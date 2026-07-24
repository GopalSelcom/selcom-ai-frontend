import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import '../../../../core/data/models/responses/payment_status_response/payment_status_response.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/responses/rides/validate_ride_payment_response.dart';
import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/active_rides_parser.dart';
import '../../../../shared/utils/address_display_utils.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/country_region_defaults.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/distance_display.dart';
import '../../../../shared/utils/map_vehicle_marker_utils.dart';
import '../../../../shared/utils/ride_payment_validation_messages.dart';
import '../../../../shared/utils/route_map_marker_icons.dart';
import '../../../../shared/utils/route_pin_letter_style.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../home/presentation/controllers/location_selection_controller.dart';
import '../../../payment/domain/models/insufficient_wallet_balance_details.dart';
import '../../../payment/domain/wallet_ride_balance_guard.dart';
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';
import '../../../promotions/presentation/promo_code_route_args.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../domain/repositories/ride_repository.dart';

enum BookingMode { self, other }

/// Rider promo intent across estimate → validate → book.
///
/// - [auto]: default — let backend auto-apply eligible promos
/// - [manualCode]: rider typed/selected a code (`promo_code` wins)
/// - [none]: rider removed auto promo — send `disable_auto_promo: true`
enum PromoMode { auto, manualCode, none }

/// Sentinel id for the synthetic "Book Any" row in [estimates].
const String kBookAnyVehicleTypeId = '__book_any__';

/// SCR-09 — vehicle + fare selection.
class VehicleSelectionController extends GetxController {
  VehicleSelectionController({
    required this.rideRepository,
  });

  final RideRepository rideRepository;

  /// Ride booking currently always charges Go Wallet.
  static const String _walletPaymentMethodType = 'wallet';

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
  final promoMode = PromoMode.auto.obs;
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
  bool _forceRefreshActiveRides = false;

  /// Estimate already fetched by the pre-navigation validation call; consumed
  /// once (if fresh) to avoid estimating the same route twice.
  FareEstimateResponse? _initialFareEstimate;
  DateTime? _initialFareEstimateAt;
  static const _initialFareEstimateMaxAge = Duration(seconds: 30);
  final _vehicleTypes = <VehicleType>[];
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
    AppLogger.d('[VehicleSelection] Raw Get.arguments => $raw', tag: 'VehicleSelection');

    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    if (args.isEmpty) {
      AppLogger.w(
        '[VehicleSelection] Arguments are empty or not a Map.',
        tag: 'VehicleSelection',
      );
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

    AppLogger.d(
      '[VehicleSelection] Parsed args => '
      'pickup=(${pickupEntity.lat},${pickupEntity.lng}), '
      'destinationsCount=${destinations.length}, '
      'finalDestination=(${destinationEntity.lat},${destinationEntity.lng})',
      tag: 'VehicleSelection',
    );

    _preferredVehicleTypeId = (args['preferredVehicleTypeId'] as String?)
        ?.trim();
    _preferredVehicleName = (args['preferredVehicleName'] as String?)
        ?.trim()
        .toLowerCase();
    _forceRefreshActiveRides = args['forceRefreshActiveRides'] == true;

    final initialEstimate = args['initialFareEstimate'];
    if (initialEstimate is FareEstimateResponse) {
      _initialFareEstimate = initialEstimate;
      _initialFareEstimateAt = args['initialFareEstimateAt'] as DateTime?;
    }

    isRouteReady.value = false;
    update(['route_header']);
  }

  Future<void> _loadAll() async {
    await _loadEstimates();
  }

  FareEstimateRequest _fareEstimateRequest() {
    final trimmed = appliedPromoCode.value.trim();
    final mode = promoMode.value;
    return FareEstimateRequest(
      pickup: pickupEntity,
      destination: destinationEntity,
      stops: routeStops,
      promoCode: mode == PromoMode.manualCode && trimmed.isNotEmpty
          ? trimmed
          : null,
      disableAutoPromo: mode == PromoMode.none,
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

    final vehicleTypesResult = await rideRepository.getVehicleTypes();
    List<VehicleType> vehicleTypes = [];
    vehicleTypesResult.fold((_) {}, (list) => vehicleTypes = list);
    _vehicleTypes
      ..clear()
      ..addAll(vehicleTypes);

    final initialEstimate = _takeFreshInitialEstimate();
    if (initialEstimate != null) {
      AppLogger.d(
        '[VehicleSelection] Reusing pre-navigation fare estimate '
        '(skipping duplicate estimate call).',
        tag: 'VehicleSelection',
      );
      _applyEstimateModel(initialEstimate, vehicleTypes);
    } else {
      final result = await rideRepository.estimateFare(req);
      result.fold((f) {
        AppLogger.w(
          '[VehicleSelection] Fare estimate error: $f',
          tag: 'VehicleSelection',
        );
        estimates.assignAll(_dummyEstimates(vehicleTypes));
        isRouteReady.value = false;
      }, (model) => _applyEstimateModel(model, vehicleTypes));
    }
    isLoadingEstimates.value = false;
    _applyPreferredVehicleSelection();

    if (estimates.isNotEmpty) {
      await loadDriverIcon();
    }

    _requestNearbyDriversForCurrentSelection();
    _scheduleFitBoundsMicrotask();
  }

  /// Returns the pre-navigation estimate exactly once, and only when it is
  /// still fresh and promo request params match (auto-on, no typed code).
  FareEstimateResponse? _takeFreshInitialEstimate() {
    final estimate = _initialFareEstimate;
    final estimatedAt = _initialFareEstimateAt;
    _initialFareEstimate = null;
    _initialFareEstimateAt = null;

    if (estimate == null || estimatedAt == null) return null;
    if (promoMode.value != PromoMode.auto) return null;
    if (appliedPromoCode.value.trim().isNotEmpty) return null;
    final age = DateTime.now().difference(estimatedAt);
    if (age > _initialFareEstimateMaxAge) return null;
    return estimate;
  }

  void _applyEstimateModel(
    FareEstimateResponse model,
    List<VehicleType> vehicleTypes,
  ) {
    AppLogger.d(
      '[VehicleSelection] Fare estimate applied => '
      'estimates=${model.data?.estimates?.length ?? 0}, '
      'routeGeometry=${model.data?.routeGeometry != null}, '
      'points=${model.data?.routeGeometry?.coordinates?.length ?? 0}',
      tag: 'VehicleSelection',
    );
    final estimateItems = model.data?.estimates ?? const <FareEstimateItem>[];
    if (estimateItems.isEmpty) {
      estimates.assignAll(_dummyEstimates(vehicleTypes));
      return;
    }

    final normalized = estimateItems
        .map((e) => _withResolvedVehicleTypeId(e, vehicleTypes))
        .toList();
    estimates.assignAll(_estimatesWithBookAny(normalized, model.data?.bookAny));
    final pending = _pendingPromoApplyResult;
    if (pending != null) {
      _applyPromoValidationToEstimates(pending);
    }
    if (appliedPromoCode.value.trim().isNotEmpty) {
      promoValidatedAt.value = DateTime.now();
    }

    final routeGeometry = model.data?.routeGeometry;
    if (routeGeometry?.coordinates != null &&
        routeGeometry!.coordinates!.isNotEmpty) {
      final coords = routeGeometry.coordinates!;
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
        AppLogger.d(
          '[VehicleSelection] API route geometry applied => '
          'points=${mapped.length}, '
          'first=${mapped.first.latitude},${mapped.first.longitude}, '
          'last=${mapped.last.latitude},${mapped.last.longitude}',
          tag: 'VehicleSelection',
        );
      } else {
        _useStraightLineFallback();
      }
    } else {
      _useStraightLineFallback();
    }
  }

  void _useStraightLineFallback() {
    final list = [
      LatLng(pickupEntity.lat, pickupEntity.lng),
      ...destinations.map((d) => LatLng(d.lat, d.lng)),
    ];
    routePoints.assignAll(list);
    isRouteReady.value = true;
    AppLogger.d(
      '[VehicleSelection] Using straight-line fallback for routePoints.',
      tag: 'VehicleSelection',
    );
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
      final intermediateCount = destinations.length - 1;

      if (!isMulti) {
        pickupIcon = await RouteMapMarkerIcons.pin(
          letter: 'P',
          color: RoutePinLetterStyle.pickupColor,
        );
        dropIcon = await RouteMapMarkerIcons.pin(
          letter: 'D',
          color: RoutePinLetterStyle.destinationColor,
        );
        stopIcons.clear();
      } else {
        pickupIcon = await RouteMapMarkerIcons.pin(
          letter: RoutePinLetterStyle.pickupLetter(
            intermediateStopCount: intermediateCount,
          ),
          color: RoutePinLetterStyle.pickupColor,
        );

        stopIcons.clear();
        for (int i = 0; i < intermediateCount; i++) {
          final icon = await RouteMapMarkerIcons.pin(
            letter: RoutePinLetterStyle.intermediateLetter(i),
            color: RoutePinLetterStyle.intermediateColor(i),
          );
          stopIcons.add(icon);
        }

        dropIcon = await RouteMapMarkerIcons.pin(
          letter: RoutePinLetterStyle.destinationLetter(
            intermediateStopCount: intermediateCount,
          ),
          color: RoutePinLetterStyle.destinationColor,
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.e(
        '[VehicleSelection] Error loading markers',
        tag: 'VehicleSelection',
        error: e,
      );
    }
    isLocationIconsReady.value = pickupIcon != null && dropIcon != null;
  }

  bool get isMapDataReady => isRouteReady.value && routePoints.length >= 2;

  String vehicleImage(FareEstimateItem e) {
    if (e.isBookAnyOption) {
      return VehicleImageUtils.imageAssetForVehicleType('van');
    }
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
    BookAny? bookAny,
  ) {
    if (bookAny == null || bookAny.eligible != true || items.length < 2) {
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
      bookAnyMinFare: bookAny.fareRange?.min,
      bookAnyMaxFare: bookAny.fareRange?.max,
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

  VehicleType? _matchVehicleTypeFromEstimate(
    FareEstimateItem e,
    List<VehicleType> types,
  ) {
    final id = (e.vehicleTypeId ?? '').trim();
    final vn = (e.vehicleName ?? '').trim().toLowerCase();
    final dn = (e.displayName ?? '').trim().toLowerCase();
    for (final vt in types) {
      final vtId = vt.id ?? '';
      final vtKey = (vt.key ?? '').toLowerCase();
      final vtName = (vt.name ?? '').toLowerCase();
      final vtDisplay = (vt.displayName ?? '').toLowerCase();
      if (id.isNotEmpty && vtId == id) return vt;
      if (id.isNotEmpty && vtId.isNotEmpty && vtKey == id.toLowerCase()) {
        return vt;
      }
      if (id.isNotEmpty && vtName == id.toLowerCase()) return vt;
      if (vn.isNotEmpty && vtKey == vn) return vt;
      if (vn.isNotEmpty && vtName == vn) return vt;
      if (dn.isNotEmpty && vtDisplay == dn) return vt;
    }
    return null;
  }

  FareEstimateItem _copyFareEstimateItem(
    FareEstimateItem e, {
    bool? promoApplied,
    String? promoCode,
    bool? isCashback,
    int? cashbackAmount,
    int? promoDiscount,
    int? discountedFare,
    bool? promoAutoApplied,
    String? promoDescription,
    String? promoError,
    bool clearPromoError = false,
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
      promoCode: promoCode ?? e.promoCode,
      isCashback: isCashback ?? e.isCashback,
      cashbackAmount: cashbackAmount ?? e.cashbackAmount,
      promoDiscount: promoDiscount ?? e.promoDiscount,
      discountedFare: discountedFare ?? e.discountedFare,
      promoAutoApplied: promoAutoApplied ?? e.promoAutoApplied,
      promoDescription: promoDescription ?? e.promoDescription,
      promoError: clearPromoError ? promoError : (promoError ?? e.promoError),
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
    // Auto-apply promos stay in [PromoMode.auto] so the vehicle-card
    // "Auto-applied" badge is preserved after returning from the promo screen.
    if (validation.isAutoApply) {
      appliedPromoCode.value = '';
      promoValidatedAt.value = null;
      _pendingPromoApplyResult = null;
      promoMode.value = PromoMode.auto;
      await _loadEstimates(silent: true, preserveRoute: true);
      return;
    }

    _pendingPromoApplyResult = validation;
    appliedPromoCode.value = validation.code;
    promoMode.value = PromoMode.manualCode;
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
      final original = e.fareEstimate ?? 0;
      if (original <= 0 || discounted < 0 || discounted >= original) return e;
      return _copyFareEstimateItem(
        e,
        promoApplied: true,
        promoCode: validation.code,
        isCashback: validation.isCashback,
        cashbackAmount: validation.isCashback ? validation.discountAmount : 0,
        promoDiscount: validation.isCashback ? 0 : validation.discountAmount,
        discountedFare: discounted,
        promoAutoApplied: validation.isAutoApply,
        clearPromoError: true,
        promoError: null,
      );
    }).toList();
    estimates.assignAll(updated);
    estimates.refresh();
  }

  FareEstimateItem _withResolvedVehicleTypeId(
    FareEstimateItem e,
    List<VehicleType> types,
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
      promoCode: e.promoCode,
      isCashback: e.isCashback,
      cashbackAmount: e.cashbackAmount,
      promoDiscount: e.promoDiscount,
      discountedFare: e.discountedFare,
      promoAutoApplied: e.promoAutoApplied,
      promoDescription: e.promoDescription,
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

  /// Fallback rows when estimate API fails; uses real vehicle type id from `getVehicleTypes()`.
  List<FareEstimateItem> _dummyEstimates(List<VehicleType> types) {
    final sorted = (types.where((t) => t.isActive == true).toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0)));
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
      final fare = (vt.baseFare ?? 0) > 0 ? vt.baseFare! : 500;
      final name = vt.name ?? '';
      final display = vt.displayName ?? '';
      return FareEstimateItem(
        vehicleTypeId: vt.id,
        vehicleName: name,
        displayName: display.isNotEmpty ? display : name,
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

  int get selectedPayableFareAmount {
    final e = selectedEstimate;
    if (e == null) return 0;
    // Cashback does not reduce fare; payable stays at original estimate.
    if (e.hasCashbackPromo) return e.fareEstimate ?? 0;
    return e.discountedFare ?? e.fareEstimate ?? 0;
  }

  int get selectedOriginalFareAmount => selectedEstimate?.fareEstimate ?? 0;

  int get selectedPromoSavingsAmount {
    final e = selectedEstimate;
    if (e == null) return 0;
    return e.promoBenefitAmount;
  }

  /// Benefit label under vehicle fare (cashback credit vs fare discount).
  String? promoBenefitLabelFor(FareEstimateItem item) {
    final amount = item.promoBenefitAmount;
    if (amount <= 0) return null;
    final formatted = CurrencyFormatter.formatWithApiCurrency(
      amount,
      item.currency,
    );
    if (item.hasCashbackPromo) {
      return AppStrings.promoCashbackAmount.trParams({'amount': formatted});
    }
    return '-$formatted';
  }

  /// Selected estimate has a backend auto-applied promo (not a typed code).
  bool get selectedHasAutoAppliedPromo {
    final e = selectedEstimate;
    if (e == null) return false;
    return e.promoApplied == true && e.promoAutoApplied == true;
  }

  /// Chip / Remove should show for typed code or auto-applied discount.
  bool get hasRemovablePromo {
    if (promoMode.value == PromoMode.manualCode &&
        appliedPromoCode.value.trim().isNotEmpty) {
      return true;
    }
    return selectedHasAutoAppliedPromo;
  }

  /// Label for the header promo chip (typed code or auto-applied code).
  String get promoChipLabel {
    final manual = appliedPromoCode.value.trim();
    if (promoMode.value == PromoMode.manualCode && manual.isNotEmpty) {
      return manual;
    }
    final autoCode = selectedEstimate?.promoCode?.trim() ?? '';
    if (selectedHasAutoAppliedPromo && autoCode.isNotEmpty) {
      return autoCode;
    }
    return '';
  }

  bool get showPromoChipAsAutoApplied =>
      promoMode.value != PromoMode.manualCode && selectedHasAutoAppliedPromo;

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
      if (promoMode.value == PromoMode.manualCode) {
        promoMode.value = PromoMode.auto;
      }
    }
    selectedVehicleIndex.value = index;
    await loadDriverIcon();
    _requestNearbyDriversForCurrentSelection();
    if (promoMode.value == PromoMode.manualCode &&
        appliedPromoCode.value.trim().isNotEmpty &&
        !item.isBookAnyOption) {
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
          if (_forceRefreshActiveRides) 'forceRefreshActiveRides': true,
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
      final refreshedEstimateResult = await rideRepository.estimateFare(
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
          final estimateItems = model.data?.estimates ?? const <FareEstimateItem>[];
          if (estimateItems.isEmpty) {
            AppDialogs.showErrorDialog(
              title: AppStrings.estimateFailed.tr,
              message: AppStrings
                  .noFareEstimateReturnedForTheUpdatedPickupLocation
                  .tr,
            );
            return false;
          }

          final normalized = estimateItems
              .map((e) => _withResolvedVehicleTypeId(e, _vehicleTypes))
              .toList();
          estimates.assignAll(
            _estimatesWithBookAny(normalized, model.data?.bookAny),
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

          final routeGeometry = model.data?.routeGeometry;
          if (routeGeometry?.coordinates != null &&
              routeGeometry!.coordinates!.isNotEmpty) {
            final mapped = routeGeometry.coordinates!
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
      // Block the original fare_estimate (not discounted) so pre-auth holds enough.
      final requiredFare = bookingBookAny
          ? (refreshedSelectedEstimate?.fareEstimate ??
                est.fareEstimate ??
                0)
          : (refreshedSelectedEstimate?.fareEstimate ??
                est.fareEstimate ??
                0);
      if (!await _guardWalletBalanceBeforePayment(requiredFare)) {
        return;
      }

      if (!await _guardActiveRideLimits(isBookedForOther: isBookedForOther)) {
        return;
      }

      if (!await _guardBookForOtherMultiStop(
        isBookedForOther: isBookedForOther,
      )) {
        return;
      }

      // 2) Validate payment (block flow — dummy callback until real payment).
      final validateRequest = bookingBookAny
          ? ValidateRidePaymentRequest(
              bookAny: true,
              paymentMethod: _walletPaymentMethodType,
              pickup: pickupEntity,
              destination: destinationEntity,
              stops: routeStops,
              isBookedForOther: isBookedForOther,
              passengerName: isBookedForOther ? passengerName : null,
              passengerPhone: isBookedForOther ? passengerPhone : null,
            )
          : ValidateRidePaymentRequest(
              fareEstimate: requiredFare,
              paymentMethod: _walletPaymentMethodType,
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
        (validation) async {
          final validationId = (validation.data?.validationId ?? '').trim();
          if (validationId.isEmpty) {
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
          var latestValidation = validation;
          Loader.instance.show();
          while (true) {
            String? roomValidationId;
            final needsCallback =
                !_canProceedDirectlyFromValidation(latestValidation);
            if (AppConfig.ridePaymentBypass || needsCallback) {
              roomValidationId = blockValidationId;
              _socketService.joinPaymentRoom(validationId: roomValidationId);
            }
            final paymentConfirmed = AppConfig.ridePaymentBypass
                ? await _confirmDevPaymentCallback(roomValidationId ?? '')
                : _canProceedDirectlyFromValidation(latestValidation)
                ? true
                : await _waitForPaymentBlockStatus();

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
            final nextValidation = reValidation.fold<ValidateRidePaymentResponse?>(
              (f) {
                if (_handlePaymentValidationFailure(f)) return null;
                AppDialogs.showErrorDialog(
                  title: AppStrings.paymentValidationFailed.tr,
                  message: AppStrings.couldNotValidatePaymentPleaseTryAgain.tr,
                );
                return null;
              },
              (value) {
                final t = (value.data?.validationId ?? '').trim();
                if (t.isEmpty) {
                  AppDialogs.showErrorDialog(
                    title: AppStrings.paymentValidationFailed.tr,
                    message:
                        AppStrings.validationIdMissingFromServerResponse.tr,
                  );
                  return null;
                }
                return value;
              },
            );
            if (nextValidation == null) {
              return;
            }
            latestValidation = nextValidation;
            blockValidationId =
                (nextValidation.data?.validationId ?? '').trim();
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
                      paymentMethod: _walletPaymentMethodType,
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
                      paymentMethod: _walletPaymentMethodType,
                      isBookedForOther: isBookedForOther,
                      passengerName: isBookedForOther ? passengerName : null,
                      passengerPhone: isBookedForOther ? passengerPhone : null,
                      note: rideNote,
                      fareEstimate: selectedOriginalFareAmount,
                      promoCode: promoMode.value == PromoMode.manualCode &&
                              appliedPromoCode.value.trim().isNotEmpty
                          ? appliedPromoCode.value.trim()
                          : null,
                      disableAutoPromo: promoMode.value == PromoMode.none,
                    );
              final result = await rideRepository.bookRide(request);
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
                  final ride = data.ride;
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
                    _walletPaymentMethodType,
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
                      if (ride.searchStartedAt != null)
                        'search_started_at':
                            ride.searchStartedAt!.toIso8601String(),
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

  double _walletSpendableBalance(GoCardBalanceResponseModel? wallet) {
    if (wallet == null) return 0;
    return wallet.availableBalance.toDouble();
  }

  /// Client-side check via `go_wallet/go_card_balance` until payment API returns breakdown.
  ///
  /// See [WalletRideBalanceGuard] TODOs for backend migration.
  Future<bool> _guardWalletBalanceBeforePayment(int requiredAmount) async {
    if (AppConfig.ridePaymentBypass) {
      return true;
    }

    final walletResult = await rideRepository.getWalletBalance();
    return walletResult.fold((_) => true, (wallet) {
      final details = WalletRideBalanceGuard.insufficientDetails(
        currentBalance: _walletSpendableBalance(wallet),
        requiredAmount: requiredAmount,
        currency: wallet.currency,
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
    if (failure is InsufficientWalletBalanceFailure) {
      unawaited(_showInsufficientWalletDialog(failure.details));
      return true;
    }
    if (failure is RidePaymentValidationFailure) {
      AppDialogs.showErrorDialog(
        title: AppStrings.paymentValidationFailed.tr,
        message: RidePaymentValidationMessages.displayMessage(
          errorCode: failure.errorCode,
          apiMessage: failure.message,
        ),
      );
      return true;
    }
    return false;
  }

  /// Client guard before `POST go/validate_ride_payment`.
  ///
  /// See `docs/flows/book-for-other-pickup-flow.md`.
  ///
  /// Self booking: blocked when any active self ride exists (backend: `RIDE_ALREADY_ACTIVE`).
  /// Book-for-other: blocked when active book-for-other count >= `max_active` from settings
  /// (backend: `BOOKED_FOR_OTHER_LIMIT_REACHED`).
  Future<bool> _guardActiveRideLimits({required bool isBookedForOther}) async {
    final settingsService = di.sl<AppSettingsService>();
    await settingsService.preload();

    final activeResult = await rideRepository.getActiveRide();
    final rides = activeResult.fold(
      (_) => <RideModel>[],
      (response) => parseActiveRidesFromResponse(response?.data),
    );

    if (!isBookedForOther) {
      if (hasSelfActiveRide(rides)) {
        AppDialogs.showErrorDialog(
          message: AppStrings.youAlreadyHaveAnActiveRide.tr,
        );
        return false;
      }
      return true;
    }

    if (!settingsService.bookForOtherEnabled) {
      return true;
    }

    final maxBookForOther = settingsService.maxActiveBookForOtherRides;
    final bookedForOtherCount = countBookedForOtherRides(rides);
    if (bookedForOtherCount >= maxBookForOther) {
      AppDialogs.showErrorDialog(
        message: AppStrings.bookedForOtherLimitReached.tr,
      );
      return false;
    }

    return true;
  }

  /// Book-for-other cannot include intermediate stops (backend: `BOOKED_FOR_OTHER_NO_MULTI_STOP`).
  Future<bool> _guardBookForOtherMultiStop({
    required bool isBookedForOther,
  }) async {
    if (!isBookedForOther) return true;
    if (routeStops.isEmpty) return true;

    AppDialogs.showErrorDialog(
      message: AppStrings.bookedForOtherNoMultiStop.tr,
    );
    return false;
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

  /// Mirrors former `ValidateRidePaymentResponse.canProceedDirectly`.
  bool _canProceedDirectlyFromValidation(ValidateRidePaymentResponse v) {
    final id = (v.data?.validationId ?? '').trim();
    if (v.statusCode != 200 || id.isEmpty) return false;
    if (v.data?.callbackRequired == true) return false;
    final status = (v.data?.blockStatus ?? '').trim().toLowerCase();
    return status.isEmpty || status == 'confirmed';
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
    AppLogger.d(
      '▶ REQUEST nearby drivers (awaiting result)\n'
      '  vehicleType: $vehicleType\n'
      '  lat: ${pickupEntity.lat}\n'
      '  lng: ${pickupEntity.lng}\n'
      '  socketConnected: ${isSocketConnected.value}',
      tag: _nearbyDriversLogName,
    );
  }

  void _logNearbyDriversResult(List<Driver> drivers) {
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

    AppLogger.d(buffer.toString(), tag: _nearbyDriversLogName);
  }

  void _logNearbyDriversError(String message) {
    _lastLoggedNearbyDriversCount = null;
    AppLogger.d(
      '▶ ERROR — nearby drivers failed\n'
      '  vehicleType: ${_pendingNearbyDriversVehicleType ?? 'any'}\n'
      '  message: $message',
      tag: _nearbyDriversLogName,
    );
  }

  void _logNearbyDriversInfo(String headline) {
    AppLogger.d(
      '▶ $headline\n'
      '  socketConnected: ${isSocketConnected.value}',
      tag: _nearbyDriversLogName,
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

  Future<void> _preloadNearbyDriverIcons(
    List<NearbyDriverPoint> drivers,
  ) async {
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
    final key = matched?.key?.trim();
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
        : AppStrings.etaMinutesAwayOnly.trParams({'minutes': '$eta'});
    final dropTimeLine = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1]
        : AppStrings.dropAtTime.trParams({'time': dropLabel});

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
    final hadManual = promoMode.value == PromoMode.manualCode &&
        appliedPromoCode.value.trim().isNotEmpty;
    appliedPromoCode.value = '';
    promoValidatedAt.value = null;
    _pendingPromoApplyResult = null;
    promoMode.value = PromoMode.auto;
    if (!hadManual) return;
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
    final fare = est!.fareEstimate ?? 0;
    final result = await rideRepository.validatePromo(
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
        promoMode.value = PromoMode.auto;
        await _loadEstimates();
        return false;
      },
      (data) async {
        appliedPromoCode.value = (data.code ?? code).trim().toUpperCase();
        promoMode.value = PromoMode.manualCode;
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
    if (!hasRemovablePromo) return;
    appliedPromoCode.value = '';
    promoValidatedAt.value = null;
    _pendingPromoApplyResult = null;
    // Opt out of auto-apply so the same promo does not immediately reappear.
    promoMode.value = PromoMode.none;
    await _loadEstimates(silent: true, preserveRoute: true);
  }

  Future<void> openPromotions() async {
    final est = selectedEstimate;
    if (est == null) return;

    final modeBeforeOpen = promoMode.value;
    final manualBeforeOpen = appliedPromoCode.value.trim();

    if (est.isBookAnyOption) {
      final result = await Get.toNamed<dynamic>(
        AppRoutes.promotions,
        arguments: PromoCodeRouteArgs(
          fareEstimate: est.fareEstimate ?? 0,
          bookAny: true,
        ).toMap(),
      );
      await _handlePromoScreenResult(
        result,
        modeBeforeOpen: modeBeforeOpen,
        manualBeforeOpen: manualBeforeOpen,
      );
      return;
    }

    final vid = (est.vehicleTypeId ?? '').trim();
    if (vid.isEmpty || !_looksLikeBackendVehicleTypeId(vid)) {
      AppDialogs.showErrorDialog(
        title: AppStrings.vehicleType.tr,
        message: AppStrings.couldNotResolveVehicleTypeIdPleaseTryAgain.tr,
      );
      return;
    }

    // Prefill only an explicitly selected/typed code — not an auto-applied one —
    // so backing out does not look like the rider "cleared" a manual code.
    final appliedForScreen =
        modeBeforeOpen == PromoMode.manualCode ? manualBeforeOpen : '';

    final result = await Get.toNamed<dynamic>(
      AppRoutes.promotions,
      arguments: PromoCodeRouteArgs(
        vehicleTypeId: vid,
        fareEstimate: est.fareEstimate ?? 0,
        appliedCode: appliedForScreen,
      ).toMap(),
    );

    await _handlePromoScreenResult(
      result,
      modeBeforeOpen: modeBeforeOpen,
      manualBeforeOpen: manualBeforeOpen,
    );
  }

  /// Promo screen result:
  /// - validated code → apply as [PromoMode.manualCode]
  /// - back with no selection → keep manual if one was already applied; otherwise
  ///   restore [PromoMode.auto] so backend auto-apply can run again
  Future<void> _handlePromoScreenResult(
    dynamic result, {
    required PromoMode modeBeforeOpen,
    required String manualBeforeOpen,
  }) async {
    final applyResult = PromoCodeApplyResult.tryFrom(result);
    if (applyResult != null) {
      await commitPromoApplyResult(applyResult);
      return;
    }

    // Rider left without applying a (new) code.
    if (modeBeforeOpen == PromoMode.manualCode &&
        manualBeforeOpen.isNotEmpty) {
      // Keep the previously selected manual promo.
      return;
    }

    // Restore auto-apply (covers: was auto, or had opted out via Remove then
    // opened the list and backed out without picking another code).
    final needsAutoRestore =
        promoMode.value != PromoMode.auto ||
        appliedPromoCode.value.trim().isNotEmpty;
    appliedPromoCode.value = '';
    promoValidatedAt.value = null;
    _pendingPromoApplyResult = null;
    promoMode.value = PromoMode.auto;
    if (needsAutoRestore || !selectedHasAutoAppliedPromo) {
      await _loadEstimates(silent: true, preserveRoute: true);
    }
  }

  void closeVehicleSelection() {
    // Return to existing home screen if present in backstack, avoiding full stack wipe & duplicate re-fetches.
    final canPopToHome = Get.key.currentState?.canPop() ?? false;
    if (canPopToHome) {
      Get.until((route) => route.settings.name == AppRoutes.home || route.isFirst);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
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

    // Reuse the estimate fetched by the edit-flow validation (if provided).
    final editedEstimate = edited['initialFareEstimate'];
    if (editedEstimate is FareEstimateResponse) {
      _initialFareEstimate = editedEstimate;
      _initialFareEstimateAt = edited['initialFareEstimateAt'] as DateTime?;
    }
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
