import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/core/utils/map_marker_utils.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import '../../../../core/data/models/responses/payment_status_response/payment_status_response.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../payment/presentation/widgets/payment_status_dialog.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../home/presentation/controllers/location_selection_controller.dart';
import '../../../payment/presentation/controllers/payment_method_controller.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/widgets/ride_promo_code_sheet.dart';
import '../../../../shared/widgets/promo_apply_success_dialog.dart';
import '../../../../shared/utils/country_region_defaults.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';

enum BookingMode { self, other }

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
  final lastSocketError = ''.obs;
  final nearbyDriverCount = 0.obs;
  final paymentStatus = PaymentStatus.pending.obs;

  /// Countdown shown in [PaymentStatusDialog]; initial duration from settings API.
  final paymentTimerSeconds = 300.obs;
  final appliedPromoCode = ''.obs;
  final promoValidatedAt = Rxn<DateTime>();
  final promoSheetInlineError = RxnString();
  final promoSheetLoading = false.obs;
  Timer? _promoEstimateDebounce;
  final isRouteReady = false.obs;
  final isLocationIconsReady = false.obs;
  final isMapVisualReady = false.obs;
  final pickupOverlayOffset = Rxn<Offset>();
  final dropOverlayOffset = Rxn<Offset>();
  final dropOverlayOffsets = <Offset?>[].obs;

  /// Full route for polyline (API).
  final routePoints = <LatLng>[].obs;

  /// Nearby “driver” markers (dummy positions along/near route).
  final driverMarkerPoints = <LatLng>[].obs;

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

  @override
  void onInit() {
    super.onInit();
    _parseArguments();
    loadLocationIcons();
    _initNearbyDriversSocket();
    _loadAll();
  }

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
      destinations: destinations.toList(),
      promoCode: trimmed.isEmpty ? null : trimmed,
    );
  }

  Future<void> _loadEstimates({bool silent = false}) async {
    if (!silent) {
      isLoadingEstimates.value = true;
    }
    isRouteReady.value = false;
    routePoints.clear();
    driverMarkerPoints.clear();
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
          estimates.assignAll(normalized);
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
              final n = mapped.length;
              driverMarkerPoints.assignAll([
                mapped[(n * 0.25).floor().clamp(0, n - 1)],
                mapped[(n * 0.55).floor().clamp(0, n - 1)],
                mapped[(n * 0.78).floor().clamp(0, n - 1)],
              ]);
            } else {
              _useStraightLineFallback();
            }
          } else {
            _useStraightLineFallback();
          }
        }
      },
    );
    if (!silent) {
      isLoadingEstimates.value = false;
    }
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
    driverIcon = await MapMarkerUtils.getResizedMarker(
      vehicleImage(estimates[selectedVehicleIndex.value]),
      150,
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

        // Destination letter (Green)
        final destIndex = destinations.length; // If 2 drops, index is 2 (C)
        final label = (destIndex < letters.length)
            ? letters[destIndex]
            : letters.last;
        dropIcon = await MapMarkerUtils.createTextMarker(
          text: label,
          color: AppColors.mapDropMarkerGreen,
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
    return VehicleImageUtils.imageAssetForVehicleType(e.vehicleName);
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

  FareEstimateItem _withResolvedVehicleTypeId(
    FareEstimateItem e,
    List<VehicleTypeModel> types,
  ) {
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
          displayName: 'Ride',
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
    selectedVehicleIndex.value = index;
    await loadDriverIcon();
    _requestNearbyDriversForCurrentSelection();
    if (appliedPromoCode.value.trim().isNotEmpty) {
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
    final pay = paymentMethodController.selectedPayment.value;
    if (est == null || pay == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.missingInfo.tr,
        message: AppStrings.selectAVehicleAndPaymentMethod.tr,
      );
      return;
    }

    isBooking.value = true;
    try {
      var resolvedVehicleTypeId = (est.vehicleTypeId ?? '').trim();
      if (resolvedVehicleTypeId.isEmpty ||
          !_looksLikeBackendVehicleTypeId(resolvedVehicleTypeId)) {
        AppDialogs.showErrorDialog(
          title: AppStrings.vehicleType.tr,
          message: AppStrings.couldNotResolveVehicleTypeIdPleaseTryAgain.tr,
        );
        return;
      }

      final confirmResult = await Get.toNamed(
        AppRoutes.confirmPickup,
        arguments: {
          'pickupLat': pickupEntity.lat,
          'pickupLng': pickupEntity.lng,
          'pickupAddress': pickupEntity.address,
        },
      );

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
            title: 'Estimate failed',
            message: msg.isEmpty
                ? 'Could not refresh fare after pickup confirmation.'
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
          estimates.assignAll(normalized);

          final keepIndex = normalized.indexWhere(
            (e) => (e.vehicleTypeId ?? '').trim() == resolvedVehicleTypeId,
          );
          if (keepIndex >= 0) {
            selectedVehicleIndex.value = keepIndex;
          } else {
            selectedVehicleIndex.value = selectedVehicleIndex.value.clamp(
              0,
              normalized.length - 1,
            );
          }

          final selectedNow = selectedEstimate;
          final selectedNowId = (selectedNow?.vehicleTypeId ?? '').trim();
          if (selectedNowId.isNotEmpty) {
            resolvedVehicleTypeId = selectedNowId;
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

      if (!await _awaitPromoStalenessGuardIfNeeded()) {
        return;
      }

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

      // 1) Validate payment first (Validate Ride Payment - Block).
      final refreshedSelectedEstimate = selectedEstimate;
      final validateRequest = ValidateRidePaymentRequest(
        fareEstimate: refreshedSelectedEstimate?.displayFare ?? est.displayFare,
        paymentMethod: pay.type,
        vehicleTypeId: resolvedVehicleTypeId,
      );
      final validationResult = await rideRepository.validateRidePayment(
        validateRequest,
      );

      await validationResult.fold(
        (f) async {
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

          // Join payment room and wait for block callback before booking.
          if (!_socketService.isConnected) {
            await _socketService.connect();
          }

          var blockValidationId = validationId;
          while (true) {
            final roomValidationId = blockValidationId;
            _socketService.joinPaymentRoom(validationId: roomValidationId);
            final txnId = generateTransactionId();

            Future.delayed(const Duration(seconds: 5), () {
              rideRepository.walletDummyPaymentRequest(
                DummyPaymentRequest(
                  result: "SUCCESS",
                  transId: txnId,
                  validationId: roomValidationId,
                ),
              );
            });
            _showPaymentStatusDialog();

            final blockOk = await _waitForPaymentBlockStatus(
              timeout: Duration(
                seconds: di.sl<AppSettingsService>().paymentWaitSeconds.value,
              ),
            );

            if (blockOk) {
              paymentStatus.value = PaymentStatus.success;
              await Future.delayed(const Duration(seconds: 2));
            }

            _closePaymentStatusDialogIfOpen();

            if (blockOk) {
              break;
            }

            final shouldRetry = await _offerPaymentBlockRetry();
            if (!shouldRetry) {
              return;
            }

            final reValidation = await rideRepository.validateRidePayment(
              validateRequest,
            );
            final nextId = reValidation.fold<String?>(
              (f) {
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
              final request = BookRideRequest(
                validationId: blockValidationId,
                idempotencyKey: 'idem_${DateTime.now().millisecondsSinceEpoch}',
                pickup: pickupEntity,
                destinations: destinations.toList(),
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
                    title: 'Booking failed',
                    message: msg,
                  );
                },
                (data) async {
                  final ride = data.data?.ride;
                  final rideId = ride?.id;
                  if (rideId == null || rideId.isEmpty || ride == null) {
                    AppDialogs.showErrorDialog(
                      title: 'Booking',
                      message:
                          data.message ??
                          'Ride was created but ride id is missing from the response.',
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
      // Small delay to ensure snackbars or navigation have time to settle if needed,
      // but primarily just reset the booking state.
      isBooking.value = false;
    }
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

  void _showPaymentStatusDialog() {
    paymentStatus.value = PaymentStatus.pending;
    paymentTimerSeconds.value = di
        .sl<AppSettingsService>()
        .paymentWaitSeconds
        .value;

    if (Get.isDialogOpen == true) return;

    Get.dialog<void>(
      Obx(
        () => PaymentStatusDialog(
          status: paymentStatus.value,
          secondsRemaining: paymentStatus.value == PaymentStatus.pending
              ? paymentTimerSeconds.value
              : null,
        ),
      ),
      barrierDismissible: false,
    );

    // Start local timer for the dialog display
    _startPaymentTimer();
  }

  Timer? _paymentTimer;

  void _startPaymentTimer() {
    _paymentTimer?.cancel();
    _paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (paymentTimerSeconds.value <= 0) {
        timer.cancel();
      } else {
        paymentTimerSeconds.value--;
      }
    });
  }

  void _closePaymentStatusDialogIfOpen() {
    _paymentTimer?.cancel();
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  Future<void> _initNearbyDriversSocket() async {
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    _nearbyDriversConnectionSub?.cancel();

    _nearbyDriversSub = _socketService.nearbyDriversStream.listen((drivers) {
      if (drivers.isEmpty) {
        driverMarkerPoints.clear();
      } else {
        driverMarkerPoints.assignAll(
          drivers.map(
            (d) => LatLng(double.parse(d.lat ?? ""), double.parse(d.lng ?? "")),
          ),
        );
      }
      nearbyDriverCount.value = drivers.length;
      lastSocketError.value = '';
      isLoadingNearbyDrivers.value = false;
    });

    _nearbyDriversErrorSub = _socketService.errorStream.listen((msg) {
      lastSocketError.value = msg;
      isLoadingNearbyDrivers.value = false;
    });
    _nearbyDriversConnectionSub = _socketService.connectionStream.listen((ok) {
      isSocketConnected.value = ok;
      if (!ok) {
        isLoadingNearbyDrivers.value = false;
      }
    });

    await _socketService.connect();
    _requestNearbyDriversForCurrentSelection();
  }

  void _requestNearbyDriversForCurrentSelection() {
    if (pickupEntity.lat == 0 || pickupEntity.lng == 0) return;
    isLoadingNearbyDrivers.value = true;
    if (!isSocketConnected.value) {
      lastSocketError.value = 'Connecting socket...';
    }
    final vehicleType = _socketVehicleTypeForEstimate(selectedEstimate);
    _socketService.requestNearbyDrivers(
      lat: pickupEntity.lat,
      lng: pickupEntity.lng,
      vehicleType: vehicleType,
      radiusKm: 1000,
    );
  }

  String? _socketVehicleTypeForEstimate(FareEstimateItem? item) {
    if (item == null) return null;

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
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Selected location';
    final first = trimmed.split(',').first.trim();
    return first.isEmpty ? trimmed : first;
  }

  String get pickupMapLabel => compactAddress(pickupEntity.address);

  String get destinationMapLabel => compactAddress(destinationEntity.address);

  String dropMapLabelAt(int index) {
    if (index < 0 || index >= destinations.length) return destinationMapLabel;
    return compactAddress(destinations[index].address);
  }

  String get destinationEtaBadgeText {
    final minutes = selectedEstimate?.durationMinutes ?? 0;
    return minutes > 0 ? '$minutes Mins' : 'ETA';
  }

  String get socketDriverStatusText {
    if (isSocketConnected.value) {
      return '$nearbyDriverCount drivers online';
    }
    if (lastSocketError.value.isNotEmpty) {
      return 'Socket disconnected';
    }
    return 'Connecting drivers...';
  }

  Color get socketDriverStatusColor =>
      isSocketConnected.value ? AppColors.success : AppColors.warningStrong;

  Color get socketDriverStatusBackground => isSocketConnected.value
      ? AppColors.bgSuccessBanner
      : AppColors.bgWarningLight;

  void _clearPromoAfterRouteChange() {
    if (appliedPromoCode.value.trim().isEmpty) return;
    appliedPromoCode.value = '';
    promoValidatedAt.value = null;
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

  Future<void> applyPromoFromSheet(String raw) async {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) return;
    final est = selectedEstimate;
    final vid = (est?.vehicleTypeId ?? '').trim();
    if (vid.isEmpty || !_looksLikeBackendVehicleTypeId(vid)) {
      promoSheetInlineError.value = 'INVALID_INPUT';
      return;
    }
    final fare = est!.originalFare;
    promoSheetLoading.value = true;
    promoSheetInlineError.value = null;
    final result = await homeRepository.validatePromo(
      code: code,
      vehicleTypeId: vid,
      fareEstimate: fare,
    );
    promoSheetLoading.value = false;
    await result.fold<Future<void>>(
      (f) async {
        final err = f is PromoValidationFailure ? f.errorCode : null;
        promoSheetInlineError.value = (err != null && err.isNotEmpty)
            ? err
            : 'NETWORK';
        unawaited(
          di.sl<AnalyticsService>().logEvent(
            'promo_validated',
            parameters: {'success': 'false', 'error_code': err ?? 'unknown'},
          ),
        );
      },
      (data) async {
        unawaited(
          di.sl<AnalyticsService>().logEvent(
            'promo_validated',
            parameters: {'success': 'true', 'code': data.code},
          ),
        );
        appliedPromoCode.value = data.code;
        promoValidatedAt.value = DateTime.now();
        if (Get.isBottomSheetOpen ?? false) {
          Get.back<void>();
        }
        await _showPromoApplySuccessCelebration();
        await _loadEstimates();
      },
    );
  }

  Future<void> clearAppliedPromo() async {
    if (appliedPromoCode.value.trim().isEmpty) return;
    appliedPromoCode.value = '';
    promoValidatedAt.value = null;
    await _loadEstimates();
  }

  void openPromoEntrySheet() {
    promoSheetInlineError.value = null;
    promoSheetLoading.value = false;
    Get.bottomSheet<void>(
      RidePromoCodeSheet(controller: this),
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Future<void> _showPromoApplySuccessCelebration() async {
    await Get.dialog<void>(
      const PromoApplySuccessDialog(),
      barrierDismissible: true,
      barrierColor: Colors.black38,
    );
  }

  void openPromotions() {
    openPromoEntrySheet();
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
  Ride ride,
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
