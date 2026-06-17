import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import '../../../../core/data/models/responses/payment_status_response/payment_status_response.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/address_display_utils.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/country_region_defaults.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/distance_display.dart';
import '../../../../shared/utils/map_vehicle_marker_utils.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/controllers/location_selection_controller.dart';
import '../../../payment/domain/models/insufficient_wallet_balance_details.dart';
import '../../../payment/domain/wallet_ride_balance_guard.dart';
import '../../../payment/presentation/controllers/payment_method_controller.dart';
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../promotions/presentation/promo_code_route_args.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../domain/repositories/ride_repository.dart';

enum BookingMode { self, other }

/// Sentinel id for the synthetic "Book Any" row in [estimates].
const String kBookAnyVehicleTypeId = '__book_any__';

/// SCR-09 — vehicle + fare selection.
class VehicleSelectionController extends GetxController {
  VehicleSelectionController({
    required this.homeRepository,
    required this.profileRepository,
    required this.rideRepository,
    required this.paymentMethodController,
  });

  final HomeRepository homeRepository;
  final ProfileRepository profileRepository;
  final RideRepository rideRepository;
  final PaymentMethodController paymentMethodController;

  final estimates = <FareEstimateItem>[].obs;
  final selectedVehicleIndex = 0.obs;
  final isLoadingEstimates = true.obs;
  final isBooking = false.obs;
  final isLoadingNearbyDrivers = false.obs;
  final isSocketConnected = false.obs;

  /// User-visible nearby-drivers badge failed (never show raw socket errors).
  final nearbyDriversUnavailable = false.obs;
  final nearbyDriverCount = 0.obs;
  final appliedPromoCode = ''.obs;
  final promoValidatedAt = Rxn<DateTime>();
  PromoCodeApplyResult? _pendingPromoApplyResult;
  Timer? _promoEstimateDebounce;
  final isRouteReady = false.obs;
  final isLocationIconsReady = false.obs;
  final isMapVisualReady = false.obs;
  final pickupOverlayOffset = Rxn<Offset>();
  final dropOverlayOffset = Rxn<Offset>();
  final dropOverlayOffsets = <Offset?>[].obs;

  /// Full route for polyline (API).
  final routePoints = <LatLng>[].obs;

  /// Nearby driver markers from `go:nearby_drivers:result` (position + vehicle type).
  final nearbyDrivers = <NearbyDriverPoint>[].obs;

  late LocationEntity pickupEntity;
  late LocationEntity destinationEntity;
  final destinations = <LocationEntity>[].obs;

  String? _preferredVehicleTypeId;
  String? _preferredVehicleName;
  final _vehicleTypes = <VehicleTypeModel>[];
  AppSocketService get _socketService => Get.find<AppSocketService>();
  StreamSubscription<List<Driver>>? _nearbyDriversSub;
  StreamSubscription<String>? _nearbyDriversErrorSub;
  StreamSubscription<bool>? _nearbyDriversConnectionSub;

  static const String _nearbyDriversLogName = 'NEARBY_DRIVERS';
  String? _pendingNearbyDriversVehicleType;
  int? _lastLoggedNearbyDriversCount;

  GoogleMapController? mapController;
  LatLng? _lastProjectedPickup;
  List<LatLng> _lastProjectedDrops = const <LatLng>[];
  int _overlayProjectionSeq = 0;

  /// Incremented when the [GoogleMap] widget is disposed or this controller
  /// closes, so stale [Future.microtask] / async callbacks skip map I/O.
  int _mapDisposedGeneration = 0;

  BitmapDescriptor? driverIcon;
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropIcon;
  final stopIcons = <BitmapDescriptor>[].obs;
  final Map<String, BitmapDescriptor> _nearbyDriverIconCache = {};

  static PaymentMethodModel get _walletPaymentMethod => PaymentMethodModel(
    id: 'wallet',
    label: AppStrings.wallet.tr,
    type: 'wallet',
  );

  @override
  void onInit() {
    super.onInit();
    _parseArguments();
    _ensureWalletPaymentSelected();
    loadLocationIcons();
    _initNearbyDriversSocket();
    _loadAll();
  }

  void _ensureWalletPaymentSelected() {
    paymentMethodController.selectedPayment.value = _walletPaymentMethod;
  }

  PaymentMethodModel get _walletPayment =>
      paymentMethodController.selectedPayment.value ?? _walletPaymentMethod;

  @override
  void onClose() {
    _promoEstimateDebounce?.cancel();
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    _nearbyDriversConnectionSub?.cancel();
    _invalidateMapSession();
    super.onClose();
  }

  /// Called from [AppGoogleMap.onMapDisposed] when the map widget is removed.
  void onMapDisposed() => _invalidateMapSession();

  void _invalidateMapSession() {
    mapController = null;
    _mapDisposedGeneration++;
    // Drop any in-flight overlay projection that still holds the old controller.
    _overlayProjectionSeq++;
  }

  /// [_fitBounds] is also invoked via [Future.microtask] after async estimate work.
  /// Capture [_mapDisposedGeneration] now so a dispose that happens before the
  /// microtask runs causes an immediate no-op instead of touching a dead controller.
  void _scheduleFitBoundsMicrotask() {
    final gen = _mapDisposedGeneration;
    Future.microtask(() => _fitBounds(disposalGenWhenScheduled: gen));
  }

  bool _isGoogleMapDisposedUseError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('googlemapcontroller') && s.contains('disposed');
  }

  void _parseArguments() {
    final raw = Get.arguments;
    if (kDebugMode) {
      debugPrint('[VehicleSelection] Raw Get.arguments => $raw');
    }

    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    if (args.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[VehicleSelection] WARNING: Arguments are empty or not a Map.',
        );
      }
    }

    final pickupAddr = (args['pickup'] as String?)?.trim() ?? '';
    final pLat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
    final pLng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
    pickupEntity = LocationEntity(lat: pLat, lng: pLng, address: pickupAddr);

    final List<dynamic>? ds = args['destinations'];
    if (ds != null && ds.isNotEmpty) {
      destinations.assignAll(ds.cast<LocationEntity>());
      destinationEntity = destinations.last;
    } else {
      // Legacy support
      final destAddr = (args['destination'] as String?)?.trim() ?? '';
      final dLat =
          (args['destinationLat'] as num?)?.toDouble() ?? (pLat - 0.018);
      final dLng =
          (args['destinationLng'] as num?)?.toDouble() ?? (pLng + 0.014);
      destinationEntity = LocationEntity(
        lat: dLat,
        lng: dLng,
        address: destAddr,
      );
      destinations.assignAll([destinationEntity]);
    }

    if (kDebugMode) {
      debugPrint(
        '[VehicleSelection] Parsed args => '
        'pickup=(${pickupEntity.lat},${pickupEntity.lng}), '
        'destinationsCount=${destinations.length}, '
        'finalDestination=(${destinationEntity.lat},${destinationEntity.lng})',
      );
    }

    _preferredVehicleTypeId = (args['preferredVehicleTypeId'] as String?)
        ?.trim();
    _preferredVehicleName = (args['preferredVehicleName'] as String?)
        ?.trim()
        .toLowerCase();

    isRouteReady.value = false;
    update(['route_header']);
  }

  Future<void> _loadAll() async {
    await _loadEstimates();
  }

  FareEstimateRequest _fareEstimateRequest() {
    final trimmed = appliedPromoCode.value.trim();
    return FareEstimateRequest(
      pickup: pickupEntity,
      destination: destinationEntity,
      stops: routeStops,
      promoCode: trimmed.isEmpty ? null : trimmed,
    );
  }

  /// Intermediate stops only — final destination is [destinationEntity].
  List<LocationEntity> get routeStops => destinations.length > 1
      ? destinations.sublist(0, destinations.length - 1)
      : const [];

  Future<void> _loadEstimates({
    bool silent = false,
    bool preserveRoute = false,
  }) async {
    if (!silent) {
      isLoadingEstimates.value = true;
    }
    if (!preserveRoute) {
      isRouteReady.value = false;
      routePoints.clear();
      nearbyDrivers.clear();
    }
    final req = _fareEstimateRequest();

    final vehicleTypesResult = await homeRepository.getVehicleTypes();
    List<VehicleTypeModel> vehicleTypes = [];
    vehicleTypesResult.fold((_) {}, (list) => vehicleTypes = list);
    _vehicleTypes
      ..clear()
      ..addAll(vehicleTypes);

    final result = await homeRepository.estimateFare(req);
    result.fold(
      (f) {
        if (kDebugMode) {
          debugPrint('[VehicleSelection] Fare estimate error: $f');
        }
        estimates.assignAll(_dummyEstimates(vehicleTypes));
        isRouteReady.value = false;
      },
      (model) {
        if (kDebugMode) {
          debugPrint(
            '[VehicleSelection] Fare estimate success => '
            'estimates=${model.estimates.length}, '
            'routeGeometry=${model.routeGeometry != null}, '
            'points=${model.routeGeometry?.coordinates?.length ?? 0}',
          );
        }
        if (model.estimates.isEmpty) {
          estimates.assignAll(_dummyEstimates(vehicleTypes));
        } else {
          final normalized = model.estimates
              .map((e) => _withResolvedVehicleTypeId(e, vehicleTypes))
              .toList();
          estimates.assignAll(
            _estimatesWithBookAny(normalized, model.bookAny),
          );
          final pending = _pendingPromoApplyResult;
          if (pending != null) {
            _applyPromoValidationToEstimates(pending);
          }
          if (appliedPromoCode.value.trim().isNotEmpty) {
            promoValidatedAt.value = DateTime.now();
          }

          if (model.routeGeometry?.coordinates != null &&
              model.routeGeometry!.coordinates!.isNotEmpty) {
            final coords = model.routeGeometry!.coordinates!;
            final mapped = coords
                .map((c) {
                  if (c.length >= 2) return LatLng(c[1], c[0]);
                  return null;
                })
                .whereType<LatLng>()
                .toList();

            if (mapped.length >= 2) {
              routePoints.assignAll(mapped);
              isRouteReady.value = true;
              if (kDebugMode) {
                debugPrint(
                  '[VehicleSelection] API route geometry applied => '
                  'points=${mapped.length}, '
                  'first=${mapped.first.latitude},${mapped.first.longitude}, '
                  'last=${mapped.last.latitude},${mapped.last.longitude}',
                );
              }
            } else {
              _useStraightLineFallback();
            }
          } else {
            _useStraightLineFallback();
          }
        }
      },
    );
    isLoadingEstimates.value = false;
    _applyPreferredVehicleSelection();

    if (estimates.isNotEmpty) {
      await loadDriverIcon();
    }

    _requestNearbyDriversForCurrentSelection();
    _scheduleFitBoundsMicrotask();
  }

  void _useStraightLineFallback() {
    final list = [
      LatLng(pickupEntity.lat, pickupEntity.lng),
      ...destinations.map((d) => LatLng(d.lat, d.lng)),
    ];
    routePoints.assignAll(list);
    isRouteReady.value = true;
    if (kDebugMode) {
      debugPrint(
        '[VehicleSelection] Using straight-line fallback for routePoints.',
      );
    }
  }

  Future<void> loadDriverIcon() async {
    final item = estimates[selectedVehicleIndex.value];
    final vehicleType = item.isBookAnyOption ? 'cab' : item.vehicleName;
    final asset = MapVehicleMarkerUtils.markerAssetForVehicleType(vehicleType);
    driverIcon = await MapMarkerUtils.getSvgMarker(
      asset,
      MapVehicleMarkerUtils.defaultMarkerWidth,
    );
  }

  Future<void> loadLocationIcons() async {
    try {
      final bool isMulti = destinations.length > 1;

      if (!isMulti) {
        // Single Stop: P (Blue) and D (Green)
        pickupIcon = await MapMarkerUtils.createTextMarker(
          text: 'P',
          color: AppColors.mapPickupMarkerBlue,
        );
        dropIcon = await MapMarkerUtils.createTextMarker(
          text: 'D',
          color: AppColors.mapDropMarkerGreen,
        );
        stopIcons.clear();
      } else {
        // Multi Stop: A (Blue), B, C... (Red), Last Letter (Green)
        const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
        pickupIcon = await MapMarkerUtils.createTextMarker(
          text: 'A',
          color: AppColors.mapPickupMarkerBlue,
        );

        stopIcons.clear();
        // Generate all possible intermediate letters as Red
        for (int i = 1; i < letters.length; i++) {
          final icon = await MapMarkerUtils.createTextMarker(
            text: letters[i],
            color: AppColors.mapStopMarkerRed,
          );
          stopIcons.add(icon);
        }

        // Final destination letter circle (secondary — pickup stays primary).
        final destIndex = destinations.length; // If 2 drops, index is 2 (C)
        final label = (destIndex < letters.length)
            ? letters[destIndex]
            : letters.last;
        dropIcon = await MapMarkerUtils.createTextMarker(
          text: label,
          color: AppColors.secondary,
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      if (kDebugMode) {
        debugPrint('[VehicleSelection] Error loading markers: $e');
      }
    }
    isLocationIconsReady.value =
        pickupIcon != null && dropIcon != null && stopIcons.isNotEmpty;
  }

  bool get isMapDataReady => isRouteReady.value && routePoints.length >= 2;

  String vehicleImage(FareEstimateItem e) {
    if (e.isBookAnyOption) return VehicleImageUtils.imageAssetForVehicleType('cab');
    return VehicleImageUtils.imageAssetForVehicleType(e.vehicleName);
  }

  bool get isBookAnySelected => selectedEstimate?.isBookAnyOption == true;

  String vehicleFareDisplay(FareEstimateItem item) {
    if (item.isBookAnyOption) {
      final min = item.bookAnyMinFare ?? 0;
      final max = item.bookAnyMaxFare ?? item.fareEstimate ?? 0;
      return '${CurrencyFormatter.formatWithApiCurrency(min, item.currency)} - ${CurrencyFormatter.formatWithApiCurrency(max, item.currency)}';
    }
    return CurrencyFormatter.formatWithApiCurrency(
      item.fareEstimate ?? 0,
      item.currency,
    );
  }

  List<FareEstimateItem> _estimatesWithBookAny(
    List<FareEstimateItem> items,
    BookAnyEstimate? bookAny,
  ) {
    if (bookAny == null || !bookAny.eligible || items.length < 2) {
      return items;
    }
    final first = items.first;
    final maxPassengers = items
        .map((e) => e.maxPassengers ?? 1)
        .fold<int>(1, (a, b) => a > b ? a : b);
    final anyItem = FareEstimateItem(
      vehicleTypeId: kBookAnyVehicleTypeId,
      vehicleName: 'any',
      displayName: AppStrings.bookAny.tr,
      fareEstimate: bookAny.blockAmount,
      distanceKm: first.distanceKm,
      durationMinutes: first.durationMinutes,
      currency: bookAny.currency ?? first.currency,
      maxPassengers: maxPassengers,
      isBookAnyOption: true,
      bookAnyMinFare: bookAny.minFare,
      bookAnyMaxFare: bookAny.maxFare,
    );
    return [...items, anyItem];
  }

  void _restoreVehicleSelectionAfterRefresh({
    required bool wasBookAny,
    required String? previousVehicleTypeId,
    required int previousIndex,
  }) {
    if (wasBookAny) {
      final bookAnyIndex = estimates.indexWhere((e) => e.isBookAnyOption);
      if (bookAnyIndex >= 0) {
        selectedVehicleIndex.value = bookAnyIndex;
        return;
      }
    }
    final resolvedId = (previousVehicleTypeId ?? '').trim();
    if (resolvedId.isNotEmpty) {
      final keepIndex = estimates.indexWhere(
        (e) => (e.vehicleTypeId ?? '').trim() == resolvedId,
      );
      if (keepIndex >= 0) {
        selectedVehicleIndex.value = keepIndex;
        return;
      }
    }
    selectedVehicleIndex.value = previousIndex.clamp(0, estimates.length - 1);
  }

  /// Backend expects `vehicle_type_id` as the catalog id (e.g. Mongo `_id`), not a slug like `cab`.
  bool _looksLikeBackendVehicleTypeId(String? s) {
    final t = (s ?? '').trim();
    if (t.isEmpty) return false;
    if (t.length == 24 && RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(t)) return true;
    if (t.length == 36 && t.contains('-')) return true;
    return false;
  }

  VehicleTypeModel? _matchVehicleTypeFromEstimate(
    FareEstimateItem e,
    List<VehicleTypeModel> types,
  ) {
    final id = (e.vehicleTypeId ?? '').trim();
    final vn = (e.vehicleName ?? '').trim().toLowerCase();
    final dn = (e.displayName ?? '').trim().toLowerCase();
    for (final vt in types) {
      if (id.isNotEmpty && vt.id == id) return vt;
      if (id.isNotEmpty &&
          vt.id.isNotEmpty &&
          vt.key.toLowerCase() == id.toLowerCase()) {
        return vt;
      }
      if (id.isNotEmpty && vt.name.toLowerCase() == id.toLowerCase()) return vt;
      if (vn.isNotEmpty && vt.key.toLowerCase() == vn) return vt;
      if (vn.isNotEmpty && vt.name.toLowerCase() == vn) return vt;
      if (dn.isNotEmpty && vt.displayName.toLowerCase() == dn) return vt;
    }
    return null;
  }

  FareEstimateItem _copyFareEstimateItem(
    FareEstimateItem e, {
    bool? promoApplied,
    int? promoDiscount,
    int? discountedFare,
    String? promoError,
  }) {
    return FareEstimateItem(
      vehicleTypeId: e.vehicleTypeId,
      vehicleName: e.vehicleName,
      displayName: e.displayName,
      fareEstimate: e.fareEstimate,
      distanceKm: e.distanceKm,
      durationMinutes: e.durationMinutes,
      baseFare: e.baseFare,
      perKmCharge: e.perKmCharge,
      perMinCharge: e.perMinCharge,
      minimumFare: e.minimumFare,
      waypointCharge: e.waypointCharge,
      maxPassengers: e.maxPassengers,
      currency: e.currency,
      promoApplied: promoApplied ?? e.promoApplied,
      promoDiscount: promoDiscount ?? e.promoDiscount,
      discountedFare: discountedFare ?? e.discountedFare,
      promoError: promoError,
      isBookAnyOption: e.isBookAnyOption,
      bookAnyMinFare: e.bookAnyMinFare,
      bookAnyMaxFare: e.bookAnyMaxFare,
    );
  }

  bool _estimateMatchesVehicleType(FareEstimateItem e, String vehicleTypeId) {
    final target = vehicleTypeId.trim().toLowerCase();
    if (target.isEmpty) return false;
    final id = (e.vehicleTypeId ?? '').trim().toLowerCase();
    if (id == target) return true;
    final name = (e.vehicleName ?? '').trim().toLowerCase();
    return name == target;
  }

  /// Called from promo screen after validate succeeds (and from [openPromotions] fallback).
  Future<void> commitPromoApplyResult(PromoCodeApplyResult validation) async {
    _pendingPromoApplyResult = validation;
    appliedPromoCode.value = validation.code;
    promoValidatedAt.value = DateTime.now();
    _applyPromoValidationToEstimates(validation);
    await _loadEstimates(silent: true, preserveRoute: true);
    _applyPromoValidationToEstimates(validation);
    _pendingPromoApplyResult = null;
  }

  /// Applies [PromoCodeApplyResult] pricing to the matching vehicle row (e.g. after validate API).
  void _applyPromoValidationToEstimates(PromoCodeApplyResult validation) {
    final vid = validation.vehicleTypeId.trim();
    if (vid.isEmpty || estimates.isEmpty) return;

    final discounted = validation.discountedFare;
    final updated = estimates.map((e) {
      if (!_estimateMatchesVehicleType(e, vid)) return e;
      final original = e.originalFare;
      if (original <= 0 || discounted < 0 || discounted >= original) return e;
      return _copyFareEstimateItem(
        e,
        promoApplied: true,
        promoDiscount: validation.discountAmount,
        discountedFare: discounted,
        promoError: null,
      );
    }).toList();
    estimates.assignAll(updated);
    estimates.refresh();
  }

  FareEstimateItem _withResolvedVehicleTypeId(
    FareEstimateItem e,
    List<VehicleTypeModel> types,
  ) {
    if (e.isBookAnyOption) return e;
    if (types.isEmpty) return e;
    final raw = (e.vehicleTypeId ?? '').trim();
    if (raw.isNotEmpty && _looksLikeBackendVehicleTypeId(raw)) {
      final exists = types.any((vt) => vt.id == raw);
      if (exists) return e;
    }
    final matched = _matchVehicleTypeFromEstimate(e, types);
    if (matched == null) return e;
    if (matched.id == raw) return e;
    return FareEstimateItem(
      vehicleTypeId: matched.id,
      vehicleName: e.vehicleName ?? matched.name,
      displayName: e.displayName ?? matched.displayName,
      fareEstimate: e.fareEstimate,
      distanceKm: e.distanceKm,
      durationMinutes: e.durationMinutes,
      baseFare: e.baseFare,
      perKmCharge: e.perKmCharge,
      perMinCharge: e.perMinCharge,
      minimumFare: e.minimumFare,
      waypointCharge: e.waypointCharge,
      maxPassengers: e.maxPassengers ?? matched.maxPassengers,
      currency: e.currency,
      promoApplied: e.promoApplied,
      promoDiscount: e.promoDiscount,
      discountedFare: e.discountedFare,
      promoError: e.promoError,
      isBookAnyOption: e.isBookAnyOption,
      bookAnyMinFare: e.bookAnyMinFare,
      bookAnyMaxFare: e.bookAnyMaxFare,
    );
  }

  void _applyPreferredVehicleSelection() {
    if (estimates.isEmpty) return;
    final id = _preferredVehicleTypeId;
    if (id != null && id.isNotEmpty) {
      final byId = estimates.indexWhere(
        (e) =>
            e.vehicleTypeId == id ||
            (e.vehicleName != null && e.vehicleName == id),
      );
      if (byId >= 0) {
        selectedVehicleIndex.value = byId;
        return;
      }
    }
    final name = _preferredVehicleName;
    if (name != null && name.isNotEmpty) {
      final byName = estimates.indexWhere((e) {
        final vn = (e.vehicleName ?? '').toLowerCase();
        final dn = (e.displayName ?? '').toLowerCase();
        return vn.contains(name) ||
            name.contains(vn) ||
            dn.contains(name) ||
            name.contains(dn);
      });
      if (byName >= 0) selectedVehicleIndex.value = byName;
    }
  }

  /// Fallback rows when estimate API fails; uses real `VehicleTypeModel.id` from `getVehicleTypes()`.
  List<FareEstimateItem> _dummyEstimates(List<VehicleTypeModel> types) {
    final sorted = (types.where((t) => t.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
    final list = sorted.isNotEmpty ? sorted : types;
    if (list.isEmpty) {
      return [
        FareEstimateItem(
          vehicleTypeId: '',
          vehicleName: 'ride',
          displayName: AppStrings.displayNameRide.tr,
          fareEstimate: 500,
          distanceKm: 4.2,
          durationMinutes: 10,
          maxPassengers: 4,
          currency: CountryRegionDefaults.currencyCodeForIso2(
            di.sl<AppRegionService>().selected.code,
          ),
        ),
      ];
    }
    return list.map((vt) {
      final fare = vt.baseFare > 0 ? vt.baseFare : 500;
      return FareEstimateItem(
        vehicleTypeId: vt.id,
        vehicleName: vt.name,
        displayName: vt.displayName.isNotEmpty ? vt.displayName : vt.name,
        fareEstimate: fare,
        distanceKm: 4.2,
        durationMinutes: 10,
        maxPassengers: vt.maxPassengers,
        currency: CountryRegionDefaults.currencyCodeForIso2(
          di.sl<AppRegionService>().selected.code,
        ),
      );
    }).toList();
  }

  FareEstimateItem? get selectedEstimate {
    if (estimates.isEmpty) return null;
    final i = selectedVehicleIndex.value.clamp(0, estimates.length - 1);
    return estimates[i];
  }

  int get selectedPayableFareAmount => selectedEstimate?.displayFare ?? 0;

  int get selectedOriginalFareAmount => selectedEstimate?.originalFare ?? 0;

  int get selectedPromoSavingsAmount {
    final e = selectedEstimate;
    if (e == null) return 0;
    if (e.promoApplied == true && (e.promoDiscount ?? 0) > 0) {
      return e.promoDiscount!;
    }
    return 0;
  }

  String get currency =>
      selectedEstimate?.currency ??
      CountryRegionDefaults.currencyCodeForIso2(
        di.sl<AppRegionService>().selected.code,
      );

  Future<void> selectVehicle(int index) async {
    if (index < 0 || index >= estimates.length) return;
    final item = estimates[index];
    if (item.isBookAnyOption && appliedPromoCode.value.trim().isNotEmpty) {
      appliedPromoCode.value = '';
      promoValidatedAt.value = null;
      _pendingPromoApplyResult = null;
    }
    selectedVehicleIndex.value = index;
    await loadDriverIcon();
    _requestNearbyDriversForCurrentSelection();
    if (appliedPromoCode.value.trim().isNotEmpty && !item.isBookAnyOption) {
      _scheduleSilentPromoEstimateRefresh();
    }
  }

  void _scheduleSilentPromoEstimateRefresh() {
    _promoEstimateDebounce?.cancel();
    _promoEstimateDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_loadEstimates(silent: true));
    });
  }

  Future<void> bookRide() async {
    if (isBooking.value) return;

    final est = selectedEstimate;
    if (est == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.missingInfo.tr,
        message: AppStrings.selectAVehicle.tr,
      );
      return;
    }
    _ensureWalletPaymentSelected();
    final pay = _walletPayment;
    final isBookAny = est.isBookAnyOption;

    isBooking.value = true;
    Loader.instance.show();
    try {
      var resolvedVehicleTypeId = (est.vehicleTypeId ?? '').trim();
      if (!isBookAny &&
          (resolvedVehicleTypeId.isEmpty ||
              !_looksLikeBackendVehicleTypeId(resolvedVehicleTypeId))) {
        AppDialogs.showErrorDialog(
          title: AppStrings.vehicleType.tr,
          message: AppStrings.couldNotResolveVehicleTypeIdPleaseTryAgain.tr,
        );
        return;
      }

      Loader.instance.hide();
      final confirmResult = await Get.toNamed(
        AppRoutes.confirmPickup,
        arguments: {
          'pickupLat': pickupEntity.lat,
          'pickupLng': pickupEntity.lng,
          'pickupAddress': pickupEntity.address,
        },
      );
      Loader.instance.show();

      if (confirmResult is! Map) {
        return;
      }

      final confirmed = Map<String, dynamic>.from(confirmResult);
      final confirmedLat = (confirmed['pickupLat'] as num?)?.toDouble();
      final confirmedLng = (confirmed['pickupLng'] as num?)?.toDouble();
      final confirmedAddress = (confirmed['pickupAddress'] as String?)?.trim();
      if (confirmedLat == null || confirmedLng == null) {
        AppDialogs.showErrorDialog(
          title: AppStrings.pickup.tr,
          message: AppStrings.pleaseConfirmPickupPointToContinue.tr,
        );
        return;
      }

      pickupEntity = LocationEntity(
        lat: confirmedLat,
        lng: confirmedLng,
        address: (confirmedAddress == null || confirmedAddress.isEmpty)
            ? pickupEntity.address
            : confirmedAddress,
      );

      // Re-estimate fare/route after pickup confirmation so pricing and ETA are fresh.
      final refreshedEstimateResult = await homeRepository.estimateFare(
        _fareEstimateRequest(),
      );

      final refreshedOk = await refreshedEstimateResult.fold<Future<bool>>(
        (failure) async {
          String msg = failure.message;
          if (msg.startsWith('Exception: ')) {
            msg = msg.replaceFirst('Exception: ', '');
          }
          AppDialogs.showErrorDialog(
            title: AppStrings.estimateFailed.tr,
            message: msg.isEmpty
                ? AppStrings.couldNotRefreshFareAfterPickup.tr
                : msg,
          );
          return false;
        },
        (model) async {
          if (model.estimates.isEmpty) {
            AppDialogs.showErrorDialog(
              title: AppStrings.estimateFailed.tr,
              message: AppStrings
                  .noFareEstimateReturnedForTheUpdatedPickupLocation
                  .tr,
            );
            return false;
          }

          final normalized = model.estimates
              .map((e) => _withResolvedVehicleTypeId(e, _vehicleTypes))
              .toList();
          estimates.assignAll(
            _estimatesWithBookAny(normalized, model.bookAny),
          );

          _restoreVehicleSelectionAfterRefresh(
            wasBookAny: isBookAny,
            previousVehicleTypeId: resolvedVehicleTypeId,
            previousIndex: selectedVehicleIndex.value,
          );

          final selectedNow = selectedEstimate;
          if (!isBookAny) {
            final selectedNowId = (selectedNow?.vehicleTypeId ?? '').trim();
            if (selectedNowId.isNotEmpty) {
              resolvedVehicleTypeId = selectedNowId;
            }
          }

          if (model.routeGeometry?.coordinates != null &&
              model.routeGeometry!.coordinates!.isNotEmpty) {
            final mapped = model.routeGeometry!.coordinates!
                .map((c) => c.length >= 2 ? LatLng(c[1], c[0]) : null)
                .whereType<LatLng>()
                .toList();
            if (mapped.length >= 2) {
              routePoints.assignAll(mapped);
              isRouteReady.value = true;
            } else {
              _useStraightLineFallback();
            }
          } else {
            _useStraightLineFallback();
          }

          await loadDriverIcon();
          _requestNearbyDriversForCurrentSelection();
          _scheduleFitBoundsMicrotask();
          return true;
        },
      );
      if (!refreshedOk) return;

      final isBookedForOther =
          (confirmed['isBookedForOther'] as bool?) ?? false;
      final passengerName = confirmed['passengerName'] as String?;
      final passengerPhone = confirmed['passengerPhone'] as String?;
      final rawRideNote = confirmed['note'];
      final rideNote = rawRideNote == null
          ? ''
          : (rawRideNote is String
                ? rawRideNote.trim()
                : rawRideNote.toString().trim());

      if (!await _awaitPromoStalenessGuardIfNeeded()) {
        return;
      }

      final refreshedSelectedEstimate = selectedEstimate;
      final bookingBookAny = refreshedSelectedEstimate?.isBookAnyOption == true;
      final requiredFare = bookingBookAny
          ? (refreshedSelectedEstimate?.fareEstimate ??
                refreshedSelectedEstimate?.displayFare ??
                est.fareEstimate ??
                est.displayFare)
          : (refreshedSelectedEstimate?.displayFare ?? est.displayFare);
      if (!await _guardWalletBalanceBeforePayment(requiredFare)) {
        return;
      }

      // 2) Validate payment (block flow — dummy callback until real payment).
      final validateRequest = bookingBookAny
          ? ValidateRidePaymentRequest(
              bookAny: true,
              paymentMethod: pay.type,
              pickup: pickupEntity,
              destination: destinationEntity,
              stops: routeStops,
              isBookedForOther: isBookedForOther,
              passengerName: isBookedForOther ? passengerName : null,
              passengerPhone: isBookedForOther ? passengerPhone : null,
            )
          : ValidateRidePaymentRequest(
              fareEstimate: requiredFare,
              paymentMethod: pay.type,
              vehicleTypeId: resolvedVehicleTypeId,
              pickup: pickupEntity,
              destination: destinationEntity,
              stops: routeStops,
              isBookedForOther: isBookedForOther,
              passengerName: isBookedForOther ? passengerName : null,
              passengerPhone: isBookedForOther ? passengerPhone : null,
            );
      final validationResult = await rideRepository.validateRidePayment(
        validateRequest,
      );

      await validationResult.fold(
        (f) async {
          if (_handlePaymentValidationFailure(f)) return;
          AppDialogs.showErrorDialog(
            title: AppStrings.paymentValidationFailed.tr,
            message: AppStrings.couldNotValidatePaymentPleaseTryAgain.tr,
          );
        },
        (validationId) async {
          if (validationId.trim().isEmpty) {
            AppDialogs.showErrorDialog(
              title: AppStrings.paymentValidationFailed.tr,
              message: AppStrings.validationIdMissingFromServerResponse.tr,
            );
            return;
          }

          // // Join payment room and wait for block callback before booking.
          // if (!_socketService.isConnected) {
          //   await _socketService.connect();
          // }

          var blockValidationId = validationId;
          Loader.instance.show();
          while (true) {
            String? roomValidationId;
            if (AppConfig.ridePaymentBypass) {
              roomValidationId = blockValidationId;
              _socketService.joinPaymentRoom(validationId: roomValidationId);
            }
            final paymentConfirmed = AppConfig.ridePaymentBypass
                ? await _confirmDevPaymentCallback(roomValidationId??"")
                : true;

            if (paymentConfirmed) {
              break;
            }

            Loader.instance.hide();
            final shouldRetry = await _offerPaymentBlockRetry();
            if (!shouldRetry) {
              return;
            }
            Loader.instance.show();

            final reValidation = await rideRepository.validateRidePayment(
              validateRequest,
            );
            final nextId = reValidation.fold<String?>(
              (f) {
                if (_handlePaymentValidationFailure(f)) return null;
                AppDialogs.showErrorDialog(
                  title: AppStrings.paymentValidationFailed.tr,
                  message: AppStrings.couldNotValidatePaymentPleaseTryAgain.tr,
                );
                return null;
              },
              (id) {
                final t = id.trim();
                if (t.isEmpty) {
                  AppDialogs.showErrorDialog(
                    title: AppStrings.paymentValidationFailed.tr,
                    message:
                        AppStrings.validationIdMissingFromServerResponse.tr,
                  );
                  return null;
                }
                return t;
              },
            );
            if (nextId == null) {
              return;
            }
            blockValidationId = nextId;
          }

          // 2) Only after validation, submit ride booking (may retry if API OK but payment not applied).
          var bookingSubmitInFlight = false;
          Future<void> submitRideBooking() async {
            if (bookingSubmitInFlight) return;
            bookingSubmitInFlight = true;
            try {
              final request = bookingBookAny
                  ? BookRideRequest(
                      validationId: blockValidationId,
                      idempotencyKey:
                          'idem_${DateTime.now().millisecondsSinceEpoch}',
                      pickup: pickupEntity,
                      destination: destinationEntity,
                      stops: routeStops,
                      bookAny: true,
                      paymentMethod: pay.type,
                      isBookedForOther: isBookedForOther,
                      passengerName: isBookedForOther ? passengerName : null,
                      passengerPhone: isBookedForOther ? passengerPhone : null,
                      note: rideNote,
                    )
                  : BookRideRequest(
                      validationId: blockValidationId,
                      idempotencyKey:
                          'idem_${DateTime.now().millisecondsSinceEpoch}',
                      pickup: pickupEntity,
                      destination: destinationEntity,
                      stops: routeStops,
                      vehicleTypeId: resolvedVehicleTypeId,
                      paymentMethod: pay.type,
                      isBookedForOther: isBookedForOther,
                      passengerName: isBookedForOther ? passengerName : null,
                      passengerPhone: isBookedForOther ? passengerPhone : null,
                      note: rideNote,
                      fareEstimate: selectedOriginalFareAmount,
                      promoCode: appliedPromoCode.value.trim().isEmpty
                          ? null
                          : appliedPromoCode.value.trim(),
                    );
              final result = await homeRepository.bookRide(request);
              await result.fold<Future<void>>(
                (f) async {
                  String msg = f.message;
                  if (msg.startsWith('Exception: ')) {
                    msg = msg.replaceFirst('Exception: ', '');
                  }
                  AppDialogs.showErrorDialog(
                    title: AppStrings.bookingFailed.tr,
                    message: msg,
                  );
                },
                (data) async {
                  final ride = data.data?.ride;
                  final rideId = ride?.id;
                  if (rideId == null || rideId.isEmpty || ride == null) {
                    AppDialogs.showErrorDialog(
                      title: AppStrings.booking.tr,
                      message:
                          data.message ?? AppStrings.rideCreatedMissingId.tr,
                    );
                    return;
                  }

                  final pc = ride.promoCode?.toString().trim();
                  if (pc != null && pc.isNotEmpty) {
                    unawaited(
                      di.sl<AnalyticsService>().logEvent(
                        'promo_applied_to_booking',
                        parameters: {'code': pc},
                      ),
                    );
                  }

                  if (!rideBookResponseIndicatesPaymentApplied(
                    ride,
                    pay.type,
                  )) {
                    AppDialogs.showConfirmationDialog(
                      title: AppStrings.bookRidePaymentNotAppliedTitle.tr,
                      message: AppStrings.bookRidePaymentNotAppliedMessage.tr,
                      confirmText: AppStrings.retry,
                      cancelText: AppStrings.cancel,
                      onConfirm: submitRideBooking,
                    );
                    return;
                  }

                  Loader.instance.hide();
                  Get.offNamed(
                    AppRoutes.findingDriver,
                    arguments: {
                      'rideId': rideId,
                      'vehicleType': _socketVehicleTypeForEstimate(est),
                      'pickupLat': pickupEntity.lat,
                      'pickupLng': pickupEntity.lng,
                      'pickupAddress': pickupEntity.address,
                      'destinationLat': destinationEntity.lat,
                      'destinationLng': destinationEntity.lng,
                      'destinationAddress': destinationEntity.address,
                      'destinations': destinations.toList(),
                      'fareBreakdown': ride.fareBreakdown?.toJson(),
                      'isBookedForOther': isBookedForOther,
                      'passengerName': passengerName,
                      'passengerPhone': passengerPhone,
                      'cancel_time': ride.cancelTime,
                    },
                  );
                },
              );
            } finally {
              bookingSubmitInFlight = false;
            }
          }

          await submitRideBooking();
        },
      );
    } finally {
      Loader.instance.hide();
      isBooking.value = false;
    }
  }

  double _walletSpendableBalance(GoCardBalanceData? data) {
    if (data == null) return 0;
    final available = data.available?.trim();
    if (available != null && available.isNotEmpty) {
      return double.tryParse(available) ?? 0;
    }
    return double.tryParse(data.balance ?? '0') ?? 0;
  }

  /// Client-side check via `go_wallet/go_card_balance` until payment API returns breakdown.
  ///
  /// See [WalletRideBalanceGuard] TODOs for backend migration.
  Future<bool> _guardWalletBalanceBeforePayment(int requiredAmount) async {
    if (AppConfig.ridePaymentBypass) {
      return true;
    }

    final walletResult = await profileRepository.getWalletBalance();
    return walletResult.fold((_) => true, (wallet) {
      final details = WalletRideBalanceGuard.insufficientDetails(
        currentBalance: _walletSpendableBalance(wallet.response),
        requiredAmount: requiredAmount,
        currency: wallet.response?.currency ?? "",
      );
      if (details == null) return true;
      unawaited(_showInsufficientWalletDialog(details));
      return false;
    });
  }

  Future<void> _showInsufficientWalletDialog(
    InsufficientWalletBalanceDetails details,
  ) async {
    Loader.instance.hide();
    await AppDialogs.showInsufficientWalletBalanceDialog(
      details: details,
      onTopUp: openWalletTopUp,
    );
  }

  void openWalletTopUp() {
    unawaited(AddMoneyToWalletBottomSheet.show());
  }

  bool _handlePaymentValidationFailure(Failure failure) {
    if (failure is! InsufficientWalletBalanceFailure) return false;
    unawaited(_showInsufficientWalletDialog(failure.details));
    return true;
  }

  String generateTransactionId() {
    final random = Random();
    int randomNumber = random.nextInt(100000); // 0 to 99999

    // pad with leading zeros if needed
    String formattedNumber = randomNumber.toString().padLeft(5, '0');

    return 'DEV-BLOCK-$formattedNumber';
  }

  Future<bool> _offerPaymentBlockRetry() {
    final completer = Completer<bool>();
    AppDialogs.showConfirmationDialog(
      title: AppStrings.paymentNotConfirmed.tr,
      message: AppStrings.weCouldNotConfirmYourPaymentBlockPleaseTryAgain.tr,
      confirmText: AppStrings.retry,
      cancelText: AppStrings.cancel,
      onConfirm: () {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onCancel: () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    return completer.future;
  }

  /// Dev bypass: join room, await `payment_callback`, then allow book ride.
  Future<bool> _confirmDevPaymentCallback(String validationId) async {
    // Brief pause so `join_payment_room` can register before the callback.
    await Future.delayed(const Duration(milliseconds: 800));
    final txnId = generateTransactionId();
    final result = await rideRepository.walletDummyPaymentRequest(
      DummyPaymentRequest(
        result: 'SUCCESS',
        transId: txnId,
        validationId: validationId,
      ),
    );
    return result.fold((_) => false, (ok) => ok);
  }

  Future<bool> _waitForPaymentBlockStatus({
    Duration timeout = const Duration(seconds: 300),
  }) async {
    final completer = Completer<bool>();
    late StreamSubscription<PaymentStatusUpdateResponse> sub;

    sub = _socketService.paymentStatusStream.listen((event) {
      final outcome = _paymentBlockOutcome(event);
      if (outcome == null) return;
      if (!completer.isCompleted) completer.complete(outcome);
    });

    try {
      return await completer.future.timeout(timeout, onTimeout: () => false);
    } finally {
      await sub.cancel();
    }
  }

  bool? _paymentBlockOutcome(PaymentStatusUpdateResponse event) {
    final phase = (event.phase ?? '').toString().toLowerCase();
    final status = (event.status ?? '').toString().toLowerCase();

    // Accept both documented shapes:
    // - { phase: "block", status: "confirmed|failed" }
    // - { status: "completed|failed" } (without phase)
    if (phase.isNotEmpty && phase != 'block') return null;

    if (status == 'confirmed') {
      return true;
    }
    if (status == 'failed') {
      return false;
    }
    return null;
  }

  Future<void> _initNearbyDriversSocket() async {
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    _nearbyDriversConnectionSub?.cancel();

    _nearbyDriversSub = _socketService.nearbyDriversStream.listen((drivers) {
      unawaited(_syncNearbyDriversFromSocket(drivers));
    });

    _nearbyDriversErrorSub = _socketService.errorStream.listen((message) {
      nearbyDriversUnavailable.value = true;
      isLoadingNearbyDrivers.value = false;
      _logNearbyDriversError(message);
    });
    _nearbyDriversConnectionSub = _socketService.connectionStream.listen((ok) {
      isSocketConnected.value = ok;
      if (!ok) {
        nearbyDriversUnavailable.value = true;
        isLoadingNearbyDrivers.value = false;
        _logNearbyDriversInfo('Socket disconnected');
      } else {
        nearbyDriversUnavailable.value = false;
        _logNearbyDriversInfo('Socket connected');
      }
    });

    await _socketService.connect();
    _requestNearbyDriversForCurrentSelection();
  }

  void _requestNearbyDriversForCurrentSelection() {
    if (pickupEntity.lat == 0 || pickupEntity.lng == 0) return;
    isLoadingNearbyDrivers.value = true;
    nearbyDriversUnavailable.value = false;
    nearbyDriverCount.value = 0;
    nearbyDrivers.clear();
    final vehicleType = _socketVehicleTypeForEstimate(selectedEstimate);
    _pendingNearbyDriversVehicleType = vehicleType ?? 'any';
    _lastLoggedNearbyDriversCount = null;
    _logNearbyDriversRequest(vehicleType: _pendingNearbyDriversVehicleType!);
    _socketService.requestNearbyDrivers(
      lat: pickupEntity.lat,
      lng: pickupEntity.lng,
      vehicleType: vehicleType,
      radiusKm: 1000,
    );
  }

  void _logNearbyDriversRequest({required String vehicleType}) {
    if (!kDebugMode) return;
    developer.log(
      '▶ REQUEST nearby drivers (awaiting result)\n'
      '  vehicleType: $vehicleType\n'
      '  lat: ${pickupEntity.lat}\n'
      '  lng: ${pickupEntity.lng}\n'
      '  socketConnected: ${isSocketConnected.value}',
      name: _nearbyDriversLogName,
    );
  }

  void _logNearbyDriversResult(List<Driver> drivers) {
    if (!kDebugMode) return;

    final found = drivers.length;
    final vehicleType = _pendingNearbyDriversVehicleType ?? 'any';
    if (_lastLoggedNearbyDriversCount == found) {
      return;
    }
    _lastLoggedNearbyDriversCount = found;
    final buffer = StringBuffer()
      ..writeln(
        found > 0
            ? '▶ RESULT — driversFound: $found'
            : '▶ RESULT — driversFound: 0 (no drivers nearby)',
      )
      ..writeln('  vehicleType: $vehicleType')
      ..writeln('  socketConnected: ${isSocketConnected.value}');

    if (drivers.isNotEmpty) {
      buffer.writeln('  drivers:');
      for (final d in drivers.take(5)) {
        final type = d.vehicleType ?? '?';
        final dist = d.distanceKm?.toStringAsFixed(2) ?? '?';
        buffer.writeln(
          '    • fleet=${d.fleetId ?? '?'} type=$type dist=${dist}km '
          '(${d.lat}, ${d.lng})',
        );
      }
      if (drivers.length > 5) {
        buffer.writeln('    … +${drivers.length - 5} more');
      }
    }

    developer.log(buffer.toString(), name: _nearbyDriversLogName);
  }

  void _logNearbyDriversError(String message) {
    if (!kDebugMode) return;
    _lastLoggedNearbyDriversCount = null;
    developer.log(
      '▶ ERROR — nearby drivers failed\n'
      '  vehicleType: ${_pendingNearbyDriversVehicleType ?? 'any'}\n'
      '  message: $message',
      name: _nearbyDriversLogName,
    );
  }

  void _logNearbyDriversInfo(String headline) {
    if (!kDebugMode) return;
    developer.log(
      '▶ $headline\n'
      '  socketConnected: ${isSocketConnected.value}',
      name: _nearbyDriversLogName,
    );
  }

  Future<void> _syncNearbyDriversFromSocket(List<Driver> drivers) async {
    if (drivers.isEmpty) {
      nearbyDrivers.clear();
      nearbyDriverCount.value = 0;
      nearbyDriversUnavailable.value = false;
      isLoadingNearbyDrivers.value = false;
      _logNearbyDriversResult(drivers);
      return;
    }

    final parsed = <NearbyDriverPoint>[];
    for (final d in drivers) {
      final lat = double.tryParse((d.lat ?? '').trim());
      final lng = double.tryParse((d.lng ?? '').trim());
      if (lat == null || lng == null) continue;
      parsed.add(
        NearbyDriverPoint(
          fleetId: d.fleetId ?? '',
          lat: lat,
          lng: lng,
          vehicleType: d.vehicleType,
          distanceKm: d.distanceKm,
        ),
      );
    }

    await _preloadNearbyDriverIcons(parsed);
    nearbyDrivers.assignAll(parsed);
    nearbyDriverCount.value = parsed.length;
    nearbyDriversUnavailable.value = false;
    isLoadingNearbyDrivers.value = false;
    _logNearbyDriversResult(drivers);
  }

  Future<void> _preloadNearbyDriverIcons(List<NearbyDriverPoint> drivers) async {
    final types = drivers
        .map((d) => (d.vehicleType ?? '').trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet();
    for (final type in types) {
      if (_nearbyDriverIconCache.containsKey(type)) continue;
      final asset = MapVehicleMarkerUtils.markerAssetForVehicleType(type);
      _nearbyDriverIconCache[type] = await MapMarkerUtils.getSvgMarker(
        asset,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    }
  }

  BitmapDescriptor nearbyDriverMarkerIcon(String? vehicleType) {
    final key = (vehicleType ?? '').trim().toLowerCase();
    if (key.isNotEmpty) {
      final cached = _nearbyDriverIconCache[key];
      if (cached != null) return cached;
    }
    return driverIcon ?? pickupIcon ?? BitmapDescriptor.defaultMarker;
  }

  String? _socketVehicleTypeForEstimate(FareEstimateItem? item) {
    if (item == null) return null;
    if (item.isBookAnyOption) return 'any';

    // Pass API vehicle_types.key directly in socket event payload.
    final estimateTypeId = (item.vehicleTypeId ?? '').trim();
    if (estimateTypeId.isEmpty || _vehicleTypes.isEmpty) {
      return null; // omit vehicle_type if key cannot be resolved
    }

    final matched = _vehicleTypes.firstWhereOrNull(
      (v) => v.id == estimateTypeId,
    );
    final key = matched?.key.trim();
    if (key == null || key.isEmpty) return null;
    return key;
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitBounds();

    // Manage visual readiness with delay similar to old setState logic
    if (!isMapVisualReady.value) {
      Future.delayed(const Duration(milliseconds: 220), () {
        isMapVisualReady.value = true;
      });
    }
  }

  void onCameraIdle() {
    if (!isMapVisualReady.value) {
      isMapVisualReady.value = true;
    }
  }

  void scheduleOverlayProjection({
    required LatLng pickup,
    required List<LatLng> drops,
    required double devicePixelRatio,
  }) {
    final pickupChanged = _lastProjectedPickup != pickup;
    final dropsChanged =
        _lastProjectedDrops.length != drops.length ||
        !_lastProjectedDrops.asMap().entries.every(
          (e) => e.value == drops[e.key],
        );
    if (!pickupChanged && !dropsChanged) return;
    _lastProjectedPickup = pickup;
    _lastProjectedDrops = List<LatLng>.from(drops);
    Future.microtask(
      () => projectOverlayOffsets(
        pickup: pickup,
        drops: drops,
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }

  Future<void> projectOverlayOffsets({
    required LatLng pickup,
    required List<LatLng> drops,
    required double devicePixelRatio,
  }) async {
    if (mapController == null) return;
    final seq = ++_overlayProjectionSeq;
    final pickupRaw = await AppMapService.screenOffsetFor(
      mapController!,
      pickup,
    );
    final dropRaws = await Future.wait(
      drops.map((d) => AppMapService.screenOffsetFor(mapController!, d)),
    );
    if (seq != _overlayProjectionSeq) return;
    if (mapController == null) return;

    Offset? normalize(Offset? raw) {
      if (raw == null) return null;
      // Android map projection is reported in physical pixels; iOS aligns with
      // logical pixels in our map stack. Keep both platform behaviors stable.
      if (GetPlatform.isAndroid) {
        return Offset(raw.dx / devicePixelRatio, raw.dy / devicePixelRatio);
      }
      return raw;
    }

    pickupOverlayOffset.value = normalize(pickupRaw);
    dropOverlayOffsets.assignAll(
      dropRaws.map(normalize).toList(growable: false),
    );
    dropOverlayOffset.value = dropOverlayOffsets.isNotEmpty
        ? dropOverlayOffsets.last
        : null;
  }

  String compactAddress(String value) {
    final line = compactAddressLine(value);
    if (line.isEmpty) return AppStrings.selectedLocation.tr;
    return line;
  }

  String get pickupMapLabel => compactAddress(pickupEntity.address);

  String get destinationMapLabel => compactAddress(destinationEntity.address);

  String dropMapLabelAt(int index) {
    if (index < 0 || index >= destinations.length) return destinationMapLabel;
    return compactAddress(destinations[index].address);
  }

  String formatTripDistanceKm(double? km) => DistanceDisplay.formatKm(km);

  ({String distanceEtaLine, String dropTimeLine}) vehicleTripSubtitleLines(
    FareEstimateItem item,
  ) {
    final eta = item.durationMinutes ?? 0;
    final drop = DateTime.now().add(Duration(minutes: eta));
    final dropLabel =
        '${drop.hour.toString().padLeft(2, '0')}:${drop.minute.toString().padLeft(2, '0')}';

    final combined = AppStrings.etaMinutesAwayDropTime.trParams({
      'minutes': '$eta',
      'time': dropLabel,
    });
    final parts = combined.split('•').map((s) => s.trim()).toList();

    var distanceEtaLine = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first
        : '$eta min away';
    final dropTimeLine = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1]
        : 'Drop $dropLabel';

    final distanceLabel = formatTripDistanceKm(item.distanceKm);
    if (distanceLabel.isNotEmpty) {
      distanceEtaLine = '$distanceLabel • $distanceEtaLine';
    }

    return (distanceEtaLine: distanceEtaLine, dropTimeLine: dropTimeLine);
  }

  String get destinationEtaBadgeText {
    final minutes = selectedEstimate?.durationMinutes ?? 0;
    return minutes > 0
        ? AppStrings.minutesShortCount.trParams({'count': '$minutes'})
        : AppStrings.etaBadge.tr;
  }

  void _clearPromoAfterRouteChange() {
    if (appliedPromoCode.value.trim().isEmpty) return;
    appliedPromoCode.value = '';
    promoValidatedAt.value = null;
    _pendingPromoApplyResult = null;
    Get.snackbar(
      AppStrings.promoRemovedTitle.tr,
      AppStrings.promoRemovedDestinationChanged.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  Future<bool> _awaitPromoStalenessGuardIfNeeded() async {
    final code = appliedPromoCode.value.trim();
    if (code.isEmpty) return true;
    final at = promoValidatedAt.value;
    if (at != null &&
        DateTime.now().difference(at) <= const Duration(minutes: 5)) {
      return true;
    }
    final est = selectedEstimate;
    final vid = (est?.vehicleTypeId ?? '').trim();
    if (vid.isEmpty || !_looksLikeBackendVehicleTypeId(vid)) {
      return true;
    }
    final fare = est!.originalFare;
    final result = await homeRepository.validatePromo(
      code: code,
      vehicleTypeId: vid,
      fareEstimate: fare,
    );
    return result.fold<Future<bool>>(
      (f) async {
        final msg = f is PromoValidationFailure && f.errorCode != null
            ? userMessageForPromoSheetError(f.errorCode!)
            : f.message;
        AppDialogs.showErrorDialog(
          title: AppStrings.promoNotAppliedTitle.tr,
          message: msg,
        );
        appliedPromoCode.value = '';
        promoValidatedAt.value = null;
        await _loadEstimates();
        return false;
      },
      (data) async {
        appliedPromoCode.value = data.code;
        promoValidatedAt.value = DateTime.now();
        return true;
      },
    );
  }

  String userMessageForPromoSheetError(String code) {
    switch (code.trim()) {
      case 'VALID_PROMO_INVALID':
        return AppStrings.promoErrorInvalid.tr;
      case 'VALID_PROMO_EXPIRED':
        return AppStrings.promoErrorExpired.tr;
      case 'VALID_PROMO_NOT_APPLICABLE':
        return AppStrings.promoErrorNotApplicable.tr;
      case 'INVALID_INPUT':
        return AppStrings.couldNotResolveVehicleTypeIdPleaseTryAgain.tr;
      default:
        return AppStrings.promoErrorNetwork.tr;
    }
  }

  Future<void> clearAppliedPromo() async {
    if (appliedPromoCode.value.trim().isEmpty) return;
    appliedPromoCode.value = '';
    promoValidatedAt.value = null;
    await _loadEstimates();
  }

  Future<void> openPromotions() async {
    final est = selectedEstimate;
    final vid = (est?.vehicleTypeId ?? '').trim();
    if (vid.isEmpty || !_looksLikeBackendVehicleTypeId(vid)) {
      AppDialogs.showErrorDialog(
        title: AppStrings.vehicleType.tr,
        message: AppStrings.couldNotResolveVehicleTypeIdPleaseTryAgain.tr,
      );
      return;
    }

    final result = await Get.toNamed<dynamic>(
      AppRoutes.promotions,
      arguments: PromoCodeRouteArgs(
        vehicleTypeId: vid,
        fareEstimate: est!.originalFare,
        appliedCode: appliedPromoCode.value.trim(),
      ).toMap(),
    );

    final applyResult = PromoCodeApplyResult.tryFrom(result);
    if (applyResult == null) return;
    await commitPromoApplyResult(applyResult);
  }

  void closeVehicleSelection() {
    // Cancel from vehicle selection should return to home and clear back stack.
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> editRouteHeader() async {
    // Open edit flow and return edited result back to this same vehicle screen.
    await _openLocationEdit(isEditingPickup: false);
  }

  Future<void> editPickupFromMap() async {
    await _openLocationEdit(isEditingPickup: true);
  }

  Future<void> editDropFromMap() async {
    await _openLocationEdit(
      isEditingPickup: false,
      destinationIndex: destinations.length - 1,
    );
  }

  Future<void> editDropAtIndexFromMap(int index) async {
    if (index < 0 || index >= destinations.length) return;
    await _openLocationEdit(isEditingPickup: false, destinationIndex: index);
  }

  Future<void> _openLocationEdit({
    required bool isEditingPickup,
    int? destinationIndex,
  }) async {
    if (Get.isRegistered<LocationSelectionController>()) {
      Get.delete<LocationSelectionController>();
    }

    final safeDestinationIndex = destinationIndex == null
        ? destinations.length - 1
        : destinationIndex.clamp(0, destinations.length - 1);

    final result = await Get.toNamed(
      AppRoutes.locationSelection,
      arguments: {
        'fromVehicleSelectionEdit': true,
        'editTarget': isEditingPickup ? 'pickup' : 'drop',
        'activeSegmentIndex': isEditingPickup ? 0 : safeDestinationIndex + 1,
        // In edit mode we keep existing values prefilled.
        'clearPickupOnOpen': false,
        'clearDestinationOnOpen': false,
        'pickup': pickupEntity.address,
        'pickupLat': pickupEntity.lat,
        'pickupLng': pickupEntity.lng,
        'destination': destinationEntity.address,
        'destinationLat': destinationEntity.lat,
        'destinationLng': destinationEntity.lng,
        'destinations': destinations
            .map((d) => {'lat': d.lat, 'lng': d.lng, 'address': d.address})
            .toList(),
      },
    );
    if (result is! Map) return;

    final edited = Map<String, dynamic>.from(result);
    final nextPickupAddress = (edited['pickup'] as String?)?.trim();
    final nextPickupLat = (edited['pickupLat'] as num?)?.toDouble();
    final nextPickupLng = (edited['pickupLng'] as num?)?.toDouble();
    final nextDestinationsRaw = edited['destinations'];

    if (nextPickupAddress == null ||
        nextPickupAddress.isEmpty ||
        nextPickupLat == null ||
        nextPickupLng == null ||
        nextDestinationsRaw is! List ||
        nextDestinationsRaw.isEmpty) {
      return;
    }

    final nextDestinations = <LocationEntity>[];
    for (final item in nextDestinationsRaw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final lat = (m['lat'] as num?)?.toDouble();
      final lng = (m['lng'] as num?)?.toDouble();
      final address = (m['address'] as String?)?.trim() ?? '';
      if (lat == null || lng == null || address.isEmpty) continue;
      nextDestinations.add(
        LocationEntity(lat: lat, lng: lng, address: address),
      );
    }
    if (nextDestinations.isEmpty) return;

    pickupEntity = LocationEntity(
      lat: nextPickupLat,
      lng: nextPickupLng,
      address: nextPickupAddress,
    );
    destinations.assignAll(nextDestinations);
    destinationEntity = nextDestinations.last;
    // Refresh only the top route header (GetBuilder id: route_header).
    update(['route_header']);

    isMapVisualReady.value = false;
    _clearPromoAfterRouteChange();
    await loadLocationIcons();
    await _loadEstimates();
  }

  Future<void> _fitBounds({int? disposalGenWhenScheduled}) async {
    if (mapController == null || routePoints.length < 2) return;

    // Stale microtask: map was disposed/recreated after this callback was queued.
    final scheduledGen = disposalGenWhenScheduled ?? _mapDisposedGeneration;
    if (scheduledGen != _mapDisposedGeneration) return;

    final pts = routePoints.toList();
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    // Auto-fit zoom controls:
    // - 0.20 factor: lower => tighter zoom in, higher => more zoom out.
    // - clamp min/max: reduce max for tighter fit on long routes, increase for more margin.
    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    final latPad = (latSpan * 0.20).clamp(0.0005, 0.01);
    final lngPad = (lngSpan * 0.20).clamp(0.0005, 0.01);

    if (scheduledGen != _mapDisposedGeneration || mapController == null) return;

    // Bounds padding (screen pixels):
    // - lower => more zoom in
    // - higher => more zoom out
    try {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat - latPad, minLng - lngPad),
            northeast: LatLng(maxLat + latPad, maxLng + lngPad),
          ),
          42,
        ),
      );
    } catch (e) {
      if (!_isGoogleMapDisposedUseError(e)) rethrow;
      // Map removed while awaiting — plugin throws; not an app defect.
    }
  }
}

/// True when [ride] looks like a successful hold/charge for prepaid [paymentMethodType].
bool rideBookResponseIndicatesPaymentApplied(
  BookRide ride,
  String paymentMethodType,
) {
  final type = paymentMethodType.toLowerCase().trim().replaceAll('-', '_');
  const nonPrepaid = {'cash', 'cod', 'pay_on_delivery', 'pod'};
  if (nonPrepaid.contains(type)) return true;

  final rawStatus = ride.paymentStatus?.toString().trim().toLowerCase() ?? '';
  const okStatuses = {
    'blocked',
    'block',
    'completed',
    'captured',
    'authorized',
    'authorised',
    'paid',
    'success',
  };
  if (rawStatus.isNotEmpty && okStatuses.contains(rawStatus)) return true;

  final blocked = ride.blockedAmount;
  if (blocked != null && blocked > 0) return true;

  final blockVid = (ride.blockValidationId ?? '').toString().trim();
  if (blockVid.isNotEmpty) return true;

  final trans = ride.blockTransid?.toString().trim() ?? '';
  if (trans.isNotEmpty && trans != 'null') return true;

  return false;
}
