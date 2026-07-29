import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/ride_fare_settled_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/ride_stops_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/data/models/responses/payment_status_response/payment_status_response.dart';
import '../../../../core/data/models/mid_ride_cancel_model.dart';
import '../../../../core/data/models/ride_cancel_info_model.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/ride_no_show_info_model.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/address_display_utils.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/book_any_fare_settled_ui.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/fare_breakdown_display.dart';
import '../../../../shared/utils/map_route_marker_utils.dart';
import '../../../../shared/utils/route_map_marker_icons.dart';
import '../../../../shared/utils/route_pin_letter_style.dart';
import '../../../../shared/utils/map_vehicle_marker_utils.dart';
import '../../../../shared/utils/mid_ride_cancel_navigation.dart';
import '../../../../shared/utils/payment_countdown_timer.dart';
import '../../../../shared/utils/ride_active_navigation.dart';
import '../../../../shared/utils/ride_pickup_status_labels.dart';
import '../../../../shared/utils/ride_status_normalizer.dart';
import '../../../../shared/utils/tanzania_license_plate_formatter.dart';
import '../../../../shared/utils/socket_ride_scope.dart';
import '../../../../shared/utils/tracking_route_geometry_utils.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../../shared/widgets/app_google_map.dart';
import '../../../payment/domain/models/insufficient_wallet_balance_details.dart';
import '../../../payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart';
import '../../data/models/destination_update_models.dart';
import '../../data/models/emergency_contacts_response.dart';
import '../../data/models/stop_update_models.dart';
import '../../data/models/mid_ride_cancel_models.dart';
import '../../domain/repositories/ride_repository.dart';
import '../screens/ride_details_screen.dart';
import '../utils/cancel_ride_flow.dart';
import '../widgets/ride_driver_call_options_sheet.dart';
import 'ride_details_controller.dart';

/// SCR-11 — Driver accepted: live map, driver details, OTP.
enum RideBottomSheetState { driverAssigned, rideStarted }

const _reachedStatusesForSpeedHide = {
  'driver_arrived',
  'driverarrived',
  'near_destination',
  'neardestination',
  'completed',
  'ride_completed',
  'ridecompleted',
};

/// Hide speed once the driver is within this radius of pickup (pickup phase).
const _driverAtPickupProximityMeters = 75.0;

class DriverAcceptedController extends GetxController
    with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
  DriverAcceptedController({
    required this.rideRepository,
    required this.analyticsService,
  });

  final RideRepository rideRepository;
  final AnalyticsService analyticsService;

  /// From `/go/settings` → `features.max_stops` (excludes final destination).
  int get maxIntermediateStops =>
      di.sl<AppSettingsService>().maxIntermediateStops;

  final AppSocketService _socketService = AppSocketService();

  late final String rideId;
  late final LatLng pickupLatLng;
  late LatLng destinationLatLng;
  late final String pickupAddress;
  late String destinationAddress;
  final summaryIntermediateStops = <String>[].obs;
  final routeDestinations = <LocationEntity>[].obs;
  int? _seedRideCharge;
  int? _seedBookingFee;
  int? _seedTotalAmount;

  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();
  final routePoints = <LatLng>[].obs;
  final routeTarget = 'pick_up'.obs;

  final isLoadingRide = false.obs;

  /// User-facing message when ride details cannot be loaded (missing rideId or API failure).
  /// Drives the error sheet on [DriverAcceptedScreen]; never show placeholder driver data.
  final rideLoadError = RxnString();
  final Rxn<RideModel> ride = Rxn<RideModel>();

  /// Cached `cancel_info` from socket / active rides — drives cancel dialog copy.
  final cancelInfo = Rxn<RideCancelInfoModel>();

  /// Cached waiting `no_show` object — null hides the pickup wait banner.
  final noShowInfo = Rxn<RideNoShowInfoModel>();

  /// `mm:ss` remaining until [RideNoShowInfoModel.fireAt].
  final noShowCountdownLabel = '00:00'.obs;

  /// Clock hit zero; waiting for server-authoritative cancel (do not call cancel API).
  final isNoShowExpiring = false.obs;

  PaymentCountdownTimer? _noShowCountdown;
  String? _armedNoShowFireAtIso;

  final driverName = ''.obs;
  final driverPhone = ''.obs;
  final driverAvatarUrl = ''.obs;
  final driverRating = ''.obs;
  final driverVehicleLine = ''.obs;
  final bottomSheetVehicleImageAsset = AppAssets.imgCab.obs;

  /// Formatted for UI, e.g. `T 123 ABC` (see [TanzaniaLicensePlateFormatter]).
  final plateDisplayFormatted = ''.obs;
  final vehicleSubtitle = ''.obs;
  final otpDigits = <String>[].obs;
  final isPinRequired = true.obs;
  final etaLabel = AppStrings.minutesShortCount.trParams({'count': '10'}).obs;
  final currentEtaSeconds = 0.0.obs;
  final arrivalLabel = AppStrings.driverWillArrivingInMinutes.trParams({
    'minutes': '1',
  }).obs;

  /// Chained ride: driver is still finishing another nearby trip.
  /// Drives finishing-nearby sheet copy, hides the map ETA chip, and faces the
  /// driver marker along the drawn route until the flag clears.
  final isDriverFinishingNearby = false.obs;

  final unreadCount = 0.obs;
  final rideBottomSheetState = RideBottomSheetState.driverAssigned.obs;

  bool get shouldShowMapSafetyAction =>
      rideBottomSheetState.value == RideBottomSheetState.rideStarted;

  /// Hide cancel when backend says `can_cancel: false` (rider already in vehicle).
  bool get shouldShowRiderCancelButton {
    final info = cancelInfo.value;
    if (info == null) return true;
    return info.canCancel;
  }

  bool get shouldShowNoShowBanner => noShowInfo.value != null;

  String get noShowBannerTitle => noShowInfo.value?.title ?? '';

  String get noShowBannerSubtitle => noShowInfo.value?.subtitle ?? '';

  // Normalized ride status from socket/API — use [normalizeRideStatusString] when writing.
  final currentRideStatus = 'driver_assigned'.obs;

  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();
  final stopIcons = <BitmapDescriptor>[].obs;
  final Map<String, BitmapDescriptor> _redRouteLetterIcons = {};
  final Map<String, BitmapDescriptor> _greenRouteLetterIcons = {};
  bool _routeLetterIconsLoaded = false;
  int _markerIconLoadToken = 0;
  final Rxn<Offset> assignedDriverEtaScreenPx = Rxn<Offset>();
  final assignedDriverHeading = 0.0.obs;
  final assignedDriverSpeed = 0.0.obs; // m/s
  final Rxn<LatLng> animatedRiderLocation = Rxn<LatLng>();
  final RxBool isInitialRouteLoaded = false.obs;

  VoidCallback? onRecenterPressed;

  GoogleMapController? mapController;
  LatLng? _lastDriverRotationSamplePosition;
  bool _navigatedAway = false;

  /// Suppresses cancel dialog when the user completed [CancelRideFlow] (socket may also fire `cancelled`).
  bool _isUserInitiatedCancellation = false;
  DateTime? _lastCameraUpdate;
  bool _openedCompletedRideDetails = false;
  /// Guards completion handoff so socket + tracking cannot start parallel fetches.
  bool _completionHandoffInProgress = false;
  /// Coalesces concurrent getRideDetails calls (resume, handoff, stop-update poll).
  Future<void>? _rideDetailsFetchInFlight;
  bool _hasReceivedTrackingUpdate = false;

  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStopSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<RideStopsUpdatedResponse>? _rideStopsUpdatedSub;
  StreamSubscription<RideStopsUpdateFailedResponse>? _rideStopsUpdateFailedSub;
  StreamSubscription<PaymentStatusUpdateResponse>? _paymentStatusSub;
  StreamSubscription<RideFareSettledResponse>? _fareSettledSub;
  StreamSubscription<RideDriverCancelledPayload>? _driverCancelledSub;
  bool _skipRideRoomLeaveOnClose = false;
  /// Set from nav args when My Rides / Home already pre-fetched this ride.
  bool _skipInitialRideDetailsFetch = false;
  RideModel? _prefetchedRide;
  bool _isHandlingAppResume = false;
  bool _emergencyContactsLoadedOnce = false;

  /// API-driven rows for the safety sheet (label = title, primary `phone` for `tel:`).
  final emergencyContacts = <EmergencyContactModel>[].obs;

  final RxDouble sheetSize = 0.3.obs;

  // Mid-Ride Stops State
  final isUpdatingStops = false.obs;
  final stopUpdateIdempotencyKey = ''.obs;
  final Rxn<StopUpdatePreviewModel> stopUpdatePreview =
      Rxn<StopUpdatePreviewModel>();
  final Rxn<StopUpdateAppliedModel> stopUpdateApplied =
      Rxn<StopUpdateAppliedModel>();
  final stopUpdateProgressStep =
      0.obs; // 0: Idle, 1: Payment, 2: Route, 3: Success
  final stopUpdateWorkingStops = <RideStopModel>[].obs;

  final RxBool isUpdatingDestination = false.obs;
  final RxBool isDestinationUpdateFlow = false.obs;
  final Rxn<DestinationUpdatePreviewModel> destinationUpdatePreview =
      Rxn<DestinationUpdatePreviewModel>();
  DestinationUpdateAppliedModel? _pendingDestinationAppliedAfterConfirm;
  StopUpdateAppliedModel? _pendingStopAppliedAfterConfirm;
  String? _pendingStopPaymentValidationId;
  String? _pendingStopPaymentDirection;
  double? _pendingDestinationTargetLat;
  double? _pendingDestinationTargetLng;

  void updateSheetSize(double size) {
    sheetSize.value = size;
  }

  double _targetSheetFractionForStatus(String status) {
    if (status == 'near_destination') {
      return 0.35;
    }
    if (status == 'ride_in_progress' || status == 'ride_started') {
      return 0.40;
    }
    return 0.3;
  }

  void _syncSheetLayoutForCurrentStatus() {
    final target = _targetSheetFractionForStatus(currentRideStatus.value);
    // Keep map chrome in sync before the draggable listener catches up.
    updateSheetSize(target);
    if (sheetController.isAttached) {
      if ((sheetController.size - target).abs() > 0.01) {
        Future.microtask(() {
          if (!sheetController.isAttached) return;
          sheetController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!sheetController.isAttached) return;
        updateSheetSize(sheetController.size);
      });
    }
  }

  bool _isDriverArrivedAtPickupStatus(String rawStatus) {
    final normalized = normalizeRideStatusString(rawStatus);
    return normalized == 'driver_arrived' ||
        normalized == 'driverarrived' ||
        normalized.contains('driver_arrived') ||
        normalized.contains('driverarrived');
  }

  bool _isReachedStatusForSpeedHide(String rawStatus) {
    final normalized = normalizeRideStatusString(rawStatus);
    if (_reachedStatusesForSpeedHide.contains(normalized)) return true;
    if (_isDriverArrivedAtPickupStatus(rawStatus)) return true;
    if (normalized.contains('near_destination') ||
        normalized.contains('neardestination')) {
      return true;
    }
    return normalized == 'completed' ||
        normalized == 'ride_completed' ||
        normalized.contains('ride_completed');
  }

  bool _isDriverAtPickupProximity(LatLng? driverPosition) {
    if (rideBottomSheetState.value != RideBottomSheetState.driverAssigned) {
      return false;
    }
    if (driverPosition == null) return false;
    return _calculateDistanceInMeters(driverPosition, pickupLatLng) <=
        _driverAtPickupProximityMeters;
  }

  bool _shouldHideDriverSpeedFor({
    required String status,
    required LatLng? driverPosition,
    required double speedMps,
  }) {
    if (_isReachedStatusForSpeedHide(status)) return true;
    if (_isDriverAtPickupProximity(driverPosition)) return true;
    return speedMps <= 0.5;
  }

  bool get _shouldHideDriverSpeedLabel {
    // Read reactive deps so Obx rebuilds on status, speed, and driver position.
    final status = currentRideStatus.value;
    final driverPosition = assignedDriverLocation.value;
    rideBottomSheetState.value;
    return _shouldHideDriverSpeedFor(
      status: status,
      driverPosition: driverPosition,
      speedMps: assignedDriverSpeed.value,
    );
  }

  String get formattedSpeedLabel {
    if (_shouldHideDriverSpeedLabel) return '';
    final speedKmh = (assignedDriverSpeed.value * 3.6).round();
    return speedKmh > 0 ? '$speedKmh km/h' : '';
  }

  final DraggableScrollableController sheetController =
      DraggableScrollableController();
  final RxBool isTrackingRider = false.obs;
  final GlobalKey<AppGoogleMapState> mapWidgetKey =
      GlobalKey<AppGoogleMapState>();

  @override
  void onInit() {
    super.onInit();
    sheetController.addListener(() {
      updateSheetSize(sheetController.size);
    });
    WidgetsBinding.instance.addObserver(this);
    _parseArgs();
    _bootstrap();
    ever(animatedRiderLocation, (_) => scheduleAssignedEtaOverlayRefresh());
    ever(routePoints, (List<LatLng> points) {
      if (isInitialRouteLoaded.value) return;
      final kind = TrackingRouteGeometryUtils.classifyFromPoints(points);
      if (kind == TrackingRouteGeometryKind.path) {
        recenterMap();
        _markInitialRouteReady();
      } else if (kind == TrackingRouteGeometryKind.repeatedLocation) {
        _markInitialRouteReady();
      }
    });
    ever(currentRideStatus, (_) => _syncSheetLayoutForCurrentStatus());
    ever(rideBottomSheetState, (_) => _syncSheetLayoutForCurrentStatus());
    _loadPersistedIdempotencyKey();
    arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
      'minutes': '1',
    });
    analyticsService.logEvent('driver_assigned_screen_viewed');
  }

  Future<void> _loadPersistedIdempotencyKey() async {
    final key = await StorageService().read(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
    );
    if (key != null) {
      stopUpdateIdempotencyKey.value = key;
    }
  }

  Future<void> _saveIdempotencyKey(String key) async {
    await StorageService().write(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
      key,
    );
  }

  Future<void> _clearIdempotencyKey() async {
    await StorageService().delete(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
    );
    stopUpdateWorkingStops.clear();
    stopUpdatePreview.value = null;
  }

  Future<void> _bootstrap() async {
    await _loadMarkerIcons();
    if (_skipInitialRideDetailsFetch && _prefetchedRide != null) {
      // Reuse pre-fetched ride from navigation instead of GET /rides/:id on open.
      if (_navigatedAway) return;
      isLoadingRide.value = true;
      rideLoadError.value = null;
      await _applyRideDetailsFromModel(_prefetchedRide!);
      if (!_navigatedAway) {
        isLoadingRide.value = false;
      }
    } else {
      await _fetchRideDetails();
    }
    _handleStopUpdateRecovery();
    await _initRideRoomSocket();
  }

  /// Called once from [DriverAcceptedScreen] after first frame.
  Future<void> loadEmergencyContactsOnceOnScreenOpen() async {
    if (_emergencyContactsLoadedOnce) return;
    _emergencyContactsLoadedOnce = true;
    final result = await rideRepository.getEmergencyContacts();
    result.fold(
      (f) => AppLogger.w(
        'emergency_contacts request failed: ${f.message}',
        tag: 'EmergencyContacts',
      ),
      (EmergencyContactsResponse res) {
        emergencyContacts.assignAll(res.data.contacts);
      },
    );
  }

  IconData emergencyContactIconFor(String id) {
    switch (id) {
      case 'police':
        return Icons.local_police_outlined;
      case 'selcom_go_support':
        return Icons.support_agent_outlined;
      default:
        return Icons.phone_in_talk_outlined;
    }
  }

  Future<void> dialEmergencyContact(EmergencyContactModel contact) async {
    final primary = contact.phone.trim();
    final secondary = contact.secondaryPhone?.trim() ?? '';
    final phone = primary.isNotEmpty ? primary : secondary;
    if (phone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: contact.label.isEmpty ? AppStrings.call.tr : contact.label,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    await _launchSystemPhoneDialer(
      phone: phone,
      errorDialogTitle: contact.label.isEmpty
          ? AppStrings.call.tr
          : contact.label,
    );
  }

  void _handleStopUpdateRecovery() {
    final pending = ride.value?.pendingStopsUpdate;
    if (pending == null) return;

    if (pending.status == 'pending_payment') {
      // Trust the backend: if it's in the response, it's not expired yet
      stopUpdatePreview.value = StopUpdatePreviewModel(
        fareChanged: true,
        oldFareEstimate: ride.value?.fareEstimate ?? 0,
        newFareEstimate: pending.newFare ?? 0,
        deltaAmount: pending.deltaAmount,
        direction: pending.direction,
        newDistanceKm: 0,
        newDurationMin: 0,
        waypointCharge: 0,
        legs: const [],
        stopsDiff: StopUpdateDiffModel(
          added: const [],
          removed: const [],
          reordered: false,
        ),
      );
      stopUpdateWorkingStops.assignAll(pending.stops);
      if (pending.idempotencyKey != null) {
        stopUpdateIdempotencyKey.value = pending.idempotencyKey!;
        _saveIdempotencyKey(pending.idempotencyKey!);
      }
    } else if (pending.status == 'pending_da') {
      isUpdatingStops.value = true;
      stopUpdateProgressStep.value = 2; // Route update phase
      _startStopUpdateTimeout();
    }
  }

  List<RideStopModel> get mapIntermediateStops {
    final fromRide = _intermediateStopsFromRideStops();
    if (fromRide.isNotEmpty) return fromRide;
    return _intermediateStopsFromRouteDestinations();
  }

  List<RideStopModel> _intermediateStopsFromRideStops() {
    final stops = ride.value?.stops ?? const <RideStopModel>[];
    if (stops.isEmpty) return const [];

    final filtered = stops
        .where(
          (stop) =>
              !MapRouteMarkerUtils.stopMatchesDestination(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                destinationLat: destinationLatLng.latitude,
                destinationLng: destinationLatLng.longitude,
                destinationAddress: destinationAddress,
              ) &&
              !MapRouteMarkerUtils.stopMatchesPickup(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                pickupLat: pickupLatLng.latitude,
                pickupLng: pickupLatLng.longitude,
                pickupAddress: pickupAddress,
              ),
        )
        .toList();

    final orderedEntries = filtered.asMap().entries.toList()
      ..sort((a, b) {
        final byRouteIndex = a.value.index.compareTo(b.value.index);
        if (byRouteIndex != 0) return byRouteIndex;
        return a.key.compareTo(b.key);
      });

    return MapRouteMarkerUtils.dedupeByLocation(
      items: orderedEntries.map((entry) => entry.value).toList(),
      lat: (stop) => stop.lat,
      lng: (stop) => stop.lng,
      address: (stop) => stop.address,
    );
  }

  List<RideStopModel> _intermediateStopsFromRouteDestinations() {
    if (routeDestinations.length <= 1) return const [];

    final candidates = routeDestinations
        .take(routeDestinations.length - 1)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => RideStopModel(
            index: entry.key + 1,
            lat: entry.value.lat,
            lng: entry.value.lng,
            address: entry.value.address,
            status: 'pending',
          ),
        )
        .where(
          (stop) =>
              !MapRouteMarkerUtils.stopMatchesDestination(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                destinationLat: destinationLatLng.latitude,
                destinationLng: destinationLatLng.longitude,
                destinationAddress: destinationAddress,
              ) &&
              !MapRouteMarkerUtils.stopMatchesPickup(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                pickupLat: pickupLatLng.latitude,
                pickupLng: pickupLatLng.longitude,
                pickupAddress: pickupAddress,
              ),
        )
        .toList();

    return MapRouteMarkerUtils.dedupeByLocation(
      items: candidates,
      lat: (stop) => stop.lat,
      lng: (stop) => stop.lng,
      address: (stop) => stop.address,
    );
  }

  String routeLetterForIntermediateIndex(int sequentialIndex) =>
      MapRouteMarkerUtils.letterAt(sequentialIndex + 1);

  BitmapDescriptor redRouteLetterIconForSequentialIndex(int sequentialIndex) {
    final letter = routeLetterForIntermediateIndex(sequentialIndex);
    return RouteMapMarkerIcons.cached(
          letter: letter,
          color: RoutePinLetterStyle.intermediateColor(sequentialIndex),
        ) ??
        dropIcon.value ??
        BitmapDescriptor.defaultMarker;
  }

  bool get usesMultiStopRouteMarkers {
    return MapRouteMarkerUtils.usesMultiStopMarkers(
      isMultiStopFlag: ride.value?.isMultiStop ?? routeDestinations.length > 1,
      intermediateStopCount: mapIntermediateStops.length,
    );
  }

  Future<void> _ensureRouteLetterIcons() async {
    if (_routeLetterIconsLoaded) return;

    await RouteMapMarkerIcons.ensureLetterPinCache();
    for (int i = 0; i < MapRouteMarkerUtils.routeLetters.length - 1; i++) {
      final letter = MapRouteMarkerUtils.letterAt(i + 1);
      _redRouteLetterIcons[letter] = RouteMapMarkerIcons.cached(
        letter: letter,
        color: RoutePinLetterStyle.intermediateColor(i),
      )!;
    }
    for (int i = 1; i < MapRouteMarkerUtils.routeLetters.length; i++) {
      final letter = MapRouteMarkerUtils.routeLetters[i];
      _greenRouteLetterIcons[letter] = RouteMapMarkerIcons.cached(
        letter: letter,
        color: RoutePinLetterStyle.destinationColor,
      )!;
    }

    _routeLetterIconsLoaded = true;
  }

  Future<void> _loadMarkerIcons() async {
    final loadToken = ++_markerIconLoadToken;
    await _ensureRouteLetterIcons();
    if (loadToken != _markerIconLoadToken) return;

    final bool isMulti = usesMultiStopRouteMarkers;

    if (!isMulti) {
      pickupIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'P',
        color: RoutePinLetterStyle.pickupColor,
      );
      dropIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'D',
        color: RoutePinLetterStyle.destinationColor,
      );
      stopIcons.clear();
      return;
    }

    final intermediateCount = mapIntermediateStops.length;
    pickupIcon.value = await RouteMapMarkerIcons.pin(
      letter: RoutePinLetterStyle.pickupLetter(
        intermediateStopCount: intermediateCount,
      ),
      color: RoutePinLetterStyle.pickupColor,
    );

    final destLetter = MapRouteMarkerUtils.letterAt(
      MapRouteMarkerUtils.destinationLetterIndex(
        intermediateStopCount: intermediateCount,
      ),
    );
    dropIcon.value = _greenRouteLetterIcons[destLetter];

    final icons = List<BitmapDescriptor>.generate(
      intermediateCount,
      (i) => _redRouteLetterIcons[MapRouteMarkerUtils.letterAt(i + 1)]!,
    );
    stopIcons.assignAll(icons);
  }

  /// Stops ride fallback polling when the session is invalidated.
  void onSessionExpired() {
    isUpdatingStops.value = false;
    isUpdatingDestination.value = false;
    stopUpdateProgressStep.value = 0;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopNoShowCountdown();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _rideStopSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _chatSub?.cancel();
    _fareSettledSub?.cancel();
    _driverCancelledSub?.cancel();
    _rideStopsUpdatedSub?.cancel();
    _rideStopsUpdateFailedSub?.cancel();
    _paymentStatusSub?.cancel();
    if (!_skipRideRoomLeaveOnClose && rideId.isNotEmpty) {
      _socketService.leaveRideRoom(rideId: rideId);
    }
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _recoverRealtimeStateOnResume();
  }

  void _recoverRealtimeStateOnResume() {
    if (_isHandlingAppResume || rideId.isEmpty) return;
    _isHandlingAppResume = true;
    Future.microtask(() async {
      try {
        await _fetchRideDetails();
        await _socketService.connect();
        _joinRideRoomIfNeeded();
      } finally {
        _isHandlingAppResume = false;
      }
    });
  }

  void _parseArgs() {
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    // Prefer toString — socket/nav args may not always be a Dart [String].
    rideId = args['rideId']?.toString().trim() ?? '';
    final plat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
    final plng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
    final dlat = (args['destinationLat'] as num?)?.toDouble() ?? (plat - 0.018);
    final dlng = (args['destinationLng'] as num?)?.toDouble() ?? (plng + 0.014);
    pickupLatLng = LatLng(plat, plng);
    destinationLatLng = LatLng(dlat, dlng);
    pickupAddress = (args['pickupAddress'] as String?)?.trim() ?? '';
    destinationAddress = (args['destinationAddress'] as String?)?.trim() ?? '';
    final List<dynamic>? ds = args['destinations'];
    if (ds != null && ds.isNotEmpty) {
      try {
        // Normalize destinations payload from navigation:
        // last item = final destination, previous items = intermediate stops.
        final List<LocationEntity> locs = ds
            .map((e) {
              if (e is LocationEntity) return e;
              if (e is Map<String, dynamic>) {
                return LocationEntity(
                  lat: (e['lat'] as num?)?.toDouble() ?? 0.0,
                  lng: (e['lng'] as num?)?.toDouble() ?? 0.0,
                  address: (e['address'] as String?)?.trim() ?? '',
                );
              }
              if (e is Map) {
                final m = Map<String, dynamic>.from(e);
                return LocationEntity(
                  lat: (m['lat'] as num?)?.toDouble() ?? 0.0,
                  lng: (m['lng'] as num?)?.toDouble() ?? 0.0,
                  address: (m['address'] as String?)?.trim() ?? '',
                );
              }
              return null;
            })
            .whereType<LocationEntity>()
            .toList();

        if (locs.isNotEmpty) {
          routeDestinations.assignAll(locs);
          final finalDestination = locs.last;
          if (finalDestination.lat != 0 && finalDestination.lng != 0) {
            destinationLatLng = LatLng(
              finalDestination.lat,
              finalDestination.lng,
            );
          }
          if (finalDestination.address.trim().isNotEmpty) {
            destinationAddress = finalDestination.address.trim();
          }
          summaryIntermediateStops.assignAll(
            locs
                .take(locs.length - 1)
                .map((e) => e.address.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          );
        }
      } catch (_) {}
    }
    final rawFareBreakdown = args['fareBreakdown'];
    if (rawFareBreakdown is Map) {
      final fareBreakdown = Map<String, dynamic>.from(rawFareBreakdown);
      _seedRideCharge = (fareBreakdown['ride_charge'] as num?)?.toInt();
      _seedBookingFee = (fareBreakdown['booking_fee'] as num?)?.toInt();
      _seedTotalAmount = (fareBreakdown['total_amount'] as num?)?.toInt();
    }
    routePoints.clear();
    routeTarget.value = 'pick_up';
    _hydrateSocketSeedPayloads(args);
    _refreshMapRouteHeader();
    _skipInitialRideDetailsFetch = skipInitialRideDetailsFetchFromNavigationArgs(
      args,
    );
    _prefetchedRide = prefetchedRideFromNavigationArgs(args);
  }

  /// Updates [routeTarget] only — polylines come from `ride:tracking_update`
  /// `route_geometry` via [TrackingRouteGeometryUtils.shouldDrawPolyline].
  void _setDropRouteFallback() {
    routeTarget.value = 'drop_off';
  }

  void _setPickupRouteFallback() {
    routeTarget.value = 'pick_up';
  }

  void _clearRouteAwaitingTrackingUpdate() {
    if (routePoints.isEmpty) return;
    routePoints.clear();
    isInitialRouteLoaded.value = false;
  }

  void _markInitialRouteReady() {
    if (!isInitialRouteLoaded.value) {
      isInitialRouteLoaded.value = true;
    }
  }

  void _hydrateSocketSeedPayloads(Map<String, dynamic> args) {
    AppLogger.d(
      '💧 Hydrating socket seed payloads from args: $args',
      tag: 'ORDER_TRACKING',
    );
    final statusRaw = args['statusPayload'];
    if (statusRaw is Map) {
      final payload = EventRiderStatusUpdateResponse.fromJson(
        Map<String, dynamic>.from(statusRaw),
      );
      _applyStatusPayload(payload);
    }
    final driverRaw = args['driverLocationPayload'];
    if (driverRaw is Map) {
      final payload = DriverLocationSocketResponse.fromJson(
        Map<String, dynamic>.from(driverRaw),
      );
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat != null && lng != null) {
        assignedDriverLocation.value = LatLng(lat, lng);
      }
    }
    final trackingRaw = args['trackingPayload'];
    if (trackingRaw is Map) {
      _hasReceivedTrackingUpdate = true;
      final payload = TrackingUpdateSocketResponse.fromJson(
        Map<String, dynamic>.from(trackingRaw),
      );
      _applyTrackingPayload(payload);
    }
  }

  // Future<void> _loadMarkerIcon() async {
  //   try {
  //     await rootBundle.load(AppAssets.gariPlus);
  //     assignedDriverMarkerIcon.value = await BitmapDescriptor.asset(
  //       const ImageConfiguration(size: Size(36, 36)),
  //       AppAssets.gariPlus,
  //     );
  //   } catch (_) {}
  // }

  void _syncDestinationFromRide(RideModel? r) {
    if (r == null) return;
    final d = r.destination;
    if (d.lat != 0 && d.lng != 0) {
      destinationLatLng = LatLng(d.lat, d.lng);
    }
    final addr = d.address.trim();
    if (addr.isNotEmpty && addr != destinationAddress) {
      destinationAddress = addr;
      _refreshMapRouteHeader();
    }
    final stops = r.stops;
    if (stops.isEmpty) {
      summaryIntermediateStops.clear();
      return;
    }
    final intermediates = mapIntermediateStops;
    if (intermediates.isEmpty) {
      summaryIntermediateStops.clear();
      return;
    }
    summaryIntermediateStops.assignAll(
      intermediates
          .map((s) => s.address.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  Future<void> _fetchRideDetails() async {
    // Missing rideId is not recoverable via retry — surface error and keep fields empty.
    if (rideId.isEmpty) {
      _setRideLoadFailure(AppStrings.rideDetailsAreMissing.tr);
      return;
    }
    if (_navigatedAway) return;
    // Share one in-flight request when multiple code paths fetch at once.
    if (_rideDetailsFetchInFlight != null) {
      await _rideDetailsFetchInFlight;
      return;
    }

    _rideDetailsFetchInFlight = _fetchRideDetailsOnce();
    try {
      await _rideDetailsFetchInFlight;
    } finally {
      _rideDetailsFetchInFlight = null;
    }
  }

  Future<void> _fetchRideDetailsOnce() async {
    if (_navigatedAway) return;
    isLoadingRide.value = true;
    rideLoadError.value = null;
    final result = await rideRepository.getRideDetails(rideId);
    if (_navigatedAway) {
      isLoadingRide.value = false;
      return;
    }
    await result.fold(
      (f) async {
        // Don't paint the error sheet if we already left for rematch/searching.
        if (_navigatedAway) return;
        // Generic localized copy for UI; technical detail stays in logs only.
        _setRideLoadFailure(AppStrings.failedToLoadRideDetails.tr);
        AppLogger.w(
          'ride_details request failed: ${f.message}',
          tag: 'DriverAcceptedController',
        );
      },
      (r) async {
        await _applyRideDetailsFromModel(r.toRideModel());
      },
    );
    if (!_navigatedAway) {
      isLoadingRide.value = false;
    }
    // Removed automatic _fitRouteBounds here to prevent unwanted zoom-out during navigation.
  }

  Future<void> _applyRideDetailsFromModel(RideModel r) async {
    if (_navigatedAway) return;

    final normalized = normalizeRideStatusString(
      rideStatusToApiValue(r.status),
    );
    // Only rematch on an explicit searching status — not the broader
    // [shouldOpenFindingDriverForRide] helper (that also matches incomplete
    // / error-fallback ride payloads and was leaving this screen empty).
    if (isRideSearchingStatus(normalized)) {
      if (rideBottomSheetState.value == RideBottomSheetState.rideStarted) {
        return;
      }
      ride.value = r;
      _navigateBackToFindingDriverAfterChainBroken();
      return;
    }

    if (rideNeedsMidRideCancelScreen(r)) {
      final block = r.midRideCancel;
      if (block != null) {
        await _maybeNavigateMidRideDriverCancelled(block);
        return;
      }
    }
    rideLoadError.value = null;
    ride.value = r;
    _applyRide(r);
    _syncCancelAndNoShowFromRideModel(r);
    _syncDestinationFromRide(r);
    // HTTP details can show completion before/without a matching socket tick;
    // keep bottom-sheet state and completion navigation in sync with the model.
    _applyBottomSheetStateForStatus(rideStatusToApiValue(r.status));
    _syncLiveActivityFromDetails(r);
    await _loadMarkerIcons();

    // Debug logging for the "Stuck" state issues
    if (isUpdatingStops.value) {
      AppLogger.d(
        "STOPS_UPDATE_POLL: step=${stopUpdateProgressStep.value}, "
        "pendingStatus=${r.pendingStopsUpdate?.status}, "
        "rideStopsCount=${r.stops.length}, "
        "workingStopsCount=${stopUpdateWorkingStops.length}",
        tag: 'DriverAcceptedController',
      );
    }

    // Hardening: If we are stuck in recalculating step and pending update is gone, it succeeded!
    if (isUpdatingStops.value && stopUpdateProgressStep.value == 2) {
      if (r.pendingStopsUpdate == null) {
        _clearIdempotencyKey();
        stopUpdateProgressStep.value = 0;
        isUpdatingStops.value = false;
      } else if (stopUpdateWorkingStops.isNotEmpty &&
          r.stops.length == stopUpdateWorkingStops.length) {
        // Also succeed if the confirmed stops list now matches our target list count
        _clearIdempotencyKey();
        stopUpdateProgressStep.value = 0;
        isUpdatingStops.value = false;
      }
    }

    if (isUpdatingDestination.value && stopUpdateProgressStep.value == 2) {
      final dest = r.destination;
      final tLat = _pendingDestinationTargetLat;
      final tLng = _pendingDestinationTargetLng;
      if (tLat != null &&
          tLng != null &&
          (dest.lat - tLat).abs() < 0.00002 &&
          (dest.lng - tLng).abs() < 0.00002) {
        stopUpdateProgressStep.value = 0;
        isUpdatingDestination.value = false;
        isDestinationUpdateFlow.value = false;
        _pendingDestinationTargetLat = null;
        _pendingDestinationTargetLng = null;
        unawaited(_ensureRideRealtimeAfterLocationUpdate());
      }
    }
  }

  /// Retry is only offered when navigation supplied a [rideId].
  bool get canRetryRideLoad => rideId.isNotEmpty;

  bool get hasRideLoadError {
    final err = rideLoadError.value;
    return err != null && err.trim().isNotEmpty;
  }

  /// Bound to the error sheet primary action on [DriverAcceptedScreen].
  Future<void> retryLoadRideDetails() => _fetchRideDetails();

  /// Bound to the error sheet back action — leaves SCR-11 without fake ride content.
  void leaveAfterRideLoadFailure() {
    if (Get.isRegistered<DriverAcceptedController>()) {
      Get.back();
    }
  }

  void _setRideLoadFailure(String message) {
    if (_navigatedAway) return;
    rideLoadError.value = message;
    _clearRideDriverFields();
    isLoadingRide.value = false;
  }

  /// Clears driver/OTP/map state so a failed load never shows stale or mock content.
  void _clearRideDriverFields() {
    ride.value = null;
    driverName.value = '';
    driverPhone.value = '';
    driverAvatarUrl.value = '';
    driverRating.value = '';
    driverVehicleLine.value = '';
    plateDisplayFormatted.value = '';
    vehicleSubtitle.value = '';
    otpDigits.clear();
    assignedDriverLocation.value = null;
    isTrackingRider.value = false;
  }

  void _applyRide(RideModel r) {
    isPinRequired.value = r.pinRequired;
    final d = r.driverSnapshot;
    final v = r.vehicleSnapshot;
    String plateForVehicleLine = '';
    _syncBottomSheetVehicleImage(d?.vehicleType);
    if ((d?.vehicleType ?? '').isNotEmpty) {
      loadDriverIcon(vehicleType: d?.vehicleType);
    }

    if (d != null) {
      driverName.value = d.name;
      driverPhone.value = d.phone;
      driverAvatarUrl.value = (d.avatarUrl ?? '').trim();
      driverRating.value = d.rating > 0 ? d.rating.toStringAsFixed(1) : '—';

      // If vehicle snapshot is missing or generic, use fields from driver snapshot
      final plate = (d.vehicleRegistrationNumber ?? '').trim();
      final model = (d.vehicleModel ?? '').trim();
      final color = (d.vehicleColor ?? '').trim();
      plateForVehicleLine = plate;

      if (plate.isNotEmpty) {
        plateDisplayFormatted.value =
            TanzaniaLicensePlateFormatter.formatDisplay(plate);
      } else {
        plateDisplayFormatted.value = '';
      }
      if (model.isNotEmpty || color.isNotEmpty) {
        vehicleSubtitle.value = [
          model,
          color,
        ].where((e) => e.isNotEmpty).join(', ').trim();
      }

      if (isPinRequired.value) {
        final pin = r.pinCode.trim();
        final vCode = (d.verificationCode ?? '').trim();
        final otp = (pin.isNotEmpty ? pin : vCode).replaceAll(
          RegExp(r'\s'),
          '',
        );

        if (otp.isNotEmpty) {
          otpDigits.assignAll(otp.split('').take(4).toList());
        } else {
          otpDigits.assignAll(['—', '—', '—', '—']);
        }
      } else {
        otpDigits.clear();
      }
    } else {
      driverName.value = AppStrings.driver.tr;
      driverPhone.value = '';
      driverAvatarUrl.value = '';
      driverRating.value = '—';
      plateDisplayFormatted.value = '';
      if (isPinRequired.value) {
        otpDigits.assignAll(['—', '—', '—', '—']);
      } else {
        otpDigits.clear();
      }
    }

    if (v != null && vehicleSubtitle.value.isEmpty) {
      vehicleSubtitle.value =
          '${v.vehicleMake} ${v.vehicleModel}, ${v.vehicleColor}'.trim();
    }

    _applyUnifiedDriverVehicleLine(
      modelName: (d?.vehicleModel ?? '').trim(),
      plate: plateForVehicleLine,
      fallbackModel: (v?.vehicleModel ?? '').trim(),
    );
  }

  Future<void> _initRideRoomSocket() async {
    if (rideId.isEmpty) return;

    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _chatSub?.cancel();
    _rideStopsUpdatedSub?.cancel();
    _rideStopsUpdateFailedSub?.cancel();
    _paymentStatusSub?.cancel();
    _fareSettledSub?.cancel();
    _driverCancelledSub?.cancel();

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _joinRideRoomIfNeeded();
    });

    // Primary realtime status feed — always normalize before comparing.
    _rideStatusSub = _socketService.rideStatusStream.listen((payload) async {
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      AppLogger.d(
        '📥 Socket Event: ride_status_stream - Status: ${payload.status} for ride $rideId | ${jsonEncode(payload.toJson())}',
        tag: 'ORDER_TRACKING',
      );
      final status = (payload.status ?? '').toString().trim();
      final normalized = normalizeRideStatusString(status);

      if (normalized == 'cancelled') {
        if (_isUserInitiatedCancellation || _navigatedAway) return;
        await _syncLiveActivityFromStatusPayload(payload);
        _stopNoShowCountdown(clearInfo: true);
        if (payload.isNoShowCancellation) {
          _navigatedAway = true;
          await LiveActivityManager().endActivity(rideId);
          final message = (payload.message ?? '').trim();
          _showCancelDialogThenGoHome(
            message.isNotEmpty
                ? message
                : AppStrings.rideCancelled.tr,
          );
          return;
        }
        await _maybeNavigateMidRideDriverCancelled();
        if (_navigatedAway) return;
        _navigatedAway = true;
        await LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(AppStrings.rideCancelled.tr);
        return;
      }
      if (normalized == 'no_driver_found' || normalized == 'no_drivers_found') {
        if (_navigatedAway) return;
        _navigatedAway = true;
        await _syncLiveActivityFromStatusPayload(payload);
        await LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(
          AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr,
        );
        return;
      }

      if (normalized == 'searching') {
        if (_navigatedAway) return;
        // On driver-accepted during pickup (including chained assignment),
        // searching means the chain broke / rematch started — always return to
        // the finding-driver searching sheet.
        if (rideBottomSheetState.value == RideBottomSheetState.rideStarted) {
          return;
        }
        _navigateBackToFindingDriverAfterChainBroken();
        return;
      }

      if (_navigatedAway) return;
      // _applyStatusPayload already applies status; avoid duplicate completion triggers.
      _applyStatusPayload(payload);
      await _syncLiveActivityFromStatusPayload(payload);
    });

    _rideStopSub = _socketService.rideStopUpdateStream.listen((payload) {
      if (_navigatedAway) return;
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      _applyStatusPayload(payload);
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      if (payload.latitude == 0 || payload.longitude == 0) return;

      // Strict city-region validation for Dar es Salaam
      if (payload.latitude! < -15 ||
          payload.latitude! > 0 ||
          payload.longitude! < 20 ||
          payload.longitude! > 50) {
        return;
      }

      final lat = payload.latitude;
      final lng = payload.longitude;
      final head = payload.heading;
      final speed = (payload.speed ?? 0.0).toDouble(); // m/s
      if (lat == null || lng == null) return;

      final rawPos = LatLng(lat, lng);

      // 1. Update the base location with RAW GPS
      assignedDriverLocation.value = rawPos;
      if (_shouldHideDriverSpeedFor(
        status: currentRideStatus.value,
        driverPosition: rawPos,
        speedMps: speed,
      )) {
        assignedDriverSpeed.value = 0;
      } else {
        assignedDriverSpeed.value = speed;
      }

      // 2. High-Fidelity Interpolation:
      // We calculate duration based on REAL speed for a butter-smooth glide.
      Duration animDuration = const Duration(milliseconds: 3500);

      if (speed > 0.5) {
        final currentPos =
            mapWidgetKey.currentState?.currentAnimatedPosition ??
            assignedDriverLocation.value!;
        final distance = _calculateDistanceInMeters(currentPos, rawPos);

        // 🏎️ High-Speed Optimization:
        // Use a tighter buffer (5% instead of 15%) to prevent lag accumulation.
        // Cap duration more aggressively at 5s to force catch-up.
        double secondsNeeded = (distance / speed) * 1.05;
        int millis = (secondsNeeded * 1000).toInt();

        millis = millis.clamp(1200, 5000);
        animDuration = Duration(milliseconds: millis);
      } else {
        // If slow or stopped, use a more conservative 4s glide to match
        // the typical 3-5s socket frequency.
        animDuration = const Duration(milliseconds: 4000);
      }

      final parsedHeading = MapVehicleMarkerUtils.parseHeadingDegrees(head);
      final rotationFrom =
          _lastDriverRotationSamplePosition ??
          mapWidgetKey.currentState?.currentAnimatedPosition;

      assignedDriverHeading.value = _resolveAssignedDriverHeading(
        currentPosition: rawPos,
        previousPosition: rotationFrom,
        headingDegrees: parsedHeading,
        previousRotation: assignedDriverHeading.value,
        speedMps: speed,
      );

      if (!isDriverFinishingNearby.value) {
        if (rotationFrom != null) {
          final moved = _calculateDistanceInMeters(rotationFrom, rawPos);
          if (moved >= MapVehicleMarkerUtils.minMovementMetersForBearing) {
            _lastDriverRotationSamplePosition = rawPos;
          }
        } else {
          _lastDriverRotationSamplePosition = rawPos;
        }
      }

      mapWidgetKey.currentState?.updateRiderPosition(
        rawPos,
        rotation: assignedDriverHeading.value,
        duration: animDuration,
      );
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((
      payload,
    ) async {
      if (payload != null) {
        if (_navigatedAway) return;
        if (!_isSocketEventForThisRide(payload.rideId)) return;
        _hasReceivedTrackingUpdate = true;
        AppLogger.d(
          '📥 Socket Event: tracking_update_socket - Target: ${payload.routeTarget} for ride $rideId | ${jsonEncode(payload.toJson())}',
          tag: 'ORDER_TRACKING',
        );
        _applyTrackingPayload(payload);
      }
    });

    _fareSettledSub = _socketService.rideFareSettledStream.listen((payload) {
      BookAnyFareSettledUi.maybeShow(payload: payload, rideId: rideId);
    });

    _driverCancelledSub = _socketService.rideDriverCancelledStream.listen((
      payload,
    ) async {
      if (payload.rideId.trim() != rideId) return;
      if (_navigatedAway) return;
      await _maybeNavigateMidRideDriverCancelled(
        payload.toMidRideCancelModel(),
      );
    });

    // Ensure socket is connected for the active-ride entry path too.
    await _socketService.connect();
    if (_socketService.isConnected) {
      _joinRideRoomIfNeeded();
    }

    _chatSub = _socketService.chatStream.listen((data) {
      final payloadRideId =
          (data['ride_id'] ?? data['rideId'])?.toString().trim() ?? '';

      if (payloadRideId != rideId) return;

      final senderType =
          (data['sender_type'] ?? data['sender'] ?? data['role'])
              ?.toString()
              .toLowerCase() ??
          '';

      final bool isFromRider =
          senderType == 'rider' ||
          senderType == 'user' ||
          senderType == 'passenger';

      if (!isFromRider && !Get.currentRoute.contains(AppRoutes.rideMessage)) {
        unreadCount.value++;

        final msg = data['message'] ?? data['text'] ?? AppStrings.newMessage.tr;

        NotificationService().showLocalNotification(
          title: AppStrings.newMessage.tr,
          body: msg.toString(),
          payload: jsonEncode(data),
        );
      }
    });

    _rideStopsUpdatedSub = _socketService.rideStopsUpdatedStream.listen((res) {
      if (res.rideId != rideId) return;
      _clearIdempotencyKey();
      isUpdatingStops.value = false;
      stopUpdateProgressStep.value = 0;
      _clearRouteAwaitingTrackingUpdate();
      unawaited(_ensureRideRealtimeAfterLocationUpdate());
      _fetchRideDetails();
    });

    _rideStopsUpdateFailedSub = _socketService.rideStopsUpdateFailedStream
        .listen((res) {
          if (res.rideId != rideId) return;
          _clearIdempotencyKey();
          isUpdatingStops.value = false;
          stopUpdateProgressStep.value = 0;

          String userMessage = res.reason;
          if (res.reason == 'da_patch_rejected') {
            userMessage =
                AppStrings.driversAppCouldntBeUpdatedBillingAdjustedBack.tr;
          } else if (res.reason == 'payment_failed') {
            userMessage = AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr;
          }

          AppDialogs.showErrorDialog(
            title: AppStrings.updateFailed.tr,
            message: userMessage,
          );
        });

    _paymentStatusSub = _socketService.paymentStatusStream.listen(
      _handlePaymentBlockStatus,
    );
  }

  /// Ignores socket ticks from other active rides when Home joined multiple rooms.
  bool _isSocketEventForThisRide(String? payloadRideId) {
    return socketPayloadIsForRide(
      activeRideId: rideId,
      payloadRideId: payloadRideId,
      joinedRideRoomId: _socketService.joinedRideRoomId,
    );
  }

  Future<void> _ensureRideRealtimeAfterLocationUpdate() async {
    if (rideId.isEmpty) return;
    try {
      await _socketService.ensureConnected();
      _joinRideRoomIfNeeded();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.w(
        'Ride socket rejoin after location update failed',
        tag: 'DriverAcceptedController',
      );
    }
  }

  bool? _paymentBlockOutcome(PaymentStatusUpdateResponse event) {
    final phase = (event.phase ?? '').toString().toLowerCase();
    final status = (event.status ?? '').toString().toLowerCase();

    if (phase.isNotEmpty && phase != 'block') return null;

    if (status == 'confirmed' || status == 'completed') {
      return true;
    }
    if (status == 'failed') {
      return false;
    }
    return null;
  }

  void _handlePaymentBlockStatus(PaymentStatusUpdateResponse event) {
    final outcome = _paymentBlockOutcome(event);
    if (outcome == null) return;

    if (isUpdatingStops.value && stopUpdateProgressStep.value == 1) {
      if (outcome) {
        stopUpdateProgressStep.value = 2;
        unawaited(_ensureRideRealtimeAfterLocationUpdate());
      } else {
        isUpdatingStops.value = false;
        stopUpdateProgressStep.value = 0;
        _showStopUpdateError(
          AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr,
        );
      }
      return;
    }

    if (isUpdatingDestination.value && stopUpdateProgressStep.value == 1) {
      if (outcome) {
        stopUpdateProgressStep.value = 2;
        unawaited(_ensureRideRealtimeAfterLocationUpdate());
      } else {
        isUpdatingDestination.value = false;
        isDestinationUpdateFlow.value = false;
        stopUpdateProgressStep.value = 0;
        _pendingDestinationTargetLat = null;
        _pendingDestinationTargetLng = null;
        _showDestinationUpdateError(
          AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr,
        );
      }
    }
  }

  void _joinRideRoomIfNeeded() {
    if (!_socketService.isConnected || rideId.isEmpty) {
      return;
    }
    _socketService.switchRideRoom(rideId: rideId);
  }

  Future<void> loadDriverIcon({String? vehicleType}) async {
    try {
      final assetPath = MapVehicleMarkerUtils.markerAssetForVehicleType(
        vehicleType,
      );
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        assetPath,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error loading map marker icon ($vehicleType): $e",
        tag: 'DriverAcceptedController',
        error: e,
        stackTrace: stackTrace,
      );
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        AppAssets.mapMarkerCab,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    }
  }

  void _showCancelDialogThenGoHome(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDialogs.showErrorDialog(
        title: AppStrings.rideCancelled.tr,
        message: message,
        onConfirm: () => Get.offAllNamed(AppRoutes.home),
      );
    });
  }

  /// Ride chaining broke: assigned driver no longer available — resume driver search.
  ///
  /// Replaces SCR-11 (driver accepted) with SCR-10 (finding driver) using the
  /// same searching labels as a normal match. Sets [_navigatedAway] so in-flight
  /// [getRideDetails] responses do not paint the "unable to open ride details"
  /// error sheet after we leave.
  void _navigateBackToFindingDriverAfterChainBroken() {
    if (_navigatedAway) return;
    _navigatedAway = true;
    _skipRideRoomLeaveOnClose = true;
    isDriverFinishingNearby.value = false;

    AppLogger.d(
      'Chain broken → navigating to finding-driver (searching) for ride $rideId',
      tag: 'ORDER_TRACKING',
    );

    final currentRide = ride.value;
    if (currentRide != null) {
      navigateToFindingDriverForRide(
        currentRide.copyWith(status: RideStatus.searching),
        replace: true,
        chainBroken: true,
      );
      return;
    }

    final fareBreakdown =
        (_seedRideCharge != null ||
            _seedBookingFee != null ||
            _seedTotalAmount != null)
        ? {
            if (_seedRideCharge != null) 'ride_charge': _seedRideCharge,
            if (_seedBookingFee != null) 'booking_fee': _seedBookingFee,
            if (_seedTotalAmount != null) 'total_amount': _seedTotalAmount,
          }
        : null;

    final destinations = routeDestinations.isNotEmpty
        ? routeDestinations
              .map((e) => {'lat': e.lat, 'lng': e.lng, 'address': e.address})
              .toList()
        : [
            {
              'lat': destinationLatLng.latitude,
              'lng': destinationLatLng.longitude,
              'address': destinationAddress,
            },
          ];

    Get.offNamed(
      AppRoutes.findingDriver,
      arguments: {
        'rideId': rideId,
        'pickupLat': pickupLatLng.latitude,
        'pickupLng': pickupLatLng.longitude,
        'pickupAddress': pickupAddress,
        'destinationLat': destinationLatLng.latitude,
        'destinationLng': destinationLatLng.longitude,
        'destinationAddress': destinationAddress,
        'destinations': destinations,
        if (fareBreakdown != null) 'fareBreakdown': fareBreakdown,
        kFindingDriverChainBrokenArg: true,
      },
    );
  }

  Future<void> _handleRideCancelledFromTracking() async {
    await _maybeNavigateMidRideDriverCancelled();
    if (_navigatedAway) return;
    _navigatedAway = true;
    _showCancelDialogThenGoHome(AppStrings.rideCancelled.tr);
  }

  Future<void> _maybeNavigateMidRideDriverCancelled([
    MidRideCancelModel? seed,
  ]) async {
    if (_navigatedAway) return;
    final block = seed ?? await _loadMidRideCancelBlock();
    if (block == null) return;
    _navigatedAway = true;
    _skipRideRoomLeaveOnClose = true;
    await showMidRideDriverCancelledDialog(rideId: rideId, cancel: block);
  }

  Future<MidRideCancelModel?> _loadMidRideCancelBlock() async {
    if (rideId.isEmpty) return null;
    final result = await rideRepository.getRideDetails(rideId);
    return result.fold((_) => null, (r) {
      if (!r.isMidRideDriverCancel) return null;
      return r.toRideModel().midRideCancel;
    });
  }

  void _syncBottomSheetVehicleImage(String? vehicleType) {
    final previousAsset = bottomSheetVehicleImageAsset.value;
    bottomSheetVehicleImageAsset
        .value = VehicleImageUtils.imageAssetForVehicleType(
      vehicleType,
      // Keep previously resolved vehicle image when an event payload
      // doesn't include enough vehicle metadata (common during stop transitions).
      fallbackAsset: previousAsset.isNotEmpty
          ? previousAsset
          : AppAssets.imgCab,
    );
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitRouteBounds();
    scheduleAssignedEtaOverlayRefresh();
  }

  void scheduleAssignedEtaOverlayRefresh() {
    Future.microtask(refreshAssignedDriverEtaOverlay);
  }

  Future<void> refreshAssignedDriverEtaOverlay() async {
    final ctrl = mapController;
    final pos = animatedRiderLocation.value ?? assignedDriverLocation.value;
    if (ctrl == null || pos == null) {
      assignedDriverEtaScreenPx.value = null;
      return;
    }
    final px = await AppMapService.screenOffsetFor(ctrl, pos);
    assignedDriverEtaScreenPx.value = px;
  }

  void recenterMap() {
    if (onRecenterPressed != null) {
      onRecenterPressed!();
    } else {
      _fitRouteBounds(force: true);
    }
  }

  Future<void> _fitRouteBounds({bool force = false}) async {
    final ctrl = mapController;
    if (ctrl == null) return;

    // Throttling: prevent rapid animations unless forced (e.g. by recenter button)
    // At most one update every 5 seconds to avoid flickering on every socket event.
    final now = DateTime.now();
    if (!force &&
        _lastCameraUpdate != null &&
        now.difference(_lastCameraUpdate!) < const Duration(seconds: 5)) {
      return;
    }

    final points = <LatLng>[];
    final assigned = assignedDriverLocation.value;

    // "Show driver to pickup only" when in driverAssigned status
    if (rideBottomSheetState.value == RideBottomSheetState.driverAssigned) {
      if (assigned != null) points.add(assigned);
      points.add(pickupLatLng);
    } else {
      // Focusing on segment: Pickup/Current -> Destination
      if (assigned != null) points.add(assigned);
      points.add(destinationLatLng);

      // Also include all stops for multi-stop rides to show the whole route
      final stops = ride.value?.stops ?? [];
      for (final s in stops) {
        points.add(LatLng(s.lat, s.lng));
      }
    }

    if (routePoints.isNotEmpty) {
      points.addAll(routePoints);
    }

    // Sanity Filter: Remove (0,0) and extreme outliers relative to the driver.
    if (assigned != null) {
      final filtered = points.where((p) {
        if (p.latitude == 0 && p.longitude == 0) return false;
        final dLat = (p.latitude - assigned.latitude).abs();
        final dLng = (p.longitude - assigned.longitude).abs();
        return dLat < 0.2 && dLng < 0.2; // Approx 20km
      }).toList();
      points.clear();
      points.addAll(filtered);
    } else {
      points.removeWhere((p) => p.latitude == 0 && p.longitude == 0);
    }

    if (points.isEmpty) return;
    _lastCameraUpdate = now;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    try {
      // Ensure the bounds have at least some area to prevent rendering glitches
      double latDelta = (maxLat - minLat).abs();
      double lngDelta = (maxLng - minLng).abs();
      if (latDelta < 0.001) {
        minLat -= 0.001;
        maxLat += 0.001;
      }
      if (lngDelta < 0.001) {
        minLng -= 0.001;
        maxLng += 0.001;
      }

      await ctrl.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          72, // Slightly more padding for comfort
        ),
      );
    } catch (e) {
      // Fallback if bounds animation fails
      if (points.isNotEmpty) {
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      }
    }
  }

  /// Applies driver/vehicle/PIN/route data from a status payload (socket or navigation seed).
  void _applyStatusPayload(EventRiderStatusUpdateResponse payload) {
    final status = (payload.status ?? '').toString().trim();
    if (status.isNotEmpty) {
      _applyBottomSheetStateForStatus(status);
      _applyRouteFallbackForStatus(status);
    }

    final d = payload.driverSnapshot;
    final v = payload.vehicleSnapshot;
    String plateForVehicleLine = '';
    _syncBottomSheetVehicleImage(d?.vehicleType);
    if ((d?.vehicleType ?? '').isNotEmpty) {
      loadDriverIcon(vehicleType: d?.vehicleType);
    }

    if (payload.pinRequired != null) {
      isPinRequired.value = payload.pinRequired == true;
    }

    if (d != null) {
      if ((d.name ?? '').trim().isNotEmpty) driverName.value = d.name!.trim();
      if ((d.phone ?? '').trim().isNotEmpty) {
        driverPhone.value = d.phone!.trim();
      }
      final avatar = (d.avatarUrl ?? '').trim();
      if (avatar.isNotEmpty) {
        driverAvatarUrl.value = avatar;
      }
      if ((d.lat) != null && (d.lng) != null) {
        assignedDriverLocation.value = LatLng(d.lat!, d.lng!);
      }
      if (isPinRequired.value) {
        final pin = (payload.pinCode ?? '').trim();
        final vCode = (payload.driverSnapshot?.verificationCode ?? '').trim();
        final otp = (pin.isNotEmpty ? pin : vCode).replaceAll(
          RegExp(r'\s'),
          '',
        );

        if (otp.isNotEmpty) {
          otpDigits.assignAll(otp.split('').take(4).toList());
        } else if (otpDigits.isEmpty) {
          otpDigits.assignAll(['—', '—', '—', '—']);
        }
      } else {
        otpDigits.clear();
      }
      final vehicleModel = (d.vehicleModel ?? '').trim();
      final vehicleColor = (d.vehicleColor ?? '').trim();
      final plate = (d.vehicleRegistrationNumber ?? '').trim();
      plateForVehicleLine = plate;

      if (vehicleModel.isNotEmpty || vehicleColor.isNotEmpty) {
        final subtitle = '$vehicleModel, $vehicleColor'
            .replaceAll(RegExp(r'(^,\s*|\s*,\s*$)'), '')
            .trim();
        if (subtitle.isNotEmpty) vehicleSubtitle.value = subtitle;
      }
      if (plate.isNotEmpty) {
        plateDisplayFormatted.value =
            TanzaniaLicensePlateFormatter.formatDisplay(plate);
      } else {
        plateDisplayFormatted.value = '';
      }
    }

    _applyUnifiedDriverVehicleLine(
      modelName: (d?.vehicleModel ?? '').trim(),
      plate: plateForVehicleLine,
      fallbackModel: (v?.vehicleName ?? '').trim(),
    );

    _applyDriverRatingFromStatusPayload(payload, d);

    if (!isPinRequired.value) {
      otpDigits.clear();
    }

    final oldStatus = currentRideStatus.value;
    final oldTarget = routeTarget.value;

    final target = _normalizeRouteTarget(payload.routeTarget);
    final routeTargetChanged = target.isNotEmpty && target != oldTarget;
    _applyRouteGeometryFromPayload(
      routeTarget: target,
      coordinates: payload.routeGeometry?.coordinates,
      fitCameraOnChange: status != oldStatus || routeTargetChanged,
    );
    if (target.isEmpty && status.isNotEmpty) {
      // Active-ride entry can provide status without routeTarget.
      _applyRouteFallbackForStatus(status);
      if (status != oldStatus || routeTarget.value != oldTarget) {
        _fitRouteBounds();
      }
    }

    if (payload.currentStopIndex != null) {
      final currentRide = ride.value;
      if (currentRide != null) {
        ride.value = currentRide.copyWith(
          currentStopIndex: payload.currentStopIndex,
        );
      }
    }

    final rootEta = payload.etaSeconds;
    // Apply finishing flag first so ETA labels restore correctly when it becomes false.
    _setDriverFinishingNearby(payload.driverFinishingNearby);
    if (rootEta != null && rootEta.toDouble() > 0) {
      _applySocketEtaSecondsToLabels(rootEta.toDouble(), skipIfArrived: true);
    }

    _syncCancelAndNoShowFromStatusPayload(payload);
  }

  void _syncCancelAndNoShowFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
  ) {
    if (payload.cancelInfoFieldPresent) {
      cancelInfo.value = payload.cancelInfo;
      final current = ride.value;
      if (current != null) {
        ride.value = current.copyWith(
          cancelInfo: payload.cancelInfo,
          clearCancelInfo: payload.cancelInfo == null,
        );
      }
    }

    if (payload.noShowFieldPresent) {
      if (payload.isNoShowCancellation || payload.noShow == null) {
        _clearNoShowInfo();
      } else {
        _armNoShowInfo(payload.noShow!);
      }
    }
  }

  void _syncCancelAndNoShowFromRideModel(RideModel r) {
    if (r.cancelInfo != null) {
      cancelInfo.value = r.cancelInfo;
    }
    if (r.noShow != null) {
      // Prefer banner copy already armed from active/status payload.
      _armNoShowInfo(
        r.noShow!.mergingDisplayFrom(noShowInfo.value),
      );
      return;
    }
    final normalized = normalizeRideStatusString(rideStatusToApiValue(r.status));
    if (normalized == 'ride_started' ||
        normalized == 'ride_in_progress' ||
        normalized == 'near_destination' ||
        normalized == 'completed' ||
        normalized == 'ride_completed' ||
        normalized == 'cancelled') {
      _clearNoShowInfo();
    }
  }

  void _armNoShowInfo(RideNoShowInfoModel info) {
    // Keep title/subtitle from active/socket when a later details refresh
    // only sends fire_at / fee without banner copy.
    final merged = info.mergingDisplayFrom(noShowInfo.value);
    noShowInfo.value = merged;
    isNoShowExpiring.value = false;
    final fireIso = merged.fireAt.toIso8601String();
    if (_armedNoShowFireAtIso == fireIso && _noShowCountdown != null) {
      noShowCountdownLabel.value = merged.formatRemainingMmSs();
      final current = ride.value;
      if (current != null) {
        ride.value = current.copyWith(noShow: merged);
      }
      return;
    }
    _armedNoShowFireAtIso = fireIso;
    noShowCountdownLabel.value = merged.formatRemainingMmSs();
    _noShowCountdown?.stop();
    _noShowCountdown = PaymentCountdownTimer(
      onTick: (remainingSeconds) {
        final mins = remainingSeconds ~/ 60;
        final secs = remainingSeconds % 60;
        noShowCountdownLabel.value =
            '${mins.toString().padLeft(2, '0')}:'
            '${secs.toString().padLeft(2, '0')}';
      },
      onExpired: () {
        // Display-only — server cancels; show brief waiting state.
        noShowCountdownLabel.value = '00:00';
        isNoShowExpiring.value = true;
      },
    )..startUntil(merged.fireAt);

    final current = ride.value;
    if (current != null) {
      ride.value = current.copyWith(noShow: merged);
    }
  }

  void _clearNoShowInfo() {
    _stopNoShowCountdown(clearInfo: true);
  }

  void _stopNoShowCountdown({bool clearInfo = false}) {
    _noShowCountdown?.stop();
    _noShowCountdown = null;
    _armedNoShowFireAtIso = null;
    isNoShowExpiring.value = false;
    if (clearInfo) {
      noShowInfo.value = null;
      noShowCountdownLabel.value = '00:00';
      final current = ride.value;
      if (current != null && current.noShow != null) {
        ride.value = current.copyWith(clearNoShow: true);
      }
    }
  }

  void _applyUnifiedDriverVehicleLine({
    required String modelName,
    required String plate,
    String fallbackModel = '',
  }) {
    final model = modelName.trim().isNotEmpty
        ? modelName.trim()
        : fallbackModel.trim();
    final rawRegistration = plate.trim();
    final registration = rawRegistration.isEmpty
        ? ''
        : TanzaniaLicensePlateFormatter.formatDisplay(rawRegistration);
    final line = [model, registration].where((e) => e.isNotEmpty).join(' - ');
    if (line.isNotEmpty) {
      driverVehicleLine.value = line;
    }
  }

  /// Prefer root `driver_avg_rating` from [ride:status_update], then snapshot `rating`.
  void _applyDriverRatingFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
    DriverSnapshot? d,
  ) {
    final fromRoot = _socketAverageRatingLabel(payload.driverAvgRating);
    if (fromRoot != null) {
      driverRating.value = fromRoot;
      return;
    }
    final snap = d?.rating;
    if (snap != null && snap > 0) {
      driverRating.value = snap.toStringAsFixed(1);
    }
  }

  String? _socketAverageRatingLabel(num? raw) {
    if (raw == null) return null;
    final v = raw.toDouble();
    if (v <= 0) return null;
    return v.toStringAsFixed(1);
  }

  /// Maps status → bottom sheet variant (pickup vs in-trip) and updates [currentRideStatus].
  void _applyBottomSheetStateForStatus(String rawStatus) {
    final normalizedStatus = normalizeRideStatusString(rawStatus);
    if (normalizedStatus.isEmpty) return;
    currentRideStatus.value = normalizedStatus;
    if (_isReachedStatusForSpeedHide(normalizedStatus)) {
      assignedDriverSpeed.value = 0;
    }

    if (normalizedStatus == 'cancelled' ||
        normalizedStatus == 'no_driver_found' ||
        normalizedStatus == 'no_drivers_found') {
      return;
    }

    RideBottomSheetState nextState = RideBottomSheetState.driverAssigned;
    if (normalizedStatus == 'ride_started' ||
        normalizedStatus == 'ride_in_progress' ||
        normalizedStatus == 'near_destination' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'ride_completed') {
      nextState = RideBottomSheetState.rideStarted;
    }

    // Only allow state to move backwards if we are currently in 'rideCompleted'.
    // This maintains the fix for the "sticky finish button" while preventing
    // accidental regressions from 'rideStarted' back to 'driverAssigned'.
    final currentState = rideBottomSheetState.value;
    if (currentState == RideBottomSheetState.rideStarted &&
        nextState == RideBottomSheetState.driverAssigned) {
      return; // Block regression while trip is in progress
    }

    rideBottomSheetState.value = nextState;
    _syncSheetLayoutForCurrentStatus();
    if (_isDriverArrivedAtPickupStatus(normalizedStatus) ||
        nextState == RideBottomSheetState.rideStarted) {
      // Driver is free / trip started — no longer "finishing nearby".
      if (isDriverFinishingNearby.value) {
        isDriverFinishingNearby.value = false;
      }
    }
    if (_isDriverArrivedAtPickupStatus(normalizedStatus)) {
      _syncDriverArrivedPickupMessages();
    }
    final isCompletedStatus =
        normalizedStatus == 'completed' || normalizedStatus == 'ride_completed';
    if (isCompletedStatus) {
      _openCompletedRideDetailsScreen();
    }
  }

  /// Driver name for localized ride-status copy; falls back to generic "Driver".
  String get localizedDriverNameForCopy {
    final name = driverName.value.trim();
    return name.isNotEmpty ? name : AppStrings.driver.tr;
  }

  /// Pickup sheet + map chip copy when the driver is at pickup ([driver_arrived]).
  void _syncDriverArrivedPickupMessages() {
    isDriverFinishingNearby.value = false;
    assignedDriverSpeed.value = 0;
    arrivalLabel.value = AppStrings.driverArrivedPickupPrimary.tr;
    etaLabel.value = AppStrings.driverArrivedMapBadge.tr;
  }

  /// Second line on the driver-assigned pickup sheet (below the ETA row).
  ///
  /// Pickup progression: assigned → arriving → arrived (see [RidePickupStatusLabels]).
  String get driverPickupPhaseHeadline {
    switch (currentRideStatus.value) {
      case 'driver_arrived':
        return AppStrings.yourDriverHasArrived.tr;
      case 'driver_arriving':
        return AppStrings.driverHeadingTowardsYou.tr;
      case 'driver_assigned':
      case 'accepted':
        return AppStrings.driverHasAcceptedYourRide.tr;
      default:
        return AppStrings.driverIsHeadingToYourLocation.tr;
    }
  }

  /// Opens post-completion Ride Details once. Trusts realtime status over lagging HTTP.
  void _openCompletedRideDetailsScreen() {
    if (_openedCompletedRideDetails) return;
    if (_completionHandoffInProgress) {
      return;
    }
    final normalizedCurrentStatus = currentRideStatus.value
        .trim()
        .toLowerCase();
    if (normalizedCurrentStatus != 'completed' &&
        normalizedCurrentStatus != 'ride_completed') {
      return;
    }
    if (rideId.isEmpty) return;

    _completionHandoffInProgress = true;
    unawaited(
      _presentCompletedRideDetailsScreen().whenComplete(() {
        _completionHandoffInProgress = false;
      }),
    );
  }

  /// Fetches fresh details for the completed-ride screen.
  Future<void> _presentCompletedRideDetailsScreen() async {
    if (_openedCompletedRideDetails) return;
    if (rideId.isEmpty) return;

    final result = await rideRepository.getRideDetails(rideId);
    if (_openedCompletedRideDetails || _navigatedAway) return;

    final details = result.fold((_) => null, (r) => r);
    if (details == null) {
      AppDialogs.showErrorDialog(
        message: AppStrings.failedToLoadRideDetails.tr,
      );
      return;
    }

    // Normalize for details screen: force completed status and review UI.
    details.status = 'ride_completed';
    details.showReviewUi = true;

    _openedCompletedRideDetails = true;
    if (Get.isRegistered<RideDetailsController>()) {
      Get.delete<RideDetailsController>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.off(
        () => RideDetailsScreen(
          ride: details,
          openedFromCompletionFlow: true,
          refreshOnInit: false,
        ),
        binding: BindingsBuilder(() {
          Get.put(
            RideDetailsController(
              ride: details,
              openedFromCompletionFlow: true,
              refreshOnInit: false,
            ),
          );
        }),
      );
    });
  }

  void _applyRouteFallbackForStatus(String rawStatus) {
    if (!_hasReceivedTrackingUpdate) return;
    // Only apply fallback if we don't already have points.
    if (routePoints.isNotEmpty) return;

    final status = rawStatus.trim();
    final canonicalStatus = status
        .replaceAll('ridestatus.', '')
        .replaceAll('RideStatus.', '')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)}_${m.group(2)}',
        )
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    final normalizedStatus = canonicalStatus.toLowerCase();
    if (status.isEmpty) return;

    const pickupStatuses = {'accepted', 'driver_assigned', 'driver_arriving'};
    const dropStatuses = {
      'driver_arrived',
      'ride_started',
      'ride_in_progress',
      'near_destination',
      'ride_completed',
      'completed',
    };

    if (pickupStatuses.contains(normalizedStatus)) {
      _setPickupRouteFallback();
      return;
    }

    if (dropStatuses.contains(normalizedStatus)) {
      _setDropRouteFallback();
    }
  }

  /// In-trip sheet headline. Pickup-phase titles use [RidePickupStatusLabels] in `default`.
  String get rideProgressTitle {
    switch (currentRideStatus.value) {
      case 'ride_completed':
      case 'completed':
        return AppStrings.youHaveArrived.tr;
      case 'near_destination':
        return AppStrings.youAreAlmostThere.tr;
      case 'ride_in_progress':
        return AppStrings.onYourWayWithDriver.trParams({
          'driverName': localizedDriverNameForCopy,
        });
      case 'ride_started':
        return AppStrings.driverStartedYourRide.trParams({
          'driverName': localizedDriverNameForCopy,
        });
      default:
        return RidePickupStatusLabels.titleFor(currentRideStatus.value);
    }
  }

  /// In-trip / pickup supporting line (ETA-aware where applicable).
  String get rideProgressSubtitle {
    final etaSeconds = currentEtaSeconds.value;
    final etaMinutes = etaSeconds > 0 ? (etaSeconds / 60).ceil() : 0;
    final hasEta = etaMinutes > 0;
    switch (currentRideStatus.value) {
      case 'near_destination':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.approachingYourDestination.tr;
      case 'ride_in_progress':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.headingToYourDestination.tr;
      case 'ride_started':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.tripHasStarted.tr;
      case 'driver_arrived':
        return AppStrings.driverArrivedPickupPrimary.tr;
      case 'driver_arriving':
        return AppStrings.driverHeadingTowardsYou.tr;
      case 'driver_assigned':
        return AppStrings.driverAssignedDescription.tr;
      case 'ride_completed':
      case 'completed':
        return arrivalDateLabel;
      default:
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.tripHasStarted.tr;
    }
  }

  int get rideEtaMinutes {
    final etaSeconds = currentEtaSeconds.value;
    if (etaSeconds <= 0) return 0;
    return (etaSeconds / 60).ceil();
  }

  /// Pickup-phase statuses: map chip + driver-assigned sheet use same rule.
  bool _isDriverHeadingToPickupForEta(String rideStatusRaw) {
    final s = normalizeRideStatusString(rideStatusRaw);
    if (s.isEmpty || s == 'driver_arrived') return false;
    return s == 'driver_assigned' ||
        s == 'driver_arriving' ||
        s == 'accepted' ||
        s == 'driver_en_route' ||
        s == 'en_route';
  }

  void _applySocketEtaSecondsToLabels(
    double etaSeconds, {
    required bool skipIfArrived,
  }) {
    if (skipIfArrived &&
        normalizeRideStatusString(currentRideStatus.value) ==
            'driver_arrived') {
      return;
    }
    if (etaSeconds <= 0) return;
    currentEtaSeconds.value = etaSeconds;
    final minutes = (etaSeconds / 60).ceil();
    // Keep ETA in state, but do not show the minutes chip while finishing nearby.
    if (!isDriverFinishingNearby.value) {
      etaLabel.value = AppStrings.minutesShortCount.trParams({
        'count': '$minutes',
      });
    }
    final rideStatus = normalizeRideStatusString(currentRideStatus.value);
    if (_isDriverHeadingToPickupForEta(rideStatus) &&
        !isDriverFinishingNearby.value) {
      arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
    }
  }

  /// Driver-assigned sheet first line — matches map chip math on [currentEtaSeconds].
  String get driverAssignedSheetArrivalEtaLine {
    final st = normalizeRideStatusString(currentRideStatus.value);
    if (st == 'driver_arrived') {
      return arrivalLabel.value;
    }
    if (isDriverFinishingNearby.value && _isDriverHeadingToPickupForEta(st)) {
      return AppStrings.driverFinishingNearbyTrip.tr;
    }
    final secs = currentEtaSeconds.value;
    if (secs > 0 && _isDriverHeadingToPickupForEta(st)) {
      final minutes = (secs / 60).ceil();
      return AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
    }
    return arrivalLabel.value;
  }

  /// Map ETA chip — hidden while the chained driver is finishing another trip.
  bool get shouldShowMapEtaChip {
    if (hasRideLoadError) return false;
    if (isDriverFinishingNearby.value) return false;
    final st = normalizeRideStatusString(currentRideStatus.value);
    if (st == 'driver_arrived') return true;
    return currentEtaSeconds.value > 0 || etaLabel.value.trim().isNotEmpty;
  }

  bool get shouldShowRideEtaBadge {
    final status = currentRideStatus.value;
    if (rideEtaMinutes <= 0) return false;
    return status == 'ride_started' ||
        status == 'ride_in_progress' ||
        status == 'near_destination';
  }

  void _setDriverFinishingNearby(bool finishing) {
    final wasFinishing = isDriverFinishingNearby.value;
    isDriverFinishingNearby.value = finishing;
    if (finishing) {
      // Replaces "Driver will arrive in X min..." while the prior trip is active.
      arrivalLabel.value = AppStrings.driverFinishingNearbyTrip.tr;
      _lastDriverRotationSamplePosition = null;
      _syncDriverHeadingFromActiveRoute(animate: true);
      return;
    }
    if (!wasFinishing) return;
    _lastDriverRotationSamplePosition = null;
    _restorePickupArrivalLabelsAfterFinishingNearby();
  }

  /// When chaining ends (`driver_finishing_nearby` → false), always drop the
  /// finishing-trip copy. Prefer cached ETA minutes; otherwise show arriving.
  void _restorePickupArrivalLabelsAfterFinishingNearby() {
    final st = normalizeRideStatusString(currentRideStatus.value);
    if (!_isDriverHeadingToPickupForEta(st)) return;

    final secs = currentEtaSeconds.value;
    if (secs > 0) {
      final minutes = (secs / 60).ceil();
      etaLabel.value = AppStrings.minutesShortCount.trParams({
        'count': '$minutes',
      });
      arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
      return;
    }

    // No ETA cached yet — clear finishing text so the old arrival line can show.
    etaLabel.value = AppStrings.arriving.tr;
    arrivalLabel.value = AppStrings.driverIsArriving.tr;
  }

  /// During chained pickup, GPS movement can point away from the drawn route.
  /// Prefer the active polyline bearing so the marker faces the route line.
  double _resolveAssignedDriverHeading({
    required LatLng currentPosition,
    LatLng? previousPosition,
    double? headingDegrees,
    required double previousRotation,
    double speedMps = 0,
  }) {
    if (isDriverFinishingNearby.value && routePoints.length >= 2) {
      final routeBearing = TrackingRouteGeometryUtils.bearingAlongRouteAt(
        routePoints,
        currentPosition,
      );
      if (routeBearing != null) {
        return routeBearing;
      }
    }

    return MapVehicleMarkerUtils.resolveMarkerRotation(
      previousPosition: previousPosition,
      currentPosition: currentPosition,
      headingDegrees: headingDegrees,
      previousRotation: previousRotation,
      speedMps: speedMps,
    );
  }

  void _syncDriverHeadingFromActiveRoute({bool animate = false}) {
    if (!isDriverFinishingNearby.value || routePoints.length < 2) return;

    final driverPos =
        assignedDriverLocation.value ??
        mapWidgetKey.currentState?.currentAnimatedPosition;
    if (driverPos == null) return;

    final routeBearing = TrackingRouteGeometryUtils.bearingAlongRouteAt(
      routePoints,
      driverPos,
    );
    if (routeBearing == null) return;

    assignedDriverHeading.value = routeBearing;
    if (animate) {
      mapWidgetKey.currentState?.updateRiderPosition(
        driverPos,
        rotation: routeBearing,
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    _setDriverFinishingNearby(payload.driverFinishingNearby);

    final trackingStatus = (payload.status ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final normalizedTracking = normalizeRideStatusString(trackingStatus);

    // Chain break can also arrive on tracking before/without a status event.
    if (normalizedTracking == 'searching') {
      if (_navigatedAway) return;
      if (rideBottomSheetState.value == RideBottomSheetState.rideStarted) {
        return;
      }
      _navigateBackToFindingDriverAfterChainBroken();
      return;
    }

    if (trackingStatus.isNotEmpty) {
      // Only trigger state updates from tracking payloads if it's a major transition.
      // High-frequency tracking often contains stale 'assigned' statuses.
      if (trackingStatus.contains('started') ||
          trackingStatus.contains('progress') ||
          trackingStatus.contains('complete') ||
          trackingStatus.contains('arrived')) {
        _applyBottomSheetStateForStatus(trackingStatus);
      }
    }

    if (trackingStatus == 'cancelled') {
      if (_isUserInitiatedCancellation || _navigatedAway) return;
      unawaited(_handleRideCancelledFromTracking());
      return;
    }
    if (trackingStatus == 'no_driver_found' ||
        trackingStatus == 'no_drivers_found') {
      if (_navigatedAway) return;
      _navigatedAway = true;
      _showCancelDialogThenGoHome(
        AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr,
      );
      return;
    }

    final isPickupArrived = _isDriverArrivedAtPickupStatus(trackingStatus);
    if (isPickupArrived) {
      _setDriverFinishingNearby(false);
      _syncDriverArrivedPickupMessages();
    }

    final eta = payload.eta;
    if (eta != null) {
      final etaSecs = eta.toDouble();
      if (!isPickupArrived && etaSecs > 0) {
        _applySocketEtaSecondsToLabels(etaSecs, skipIfArrived: false);
      } else if (!isPickupArrived && etaSecs <= 0) {
        final statusForEta = (payload.status ?? currentRideStatus.value)
            .toLowerCase();
        final inRide =
            statusForEta.contains('progress') ||
            statusForEta.contains('started');
        if (!isDriverFinishingNearby.value) {
          etaLabel.value = inRide
              ? AppStrings.nearby.tr
              : AppStrings.arriving.tr;
          arrivalLabel.value = inRide
              ? AppStrings.youAreAlmostThere.tr
              : AppStrings.driverIsArriving.tr;
        }
      }
    }

    var target = _normalizeRouteTarget(payload.routeTarget);
    final coords = payload.routeGeometry?.coordinates;

    // If target is missing, infer it from the status
    if (target.isEmpty) {
      final status = (payload.status ?? '').toLowerCase();
      if (status.contains('progress') || status.contains('started')) {
        target = 'drop_off';
      } else if (status.contains('assigned') || status.contains('arriving')) {
        target = 'pick_up';
      }
    }

    _applyRouteGeometryFromPayload(
      routeTarget: target,
      coordinates: coords,
      fitCameraOnChange: true,
    );

    // Hybrid: refresh Live Activity ETA/location from tracking (1.5s throttle
    // in LiveActivityManager). APNs can still deliver the same updates later.
    unawaited(_syncLiveActivityFromTrackingPayload(payload));
  }

  /// Applies `route_geometry` from tracking/status payloads without re-fitting on duplicates.
  void _applyRouteGeometryFromPayload({
    required String routeTarget,
    required List<List<double>>? coordinates,
    required bool fitCameraOnChange,
  }) {
    if (routeTarget != 'pick_up' && routeTarget != 'drop_off') return;

    this.routeTarget.value = routeTarget;
    if (!_hasReceivedTrackingUpdate) return;

    final kind = TrackingRouteGeometryUtils.classify(coordinates);
    switch (kind) {
      case TrackingRouteGeometryKind.empty:
        // Wait for the next tracking payload with path geometry — never draw
        // a straight pickup→destination fallback line.
        if (routePoints.isEmpty) {
          _markInitialRouteReady();
        }
        return;
      case TrackingRouteGeometryKind.repeatedLocation:
      case TrackingRouteGeometryKind.path:
        final nextPoints = TrackingRouteGeometryUtils.pointsForMap(coordinates);
        _markInitialRouteReady();
        if (TrackingRouteGeometryUtils.routesEquivalent(
          routePoints,
          nextPoints,
        )) {
          return;
        }
        routePoints.assignAll(nextPoints);
        if (fitCameraOnChange &&
            kind == TrackingRouteGeometryKind.path &&
            nextPoints.length >= 2) {
          _fitRouteBounds();
        }
        _syncDriverHeadingFromActiveRoute(animate: true);
        return;
    }
  }

  /// Calculates the distance between two points in meters using Haversine formula.
  double _calculateDistanceInMeters(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final double dLng = _degreesToRadians(p2.longitude - p1.longitude);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(p1.latitude)) *
            math.cos(_degreesToRadians(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  String _normalizeRouteTarget(String? target) {
    final t = (target ?? '').trim().toLowerCase();
    if (t == 'pickup' || t == 'pick_up') return 'pick_up';
    if (t == 'dropoff' || t == 'drop_off' || t == 'destination') {
      return 'drop_off';
    }
    return '';
  }

  /// Places an in-app voice call to the assigned driver using the Agora
  /// calling package. Falls back to the system phone dialer when the package
  /// flow isn't available (no Agora App ID, ride id missing, etc.).
  Future<void> callDriver() async {
    final id = rideId;
    if (id.isEmpty) {
      return;
    }
    RideDriverCallOptionsSheet.show(
      rideId: id,
      peerDisplayName: driverName.value,
      driverPhone: driverPhone.value,
      peerAvatarUrl: driverAvatarUrl.value.trim().isEmpty
          ? null
          : driverAvatarUrl.value,
    );
  }

  /// Opens the OS phone app with [phone] (`tel:`). [errorDialogTitle] uses API `label` for emergency rows.
  Future<void> _launchSystemPhoneDialer({
    required String phone,
    required String errorDialogTitle,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: errorDialogTitle,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.e(
        'Error launching dialer',
        tag: 'DriverAcceptedController',
        error: e,
      );
      AppDialogs.showErrorDialog(
        title: errorDialogTitle,
        message: AppStrings.errorOpeningPhoneDialer.tr,
      );
    }
  }

  void onChatTap() {
    unreadCount.value = 0;
    Get.toNamed(
      AppRoutes.rideMessage,
      arguments: {
        'rideId': rideId,
        'driverName': driverName.value,
        'driverPhone': driverPhone.value,
        'driverSubtitle': plateDisplayFormatted.value,
        'riderName': 'Rider', // Default placeholder
        'initialStatus': _mapBottomSheetToRideStatus(
          rideBottomSheetState.value,
        ).name,
      },
    );
  }

  RideStatus _mapBottomSheetToRideStatus(RideBottomSheetState state) {
    switch (state) {
      case RideBottomSheetState.driverAssigned:
        return RideStatus.driverAssigned;
      case RideBottomSheetState.rideStarted:
        return RideStatus.rideStarted;
    }
  }

  static const String mapRouteHeaderId = 'map_route_header';

  String get mapRoutePickupLabel {
    if (pickupAddress.trim().isEmpty) {
      return AppStrings.currentLocation.tr;
    }
    final line = compactAddressLine(pickupAddress);
    return line.isEmpty ? AppStrings.currentLocation.tr : line;
  }

  String get mapRouteDestinationLabel {
    if (destinationAddress.trim().isEmpty) {
      return AppStrings.destination.tr;
    }
    final line = compactAddressLine(destinationAddress);
    return line.isEmpty ? AppStrings.destination.tr : line;
  }

  void _refreshMapRouteHeader() => update([mapRouteHeaderId]);

  String get pickupTitle => _firstAddressLine(pickupAddress);

  String get destinationTitle => _firstAddressLine(destinationAddress);

  String get rideVehicleLabel {
    final value = driverVehicleLine.value.trim();
    if (value.isNotEmpty) return value.split('-').first.trim();
    return AppStrings.boda.tr;
  }

  String get arrivalDateLabel {
    final value = ride.value;
    if (value == null) return '05th Mar 2026 . 08:08PM';
    return DateFormat('dd\'th\' MMM yyyy . hh:mma').format(value.createdAt);
  }

  String get rideChargeLabel {
    final amount =
        ride.value?.fareBreakdown?.rideCharge ??
        _seedRideCharge ??
        ride.value?.fareEstimate ??
        100;
    return CurrencyFormatter.format(amount);
  }

  String get bookingFeeLabel {
    final amount =
        ride.value?.fareBreakdown?.bookingFee ?? _seedBookingFee ?? 0;
    return CurrencyFormatter.format(amount);
  }

  /// Itemized fare lines: Base → Distance → Time → Stops → min-fare top-up.
  /// Prefer over legacy Ride Charge + Booking Fee when [useItemizedFareBreakdown].
  List<FareBreakdownDisplayRow> get itemizedFareRows {
    final breakdown = ride.value?.fareBreakdown;
    return FareBreakdownDisplay.itemizedComponentRows(
      baseFare: breakdown?.baseFare ?? 0,
      distanceCharge: breakdown?.distanceCharge ?? 0,
      timeCharge: breakdown?.timeCharge ?? 0,
      stopCharges: breakdown?.stopCharges ?? const [],
      minimumFareAdjustment: breakdown?.minimumFareAdjustment ?? 0,
    );
  }

  /// True when API sent component fields (not just seed ride_charge/total).
  bool get useItemizedFareBreakdown {
    final breakdown = ride.value?.fareBreakdown;
    if (breakdown == null) return false;
    return FareBreakdownDisplay.hasItemizedComponents(
      baseFare: breakdown.baseFare ?? 0,
      distanceCharge: breakdown.distanceCharge ?? 0,
      timeCharge: breakdown.timeCharge ?? 0,
      stopCharges: breakdown.stopCharges ?? const [],
      minimumFareAdjustment: breakdown.minimumFareAdjustment ?? 0,
    );
  }

  String get totalAmountLabel {
    final breakdown = ride.value?.fareBreakdown;
    final amountCharged = breakdown?.amountCharged;
    final amount =
        (amountCharged != null && amountCharged > 0)
            ? amountCharged
            : (breakdown?.totalAmount ??
                _seedTotalAmount ??
                ride.value?.finalFare ??
                ride.value?.fareEstimate ??
                100);
    return CurrencyFormatter.format(amount);
  }

  String get _promoCodeForDisplay {
    final r = ride.value;
    if (r == null) return '';
    final code =
        (r.promoCode ?? r.fareBreakdown?.promoCode)?.toString().trim() ?? '';
    if (code.isEmpty || code == 'null') return '';
    return code;
  }

  int get _promoDiscountAmount {
    final r = ride.value;
    if (r == null) return 0;
    return r.promoDiscount ?? r.fareBreakdown?.promoDiscount ?? 0;
  }

  int get _promoCashbackAmount {
    final r = ride.value;
    if (r == null) return 0;
    return r.cashbackAmount ?? r.fareBreakdown?.cashbackAmount ?? 0;
  }

  bool get _promoIsCashback {
    final breakdown = ride.value?.fareBreakdown;
    if (breakdown?.isCashback == true && _promoCashbackAmount > 0) {
      return true;
    }
    return _promoCashbackAmount > 0 && _promoDiscountAmount <= 0;
  }

  bool get showPromoFareLine {
    if (_promoCodeForDisplay.isEmpty) return false;
    return _promoIsCashback || _promoDiscountAmount > 0;
  }

  String get promoFareLineTitle {
    final code = _promoCodeForDisplay;
    if (_promoIsCashback) {
      return AppStrings.receiptCashbackPromoLine.trParams({'code': code});
    }
    final autoApplied =
        ride.value?.promoAutoApplied == true ||
        ride.value?.fareBreakdown?.promoAutoApplied == true;
    if (autoApplied) {
      return AppStrings.receiptAutoPromoLine.trParams({'code': code});
    }
    return AppStrings.receiptPromoLine.trParams({'code': code});
  }

  String get promoFareLineAmountLabel {
    if (_promoIsCashback) {
      final formatted = CurrencyFormatter.format(_promoCashbackAmount);
      return AppStrings.promoCashbackAmount.trParams({'amount': formatted});
    }
    return '-${CurrencyFormatter.format(_promoDiscountAmount)}';
  }

  String get paymentModeLabel {
    final method = ride.value?.paymentMethod.name ?? 'wallet';
    switch (method) {
      case 'mobileMoney':
        return AppStrings.mobileMoney.tr;
      case 'selcomPesa':
        return AppStrings.selcomPesa.tr;
      case 'card':
        return AppStrings.card.tr;
      default:
        return AppStrings.wallet.tr;
    }
  }

  String _firstAddressLine(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return AppStrings.unknownLocation.tr;
    return trimmed.split(',').first.trim();
  }

  Future<void> confirmCancelRide() {
    // Driver-details bottom sheet — shared [CancelRideFlow] (canonical implementation).
    return CancelRideFlow(
      rideRepository: rideRepository,
      rideId: rideId,
      cancelInfo: cancelInfo.value,
      onCancelApiStarted: () {
        _isUserInitiatedCancellation = true;
        _navigatedAway = true;
      },
      onCancelApiFailed: () {
        _isUserInitiatedCancellation = false;
        _navigatedAway = false;
      },
      onRideAlreadyFinalized: () {
        // Race with server no-show finalize — stay on screen and await socket.
        _isUserInitiatedCancellation = false;
        _navigatedAway = false;
        isNoShowExpiring.value = true;
        unawaited(_fetchRideDetails());
      },
    ).run();
  }

  Future<void> _syncLiveActivityFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
  ) async {
    try {
      final status = (payload.status ?? '').toString().trim().toUpperCase();
      if (status.isEmpty) return;

      // Terminal: tear down Lock Screen / Dynamic Island immediately.
      if (status.contains('CANCELLED') || status.contains('NO_DRIVER_FOUND')) {
        await LiveActivityManager().endActivity(rideId);
        return;
      }

      // Hybrid Live Activity updates (iOS):
      // - Local ActivityKit update here so the widget tracks app status without
      //   waiting for backend → APNs latency.
      // - APNs push-token updates remain for when the app is backgrounded/killed.
      // startActivity(..., updateIfExists: true) creates or updates ContentState.
      final r = ride.value;
      final driver = payload.driverSnapshot;
      final vehicle = payload.vehicleSnapshot;
      final plateFromPayload =
          (driver?.vehicleRegistrationNumber ?? '').trim();
      final rawPlate = plateFromPayload.isNotEmpty
          ? plateFromPayload
          : (r != null ? _rawPlateStringFromRide(r) : '');
      final driverName =
          (driver?.name ?? r?.driverSnapshot?.name ?? '').trim();
      final vehicleName =
          '${vehicle?.displayName ?? vehicle?.vehicleName ?? vehicle?.vehicleType ?? r?.vehicleSnapshot?.vehicleType ?? ''} ${driver?.vehicleModel ?? r?.vehicleSnapshot?.vehicleModel ?? ''}'
              .trim();
      final avatarUrl =
          (driver?.avatarUrl ?? r?.driverSnapshot?.avatarUrl ?? '').trim();
      final etaFromPayload = (payload.etaSeconds ?? 0).toDouble();
      final etaSeconds = etaFromPayload > 0
          ? etaFromPayload
          : currentEtaSeconds.value;

      await LiveActivityManager().startActivity(
        orderId: rideId,
        status: status,
        driverName: driverName.isNotEmpty ? driverName : 'Driver Assigned',
        vehicleName: vehicleName,
        driverAvatarUrl: avatarUrl,
        plateNumber: TanzaniaLicensePlateFormatter.formatDisplay(rawPlate),
        isCompleted: status.contains('COMPLETED'),
        etaSeconds: etaSeconds,
        driverLatitude:
            driver?.lat ?? assignedDriverLocation.value?.latitude,
        driverLongitude:
            driver?.lng ?? assignedDriverLocation.value?.longitude,
        updateIfExists: true,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d(
        "❌ Error in DriverAcceptedController._syncLiveActivityFromStatusPayload: $e",
        tag: 'ORDER_TRACKING',
      );
    }
  }

  /// Pushes ETA/location into Live Activity from tracking sockets (throttled).
  /// Keeps the widget ETA closer to the in-app chip without relying only on APNs.
  Future<void> _syncLiveActivityFromTrackingPayload(
    TrackingUpdateSocketResponse payload,
  ) async {
    try {
      if (!LiveActivityManager().isTracking(rideId)) return;

      final statusRaw =
          (payload.status ?? currentRideStatus.value).toString().trim();
      if (statusRaw.isEmpty) return;
      final status = statusRaw
          .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'),
            (m) => '${m.group(1)}_${m.group(2)}',
          )
          .toUpperCase()
          .replaceAll(' ', '_');

      final eta = (payload.eta ?? 0).toDouble();
      await LiveActivityManager().updateActivity(
        orderId: rideId,
        status: status,
        etaSeconds: eta > 0 ? eta : currentEtaSeconds.value,
        driverLatitude: assignedDriverLocation.value?.latitude,
        driverLongitude: assignedDriverLocation.value?.longitude,
        isCompleted: status.contains('COMPLETED'),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    }
  }

  /// Prefer vehicle snapshot plate; else driver snapshot registration (same sources as UI).
  String _rawPlateStringFromRide(RideModel r) {
    final snap = r.vehicleSnapshot;
    if (snap != null) {
      final p = snap.plateNumber.trim();
      if (p.isNotEmpty) return snap.plateNumber;
    }
    final d = r.driverSnapshot;
    if (d != null) {
      return (d.vehicleRegistrationNumber ?? '').trim();
    }
    return '';
  }

  Future<void> _syncLiveActivityFromDetails(RideModel r) async {
    try {
      if (rideId.isEmpty) return;

      // Create or refresh Live Activity from ride details (HTTP / bootstrap).
      // Uses updateIfExists so iOS ContentState stays aligned with the app.
      final statusStr = r.status.name
          .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'),
            (m) => '${m.group(1)}_${m.group(2)}',
          )
          .toUpperCase();

      final rawPlate = _rawPlateStringFromRide(r);

      await LiveActivityManager().startActivity(
        orderId: rideId,
        status: statusStr,
        driverName: r.driverSnapshot?.name ?? 'Driver Assigned',
        vehicleName:
            '${r.vehicleSnapshot?.vehicleType ?? ''} ${r.vehicleSnapshot?.vehicleModel ?? ''}'
                .trim(),
        driverAvatarUrl: r.driverSnapshot?.avatarUrl ?? '',
        plateNumber: TanzaniaLicensePlateFormatter.formatDisplay(rawPlate),
        isCompleted: r.status == RideStatus.rideCompleted,
        etaSeconds: currentEtaSeconds.value,
        driverLatitude: assignedDriverLocation.value?.latitude,
        driverLongitude: assignedDriverLocation.value?.longitude,
        updateIfExists: true,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.e(
        'Error syncing Live Activity from Details',
        tag: 'DriverAcceptedController',
        error: e,
      );
    }
  }

  bool isNearDestination() {
    return currentRideStatus.value.toLowerCase() == 'near_destination';
  }

  void onEditStops() {
    if (isUpdatingStops.value) {
      AppDialogs.showInfoDialog(
        title: AppStrings.updateInProgress.tr,
        message: AppStrings.aPreviousUpdateIsStillBeingProcessed.tr,
      );
      return;
    }
    stopUpdateIdempotencyKey.value = const Uuid().v4();
    Get.toNamed(AppRoutes.stopEditor, arguments: {'ride': ride.value});
  }

  Future<void> previewStopsUpdate(List<RideStopModel> stops) async {
    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await rideRepository.updateStops(
      rideId,
      stops: stopsJson,
      confirm: false,
      idempotencyKey: stopUpdateIdempotencyKey.value,
    );

    result.fold(
      (f) {
        if (_handleInsufficientWalletFailure(f)) return;
        _showStopUpdateError(f.message);
      },
      (res) {
        if (res is StopUpdatePreviewModel) {
          stopUpdatePreview.value = res;
          // Generate key if not present and save it
          if (stopUpdateIdempotencyKey.value.isEmpty) {
            stopUpdateIdempotencyKey.value = const Uuid().v4();
          }
          _saveIdempotencyKey(stopUpdateIdempotencyKey.value);
        }
      },
    );
  }

  Future<bool> applyStopsUpdate(List<RideStopModel> stops) async {
    final pending = ride.value?.pendingStopsUpdate;
    if (pending != null &&
        pending.status == 'pending_payment' &&
        pending.validationId != null) {
      _pendingStopPaymentValidationId = pending.validationId;
      _pendingStopPaymentDirection = pending.direction;
      return true;
    }

    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await rideRepository.updateStops(
      rideId,
      stops: stopsJson,
      confirm: true,
      idempotencyKey: stopUpdateIdempotencyKey.value,
    );

    return result.fold(
      (f) {
        _clearIdempotencyKey();
        stopUpdateProgressStep.value = 0;
        if (_handleInsufficientWalletFailure(f)) return false;
        _showStopUpdateError(f.message);
        return false;
      },
      (res) {
        if (res is StopUpdateAppliedModel) {
          stopUpdateApplied.value = res;
          stopUpdatePreview.value = null;
          _pendingStopAppliedAfterConfirm = res;
          return true;
        }
        return false;
      },
    );
  }

  /// Called after [StopEditorScreen] pops on add-stops confirm success.
  Future<void> onStopEditorClosedAfterConfirm() async {
    final resumeValidationId = _pendingStopPaymentValidationId;
    if (resumeValidationId != null) {
      final direction = _pendingStopPaymentDirection ?? '';
      _pendingStopPaymentValidationId = null;
      _pendingStopPaymentDirection = null;
      isUpdatingStops.value = true;
      stopUpdateProgressStep.value = 1;
      _clearRouteAwaitingTrackingUpdate();
      await _processPaymentHold(resumeValidationId, direction);
      return;
    }

    final applied = _pendingStopAppliedAfterConfirm;
    if (applied == null) return;
    _pendingStopAppliedAfterConfirm = null;
    await _finalizeStopsConfirm(applied);
  }

  Future<void> _finalizeStopsConfirm(StopUpdateAppliedModel applied) async {
    // Confirm sample has no validation_id; payment resume uses pendingStopsUpdate.
    if (applied.blockUpdateRequired == true) {
      isUpdatingStops.value = true;
      stopUpdateProgressStep.value = 1;
      _clearRouteAwaitingTrackingUpdate();
      await _fetchRideDetails();
      return;
    }

    // Instant success — mirror change-drop flow: refresh SCR-11, no progress sheet.
    _clearIdempotencyKey();
    stopUpdateProgressStep.value = 0;
    isUpdatingStops.value = false;
    _clearRouteAwaitingTrackingUpdate();
    await _ensureRideRealtimeAfterLocationUpdate();
    await _fetchRideDetails();
  }

  void _showStopUpdateError(String rawMessage) {
    _showLocationUpdateValidationError(rawMessage, clearStopPreview: true);
  }

  Future<void> _showInsufficientWalletDialog(
    InsufficientWalletBalanceDetails details,
  ) async {
    await AppDialogs.showInsufficientWalletBalanceDialog(
      details: details,
      onTopUp: _openWalletTopUp,
    );
  }

  void _openWalletTopUp() {
    unawaited(AddMoneyToWalletBottomSheet.show());
  }

  bool _handleInsufficientWalletFailure(Failure failure) {
    if (failure is InsufficientWalletBalanceFailure) {
      unawaited(_showInsufficientWalletDialog(failure.details));
      return true;
    }
    return false;
  }

  void _showDestinationUpdateError(String rawMessage) {
    _showLocationUpdateValidationError(
      rawMessage,
      clearDestinationPreview: true,
    );
  }

  void _showLocationUpdateValidationError(
    String rawMessage, {
    bool clearStopPreview = false,
    bool clearDestinationPreview = false,
  }) {
    if (clearStopPreview) stopUpdatePreview.value = null;
    if (clearDestinationPreview) destinationUpdatePreview.value = null;

    final parts = rawMessage.split('|');
    final hasErrorCode = parts.length > 1;
    final errorCode = hasErrorCode ? parts.first.trim() : '';
    final message = hasErrorCode
        ? parts.sublist(1).join('|').trim()
        : rawMessage.trim();

    AppDialogs.showErrorDialog(
      title: errorCode == 'VALID_PICKUP_DROP_TOO_CLOSE'
          ? AppStrings.validation.tr
          : AppStrings.error.tr,
      message: message.isNotEmpty
          ? message
          : AppStrings.somethingWentWrongPleaseTryAgain.tr,
    );
  }

  List<Map<String, dynamic>> _buildStopsPayloadForUpdate(
    List<RideStopModel> stops,
  ) {
    return stops
        .map(
          (stop) => {'lat': stop.lat, 'lng': stop.lng, 'address': stop.address},
        )
        .toList();
  }

  Future<void> _processPaymentHold(
    String validationId,
    String direction,
  ) async {
    if (direction == 'up') {
      stopUpdateProgressStep.value = 1; // Show payment step
      try {
        await _socketService.ensureConnected();
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      }
      _socketService.joinPaymentRoom(validationId: validationId);
      _joinRideRoomIfNeeded();
      if (AppConfig.ridePaymentBypass) {
        await rideRepository.walletDummyPaymentRequest(
          DummyPaymentRequest(
            result: 'SUCCESS',
            transId: 'TXN-${const Uuid().v4()}',
            validationId: validationId,
          ),
        );
      }
    } else if (direction == 'down') {
      stopUpdateProgressStep.value = 2; // Jump to route update (silent payment)
      unawaited(_ensureRideRealtimeAfterLocationUpdate());
    } else {
      stopUpdateProgressStep.value = 2; // Jump to route update (no payment)
      unawaited(_ensureRideRealtimeAfterLocationUpdate());
    }

    // The socket listeners will handle the rest of the flow
    _startStopUpdateTimeout();
  }

  void _startStopUpdateTimeout() {
    Future.delayed(const Duration(seconds: 90), () {
      if (isUpdatingStops.value) {
        isUpdatingStops.value = false;
        stopUpdateProgressStep.value = 0;
        AppDialogs.showInfoDialog(
          title: AppStrings.takingLongerThanExpected.tr,
          message:
              AppStrings.theUpdateIsTakingSomeTimePleaseCheckBackShortly.tr,
        );
        _fetchRideDetails();
      }
    });

    // Periodic poll fallback for socket events
    _pollForStopUpdateResult();
  }

  void _pollForStopUpdateResult() {
    Future.delayed(const Duration(seconds: 8), () {
      if (isUpdatingStops.value && stopUpdateProgressStep.value == 2) {
        _fetchRideDetails();
        _pollForStopUpdateResult();
      }
    });
  }

  Future<void> onChangeDropLocation() async {
    if (rideId.isEmpty) return;
    if (isUpdatingStops.value || isUpdatingDestination.value) {
      AppDialogs.showInfoDialog(
        title: AppStrings.updateInProgress.tr,
        message: AppStrings.aPreviousUpdateIsStillBeingProcessed.tr,
      );
      return;
    }
    if (isNearDestination()) return;
    if (ride.value?.pendingStopsUpdate != null) return;
    Get.toNamed(
      AppRoutes.changeDropLocationEditor,
      arguments: {'ride': ride.value, 'editorMode': 'destination'},
    );
  }

  // Opens stop-style picker and returns one destination (lat/lng/address).
  // This keeps destination selection UX consistent with add-stop selection.
  Future<Map<String, dynamic>?> pickNewDropLocation() async {
    final dynamic raw = await Get.toNamed(
      AppRoutes.selectSavedLocation,
      arguments: {
        'isSelectingStop': true,
        'isSelectingDestination': true,
        'label': AppStrings.changeDropLocation.tr,
      },
    );
    if (raw == null || raw is! Map) return null;
    final mapped = _extractDestinationFromLocationSelectionResult(
      Map<String, dynamic>.from(raw),
    );
    if (mapped == null) return null;
    return mapped;
  }

  Future<void> previewDropLocationUpdate(
    Map<String, dynamic> destination,
  ) async {
    destinationUpdatePreview.value = null;
    final dest = _buildDestinationPayload(destination);
    if (dest == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.error.tr,
        message: AppStrings.addressMissing.tr,
      );
      return;
    }
    // Step 1: preview update-destination (confirm=false).
    final previewRes = await rideRepository.previewUpdateDestination(
      rideId,
      dest,
    );
    previewRes.fold(
      (f) {
        if (_handleInsufficientWalletFailure(f)) return;
        _showDestinationUpdateError(f.message);
      },
      (preview) {
        destinationUpdatePreview.value = preview;
      },
    );
  }

  Future<bool> applyDropLocationUpdate(Map<String, dynamic> destination) async {
    final dest = _buildDestinationPayload(destination);
    if (dest == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.error.tr,
        message: AppStrings.addressMissing.tr,
      );
      return false;
    }
    // Step 2: apply update-destination (confirm=true).
    return _applyDestinationConfirm(dest);
  }

  Map<String, dynamic>? _buildDestinationPayload(Map<String, dynamic> result) {
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();
    final address = result['address']?.toString().trim() ?? '';
    if (lat == null || lng == null || address.isEmpty) return null;
    return <String, dynamic>{'lat': lat, 'lng': lng, 'address': address};
  }

  Map<String, dynamic>? _extractDestinationFromLocationSelectionResult(
    Map<String, dynamic> payload,
  ) {
    // Location selection edit mode returns:
    // { pickup, pickupLat, pickupLng, destinations: [{address, lat, lng}, ...] }
    // For this feature we only need the first destination.
    final destinations = payload['destinations'];
    if (destinations is List && destinations.isNotEmpty) {
      final first = destinations.first;
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        return {
          'lat': (map['lat'] as num?)?.toDouble(),
          'lng': (map['lng'] as num?)?.toDouble(),
          'address': map['address']?.toString().trim(),
        };
      }
    }

    // Backward compatibility if any picker returns direct lat/lng/address.
    return {
      'lat': (payload['lat'] as num?)?.toDouble(),
      'lng': (payload['lng'] as num?)?.toDouble(),
      'address': payload['address']?.toString().trim(),
    };
  }

  Future<bool> _applyDestinationConfirm(Map<String, dynamic> dest) async {
    final lat = (dest['lat'] as num).toDouble();
    final lng = (dest['lng'] as num).toDouble();
    _pendingDestinationTargetLat = lat;
    _pendingDestinationTargetLng = lng;

    isDestinationUpdateFlow.value = true;
    _clearRouteAwaitingTrackingUpdate();

    // Step 2: apply destination update (confirm=true).
    final result = await rideRepository.confirmUpdateDestination(rideId, dest);
    return result.fold(
      (f) {
        isDestinationUpdateFlow.value = false;
        stopUpdateProgressStep.value = 0;
        _pendingDestinationTargetLat = null;
        _pendingDestinationTargetLng = null;
        _pendingDestinationAppliedAfterConfirm = null;
        if (_handleInsufficientWalletFailure(f)) return false;
        _showDestinationUpdateError(f.message);
        return false;
      },
      (DestinationUpdateAppliedModel applied) {
        destinationUpdatePreview.value = null;
        // Finalize after the editor screen pops so progress UI shows on SCR-11.
        _pendingDestinationAppliedAfterConfirm = applied;
        return true;
      },
    );
  }

  /// Called after [StopEditorScreen] pops on confirm success.
  Future<void> onChangeDropLocationEditorClosedAfterConfirm() async {
    final applied = _pendingDestinationAppliedAfterConfirm;
    if (applied == null) return;
    _pendingDestinationAppliedAfterConfirm = null;
    await _finalizeDestinationConfirm(applied);
  }

  Future<void> _finalizeDestinationConfirm(
    DestinationUpdateAppliedModel _,
  ) async {
    // Confirm payload is fare/distance/duration only — refresh ride state.
    isDestinationUpdateFlow.value = false;
    await _ensureRideRealtimeAfterLocationUpdate();
    await _fetchRideDetails();
    stopUpdateProgressStep.value = 0;
    isUpdatingDestination.value = false;
  }

  String priceFormatter(int? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,###').format(amount);
  }
}
