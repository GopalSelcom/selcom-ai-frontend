import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../../../../core/data/models/responses/rides/ride_cancellation_request_response.dart';
import '../../../../core/data/models/ride_cancel_info_model.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/ride_no_show_info_model.dart';
import '../../../../core/data/models/ride_route_deviation_model.dart';
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
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/address_display_utils.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/book_any_fare_settled_ui.dart';
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
import '../utils/request_cancellation_flow.dart';
import '../widgets/ride_driver_call_options_sheet.dart';
import 'ride_details_controller.dart';

// ── Concern splits (same library via `part`; keep fields/lifecycle here) ──
// map ............ markers, camera, route geometry, speed/ETA overlay
// socket ......... ride-room realtime, status/tracking payloads
// cancel_safety .. cancel, no-show, route deviation, emergency
// status_labels .. sheet / progress / ETA copy from ride status
// stops_destination mid-ride stops + drop changes + wallet holds
// comms_live ..... call, chat, Live Activity sync
part 'parts/driver_accepted_controller_map.dart';
part 'parts/driver_accepted_controller_socket.dart';
part 'parts/driver_accepted_controller_cancel_safety.dart';
part 'parts/driver_accepted_controller_status_labels.dart';
part 'parts/driver_accepted_controller_stops_destination.dart';
part 'parts/driver_accepted_controller_comms_live.dart';

/// Bottom sheet layout for pickup phase vs ride-started phase.
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

/// SCR-11 — Driver accepted / ride in progress.
///
/// Owns shared state and lifecycle. Behavior is split into `parts/` extensions
/// so map, socket, cancel, labels, stops, and comms can change independently.
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

  /// Seeded from navigation args for rematch / finding-driver handoff.
  Map<String, dynamic>? _seedFareBreakdown;

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

  /// Cached `route_deviation` — null hides the deviation banner.
  final routeDeviationInfo = Rxn<RideRouteDeviationModel>();

  /// Rider dismissed the muted "back on route" / continue-to-trip banner.
  final routeDeviationBannerDismissed = false.obs;

  /// Standalone in-trip Request to cancel (separate from route-deviation cancel).
  final requestToCancelInfo = Rxn<RideCancellationRequestModel>();

  /// De-dupe key for socket `ride:route_deviation` (`ride_id` + `detected_at`).
  String? _lastRouteDeviationDedupeKey;

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

  StreamSubscription<RideRouteDeviationSocketPayload>? _routeDeviationSub;

  StreamSubscription<RideCancellationRequestUpdatePayload>?
  _cancellationRequestUpdateSub;

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
    if ((size - sheetSize.value).abs() < 0.0001) return;
    // DraggableScrollableSheet can notify during build (extent replace).
    // Defer Rx writes so Obx is not marked dirty mid-build.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      sheetSize.value = size;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if ((size - sheetSize.value).abs() < 0.0001) return;
      sheetSize.value = size;
    });
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
    _routeDeviationSub?.cancel();
    _cancellationRequestUpdateSub?.cancel();
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
      _seedFareBreakdown = Map<String, dynamic>.from(rawFareBreakdown);
    }
    routePoints.clear();
    routeTarget.value = 'pick_up';
    _hydrateSocketSeedPayloads(args);
    _refreshMapRouteHeader();
    _skipInitialRideDetailsFetch =
        skipInitialRideDetailsFetchFromNavigationArgs(args);
    _prefetchedRide = prefetchedRideFromNavigationArgs(args);
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
    _syncRouteDeviationFromRideModel(r);
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

  static const String mapRouteHeaderId = 'map_route_header';
}
