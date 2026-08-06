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
import '../utils/ride_draggable_sheet_mixin.dart';
import '../utils/ride_navigation_coords.dart';
import '../widgets/ride_driver_call_options_sheet.dart';
import 'ride_details_controller.dart';

// ── Concern splits (same library via `part`; helpers access private fields) ──
// mapHelper ............ markers, camera, route geometry, speed/ETA overlay
// socketHelper ......... ride-room realtime, status/tracking payloads
// cancelSafetyHelper .. cancel, no-show, route deviation, emergency
// statusLabelsHelper .. sheet / progress / ETA copy from ride status
// stopsDestinationHelper mid-ride stops + drop changes + wallet holds
// commsLiveHelper ..... call, chat, Live Activity sync
part 'parts/driver_accepted_controller_map.dart';
part 'parts/driver_accepted_controller_socket.dart';
part 'parts/driver_accepted_controller_cancel_safety.dart';
part 'parts/driver_accepted_controller_status_labels.dart';
part 'parts/driver_accepted_controller_stops_destination.dart';
part 'parts/driver_accepted_controller_comms_live.dart';

/// Bottom sheet layout for pickup phase vs ride-started phase.
enum RideBottomSheetState { driverAssigned, rideStarted }

/// Ride statuses where the map speed chip should stay hidden.
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
/// Owns shared state and lifecycle. Behavior is split into `parts/` helper
/// classes (same library) so map, socket, cancel, labels, stops, and comms
/// can change independently.
class DriverAcceptedController extends GetxController
    with
        GetSingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        RideDraggableSheetMixin {
  DriverAcceptedController({
    required this.rideRepository,
    required this.analyticsService,
  });

  @override
  double get initialSheetSize => 0.3;

  /// Ride HTTP API (details, cancel, stops, destination, emergency contacts).
  final RideRepository rideRepository;

  /// Product analytics (screen views and ride-flow events).
  final AnalyticsService analyticsService;

  /// From `/go/settings` → `features.max_stops` (excludes final destination).
  int get maxIntermediateStops =>
      di.sl<AppSettingsService>().maxIntermediateStops;

  /// Shared socket client for ride-room join/leave and realtime streams.
  final AppSocketService _socketService = AppSocketService();

  /// Active ride id from navigation args (required for details + sockets).
  late final String rideId;

  /// Pickup coordinates for map markers and proximity checks.
  late final LatLng pickupLatLng;

  /// Final drop coordinates (may update mid-ride).
  late LatLng destinationLatLng;

  /// Full pickup address string from nav args / ride details.
  late final String pickupAddress;

  /// Full destination address string (may update mid-ride).
  late String destinationAddress;

  /// Intermediate stop address lines shown in the trip summary (not final drop).
  final summaryIntermediateStops = <String>[].obs;

  /// Full route places from nav: intermediates + final destination (last item).
  final routeDestinations = <LocationEntity>[].obs;

  /// Seeded from navigation args for rematch / finding-driver handoff.
  Map<String, dynamic>? _seedFareBreakdown;

  /// Last known / animated assigned-driver position on the map.
  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();

  /// Decoded polyline points for the active leg (pickup or drop).
  final routePoints = <LatLng>[].obs;

  /// Active route leg target: `pick_up` or `drop` (drives fallbacks / headers).
  final routeTarget = 'pick_up'.obs;

  /// True while the initial (or retry) GET ride-details request is in flight.
  final isLoadingRide = false.obs;

  /// User-facing message when ride details cannot be loaded (missing rideId or API failure).
  /// Drives the error sheet on [DriverAcceptedScreen]; never show placeholder driver data.
  final rideLoadError = RxnString();

  /// Latest ride model from HTTP / prefetch (source of truth for sheet fields).
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

  /// Ticks [noShowCountdownLabel] until fire-at; null when banner inactive.
  PaymentCountdownTimer? _noShowCountdown;

  /// ISO fire-at already armed — avoids restarting the countdown on duplicate syncs.
  String? _armedNoShowFireAtIso;

  /// Assigned driver display name for sheet / call / chat.
  final driverName = ''.obs;

  /// Driver phone for dialer / call options.
  final driverPhone = ''.obs;

  /// Driver avatar URL (empty when unavailable).
  final driverAvatarUrl = ''.obs;

  /// Formatted rating string for the sheet (e.g. `4.8` or `—`).
  final driverRating = ''.obs;

  /// Combined vehicle + plate line shown under the driver name.
  final driverVehicleLine = ''.obs;

  /// Bottom-sheet vehicle illustration asset path.
  final bottomSheetVehicleImageAsset = AppAssets.imgCab.obs;

  /// Formatted for UI, e.g. `T 123 ABC` (see [TanzaniaLicensePlateFormatter]).
  final plateDisplayFormatted = ''.obs;

  /// Model / color subtitle under the plate line.
  final vehicleSubtitle = ''.obs;

  /// Up to 4 PIN digits shown when [isPinRequired] is true.
  final otpDigits = <String>[].obs;

  /// Whether the ride requires a PIN at pickup.
  final isPinRequired = true.obs;

  /// Short ETA label for map chip / sheet (e.g. minutes count).
  final etaLabel = AppStrings.minutesShortCount.trParams({'count': '10'}).obs;

  /// Latest ETA from socket/tracking in seconds (drives chip math).
  final currentEtaSeconds = 0.0.obs;

  /// Longer arrival copy for the pickup-phase sheet.
  final arrivalLabel = AppStrings.driverWillArrivingInMinutes.trParams({
    'minutes': '1',
  }).obs;

  /// Chained ride: driver is still finishing another nearby trip.
  /// Drives finishing-nearby sheet copy, hides the map ETA chip, and faces the
  /// driver marker along the drawn route until the flag clears.
  final isDriverFinishingNearby = false.obs;

  /// Unread in-ride chat messages (badge on chat action).
  final unreadCount = 0.obs;

  /// Which bottom-sheet layout is active: pickup vs ride-started.
  final rideBottomSheetState = RideBottomSheetState.driverAssigned.obs;

  /// Normalized ride status from socket/API — use [normalizeRideStatusString] when writing.
  final currentRideStatus = 'driver_assigned'.obs;

  /// Bitmap for the moving assigned-driver marker.
  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();

  /// Pickup pin icon.
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();

  /// Final drop pin icon.
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();

  /// Intermediate stop pin icons (letter markers when multi-stop).
  final stopIcons = <BitmapDescriptor>[].obs;

  /// Cached red A/B/C… letter icons for multi-stop route pins.
  final Map<String, BitmapDescriptor> _redRouteLetterIcons = {};

  /// Cached green letter icons (alternate style) for multi-stop pins.
  final Map<String, BitmapDescriptor> _greenRouteLetterIcons = {};

  /// True after letter icon bitmaps have been generated once.
  bool _routeLetterIconsLoaded = false;

  /// Bumps to cancel in-flight marker icon loads when a newer load starts.
  int _markerIconLoadToken = 0;

  /// Screen-space point for the driver ETA chip overlay (null when hidden).
  final Rxn<Offset> assignedDriverEtaScreenPx = Rxn<Offset>();

  /// Driver marker rotation in degrees.
  final assignedDriverHeading = 0.0.obs;

  /// Driver speed in m/s from tracking (map speed chip).
  final assignedDriverSpeed = 0.0.obs;

  /// Smoothed rider/driver position used for marker animation + ETA projection.
  final Rxn<LatLng> animatedRiderLocation = Rxn<LatLng>();

  /// True after the first usable route geometry has been applied (stops auto-recenter).
  final RxBool isInitialRouteLoaded = false.obs;

  /// Optional external hook when the GPS recenter control is pressed.
  VoidCallback? onRecenterPressed;

  /// Native Google Map controller from [AppGoogleMap.onMapCreated].
  GoogleMapController? mapController;

  /// Previous sample used to derive heading from movement when GPS bearing is weak.
  LatLng? _lastDriverRotationSamplePosition;

  /// True after leaving SCR-11 (cancel, rematch, completion) — blocks late UI updates.
  bool _navigatedAway = false;

  /// Suppresses cancel dialog when the user completed [CancelRideFlow] (socket may also fire `cancelled`).
  bool _isUserInitiatedCancellation = false;

  /// Throttles camera/bounds updates.
  DateTime? _lastCameraUpdate;

  /// Ensures completed-ride details open only once.
  bool _openedCompletedRideDetails = false;

  /// Guards completion handoff so socket + tracking cannot start parallel fetches.
  bool _completionHandoffInProgress = false;

  /// Coalesces concurrent getRideDetails calls (resume, handoff, stop-update poll).
  Future<void>? _rideDetailsFetchInFlight;

  /// True after at least one tracking payload arrived (enables route fallbacks).
  bool _hasReceivedTrackingUpdate = false;

  /// Socket connectivity stream.
  StreamSubscription<bool>? _connectionSub;

  /// `ride:status_update` subscription.
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;

  /// Stop-progress status subscription.
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStopSub;

  /// Driver location ticks subscription.
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;

  /// `ride:tracking_update` subscription.
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;

  /// In-ride chat message subscription.
  StreamSubscription<Map<String, dynamic>>? _chatSub;

  /// Stops-updated success subscription.
  StreamSubscription<RideStopsUpdatedResponse>? _rideStopsUpdatedSub;

  /// Stops-update failure subscription.
  StreamSubscription<RideStopsUpdateFailedResponse>? _rideStopsUpdateFailedSub;

  /// Payment / wallet hold status subscription.
  StreamSubscription<PaymentStatusUpdateResponse>? _paymentStatusSub;

  /// Fare settled (Book Any) subscription.
  StreamSubscription<RideFareSettledResponse>? _fareSettledSub;

  /// Mid-ride driver cancelled subscription.
  StreamSubscription<RideDriverCancelledPayload>? _driverCancelledSub;

  /// Route deviation subscription.
  StreamSubscription<RideRouteDeviationSocketPayload>? _routeDeviationSub;

  /// Cancellation-request status updates subscription.
  StreamSubscription<RideCancellationRequestUpdatePayload>?
  _cancellationRequestUpdateSub;

  /// When true, [onClose] skips leaving the ride room (e.g. mid-ride cancel handoff).
  bool _skipRideRoomLeaveOnClose = false;

  /// Set from nav args when My Rides / Home already pre-fetched this ride.
  bool _skipInitialRideDetailsFetch = false;

  /// True when pickup/destination coords were missing or invalid in nav args.
  bool _navArgsInvalid = false;

  /// Prefetched [RideModel] from navigation (used when skipping initial fetch).
  RideModel? _prefetchedRide;

  /// Guards re-entrant app-resume recovery.
  bool _isHandlingAppResume = false;

  /// Ensures emergency contacts load at most once per screen open.
  bool _emergencyContactsLoadedOnce = false;

  /// API-driven rows for the safety sheet (label = title, primary `phone` for `tel:`).
  final emergencyContacts = <EmergencyContactModel>[].obs;

  // ── Mid-ride stops / destination ──

  /// True while add-stops preview/confirm/payment/route recalculation is running.
  final isUpdatingStops = false.obs;

  /// Idempotency key for stop-update API + local persistence across resume.
  final stopUpdateIdempotencyKey = ''.obs;

  /// Last stops preview response (fare delta / geometry).
  final Rxn<StopUpdatePreviewModel> stopUpdatePreview =
      Rxn<StopUpdatePreviewModel>();

  /// Last applied stops confirm response (pending payment / success).
  final Rxn<StopUpdateAppliedModel> stopUpdateApplied =
      Rxn<StopUpdateAppliedModel>();

  /// Stop-update UI step: `0` idle, `1` payment, `2` route, `3` success.
  final stopUpdateProgressStep = 0.obs;

  /// Stops the rider selected in the editor (target list while confirming).
  final stopUpdateWorkingStops = <RideStopModel>[].obs;

  /// True while destination (drop) update confirm/route flow is running.
  final RxBool isUpdatingDestination = false.obs;

  /// True when the open stop-editor session is a drop-change (not add-stops).
  final RxBool isDestinationUpdateFlow = false.obs;

  /// Last destination preview response.
  final Rxn<DestinationUpdatePreviewModel> destinationUpdatePreview =
      Rxn<DestinationUpdatePreviewModel>();

  /// Applied destination payload waiting for editor pop / finalize.
  DestinationUpdateAppliedModel? _pendingDestinationAppliedAfterConfirm;

  /// Applied stops payload waiting for editor pop / payment / finalize.
  StopUpdateAppliedModel? _pendingStopAppliedAfterConfirm;

  /// Wallet validation id for stop-update payment hold.
  String? _pendingStopPaymentValidationId;

  /// Payment direction for the pending stop hold (`debit` / `credit`).
  String? _pendingStopPaymentDirection;

  /// Expected drop lat after destination confirm (poll success detection).
  double? _pendingDestinationTargetLat;

  /// Expected drop lng after destination confirm (poll success detection).
  double? _pendingDestinationTargetLng;

  /// Map markers, camera, route geometry, speed/ETA overlay.
  late final DriverAcceptedMapHelper mapHelper;

  /// Ride-room realtime: status, tracking, payment, rematch.
  late final DriverAcceptedSocketHelper socketHelper;

  /// Cancel, no-show, route deviation, emergency contacts.
  late final DriverAcceptedCancelSafetyHelper cancelSafetyHelper;

  /// Sheet / progress / ETA copy derived from ride status.
  late final DriverAcceptedStatusLabelsHelper statusLabelsHelper;

  /// Mid-ride stops + drop changes + wallet holds.
  late final DriverAcceptedStopsDestinationHelper stopsDestinationHelper;

  /// Call, chat, Live Activity sync.
  late final DriverAcceptedCommsLiveHelper commsLiveHelper;

  /// Builds concern helpers once before any bootstrap / socket work.
  void _initHelpers() {
    mapHelper = DriverAcceptedMapHelper(this);
    socketHelper = DriverAcceptedSocketHelper(this);
    cancelSafetyHelper = DriverAcceptedCancelSafetyHelper(this);
    statusLabelsHelper = DriverAcceptedStatusLabelsHelper(this);
    stopsDestinationHelper = DriverAcceptedStopsDestinationHelper(this);
    commsLiveHelper = DriverAcceptedCommsLiveHelper(this);
  }

  // ── Public API delegates (screens / widgets / stop editor) ──

  /// Formatted driver speed for the map chip (empty when hidden).
  String get formattedSpeedLabel => mapHelper.formattedSpeedLabel;

  /// Intermediate stops used for map letter pins.
  List<RideStopModel> get mapIntermediateStops =>
      mapHelper.mapIntermediateStops;

  /// Route letter (A/B/C…) for intermediate stop [sequentialIndex].
  String routeLetterForIntermediateIndex(int sequentialIndex) =>
      mapHelper.routeLetterForIntermediateIndex(sequentialIndex);

  /// Red letter pin bitmap for intermediate stop [sequentialIndex].
  BitmapDescriptor redRouteLetterIconForSequentialIndex(int sequentialIndex) =>
      mapHelper.redRouteLetterIconForSequentialIndex(sequentialIndex);

  /// True when multi-stop letter markers should be used instead of a single drop pin.
  bool get usesMultiStopRouteMarkers => mapHelper.usesMultiStopRouteMarkers;

  /// Loads / refreshes the vehicle-type driver marker icon.
  Future<void> loadDriverIcon({String? vehicleType}) =>
      mapHelper.loadDriverIcon(vehicleType: vehicleType);

  /// Called when [AppGoogleMap] is ready — stores controller and fits bounds.
  void onMapCreated(GoogleMapController ctrl) => mapHelper.onMapCreated(ctrl);

  /// Schedules a post-frame refresh of the driver ETA screen overlay.
  void scheduleAssignedEtaOverlayRefresh() =>
      mapHelper.scheduleAssignedEtaOverlayRefresh();

  /// Projects driver lat/lng to screen pixels for the ETA chip.
  Future<void> refreshAssignedDriverEtaOverlay() =>
      mapHelper.refreshAssignedDriverEtaOverlay();

  /// Recenter / fit camera to the active route (GPS button).
  void recenterMap() => mapHelper.recenterMap();

  /// One-line pickup label for the map route header.
  String get mapRoutePickupLabel => mapHelper.mapRoutePickupLabel;

  /// One-line drop label for the map route header.
  String get mapRouteDestinationLabel => mapHelper.mapRouteDestinationLabel;

  /// Short pickup title (first address line).
  String get pickupTitle => mapHelper.pickupTitle;

  /// Short destination title (first address line).
  String get destinationTitle => mapHelper.destinationTitle;

  /// Whether the map safety (shield) action should show.
  bool get shouldShowMapSafetyAction =>
      cancelSafetyHelper.shouldShowMapSafetyAction;

  /// Whether the rider cancel button is allowed for the current ride state.
  bool get shouldShowRiderCancelButton =>
      cancelSafetyHelper.shouldShowRiderCancelButton;

  /// Whether the pickup no-show wait banner is visible.
  bool get shouldShowNoShowBanner => cancelSafetyHelper.shouldShowNoShowBanner;

  /// Title copy for the no-show banner.
  String get noShowBannerTitle => cancelSafetyHelper.noShowBannerTitle;

  /// Subtitle copy for the no-show banner.
  String get noShowBannerSubtitle => cancelSafetyHelper.noShowBannerSubtitle;

  /// Whether the route-deviation banner should show.
  bool get shouldShowRouteDeviationBanner =>
      cancelSafetyHelper.shouldShowRouteDeviationBanner;

  /// True when the rider is currently marked off-route.
  bool get isRouteDeviationOffRoute =>
      cancelSafetyHelper.isRouteDeviationOffRoute;

  /// Whether the deviation banner may be dismissed by the rider.
  bool get canDismissRouteDeviationBanner =>
      cancelSafetyHelper.canDismissRouteDeviationBanner;

  /// Whether "Request to cancel" is offered from the deviation banner.
  bool get canRequestCancellationFromDeviation =>
      cancelSafetyHelper.canRequestCancellationFromDeviation;

  /// Deviation-scoped cancellation request is pending support review.
  bool get isDeviationCancellationPending =>
      cancelSafetyHelper.isDeviationCancellationPending;

  /// Deviation-scoped cancellation request was rejected.
  bool get isDeviationCancellationRejected =>
      cancelSafetyHelper.isDeviationCancellationRejected;

  /// Title for the route-deviation banner.
  String get routeDeviationBannerTitle =>
      cancelSafetyHelper.routeDeviationBannerTitle;

  /// Subtitle for the route-deviation banner.
  String get routeDeviationBannerSubtitle =>
      cancelSafetyHelper.routeDeviationBannerSubtitle;

  /// Human-readable off-route distance text.
  String get routeDeviationDistanceText =>
      cancelSafetyHelper.routeDeviationDistanceText;

  /// Support ticket number for deviation cancellation (when present).
  String get deviationCancellationTicketNumber =>
      cancelSafetyHelper.deviationCancellationTicketNumber;

  /// Note / status line for deviation cancellation.
  String get deviationCancellationNote =>
      cancelSafetyHelper.deviationCancellationNote;

  /// Whether the standalone Request-to-cancel banner should show.
  bool get shouldShowRequestToCancelBanner =>
      cancelSafetyHelper.shouldShowRequestToCancelBanner;

  /// Standalone cancel request is pending.
  bool get isRequestToCancelPending =>
      cancelSafetyHelper.isRequestToCancelPending;

  /// Standalone cancel request was rejected.
  bool get isRequestToCancelRejected =>
      cancelSafetyHelper.isRequestToCancelRejected;

  /// Ticket number for standalone Request to cancel.
  String get requestToCancelTicketNumber =>
      cancelSafetyHelper.requestToCancelTicketNumber;

  /// Note / status line for standalone Request to cancel.
  String get requestToCancelNote => cancelSafetyHelper.requestToCancelNote;

  /// True when the rider may retry after a rejected cancel request.
  bool get canRetryRequestToCancel =>
      cancelSafetyHelper.canRetryRequestToCancel;

  /// Loads emergency contacts once when the screen first opens.
  Future<void> loadEmergencyContactsOnceOnScreenOpen() =>
      cancelSafetyHelper.loadEmergencyContactsOnceOnScreenOpen();

  /// Icon for an emergency contact row by API id.
  IconData emergencyContactIconFor(String id) =>
      cancelSafetyHelper.emergencyContactIconFor(id);

  /// Opens the system dialer for an emergency contact.
  Future<void> dialEmergencyContact(EmergencyContactModel contact) =>
      cancelSafetyHelper.dialEmergencyContact(contact);

  /// Dismisses the route-deviation banner for this session.
  void dismissRouteDeviationBanner() =>
      cancelSafetyHelper.dismissRouteDeviationBanner();

  /// Off-route "Continue to trip" — dismiss banner only.
  void continueToTripFromDeviation() =>
      cancelSafetyHelper.continueToTripFromDeviation();

  /// Opens standalone Request-to-cancel sheet ([forceRetry] skips rejected gate).
  Future<void> openRequestToCancelSheet({bool forceRetry = false}) =>
      cancelSafetyHelper.openRequestToCancelSheet(forceRetry: forceRetry);

  /// Safety sheet entry — closes sheet then opens Request to cancel.
  Future<void> openRequestToCancelFromSafetySheet() =>
      cancelSafetyHelper.openRequestToCancelFromSafetySheet();

  /// Opens deviation-scoped Request to cancel.
  Future<void> openRequestCancellationSheet() =>
      cancelSafetyHelper.openRequestCancellationSheet();

  /// Withdraws a pending deviation cancellation request.
  Future<void> withdrawDeviationCancellationRequest() =>
      cancelSafetyHelper.withdrawDeviationCancellationRequest();

  /// Withdraws a pending standalone Request to cancel.
  Future<void> withdrawRequestToCancel() =>
      cancelSafetyHelper.withdrawRequestToCancel();

  /// Starts the rider cancel-ride confirmation flow.
  Future<void> confirmCancelRide() => cancelSafetyHelper.confirmCancelRide();

  /// Driver name for localized status copy (falls back to generic "Driver").
  String get localizedDriverNameForCopy =>
      statusLabelsHelper.localizedDriverNameForCopy;

  /// Pickup-phase headline under the ETA row (assigned / arriving / arrived).
  String get driverPickupPhaseHeadline =>
      statusLabelsHelper.driverPickupPhaseHeadline;

  /// In-trip (or pickup) progress title for the bottom sheet.
  String get rideProgressTitle => statusLabelsHelper.rideProgressTitle;

  /// Supporting progress line (ETA-aware where applicable).
  String get rideProgressSubtitle => statusLabelsHelper.rideProgressSubtitle;

  /// Whole minutes derived from [currentEtaSeconds].
  int get rideEtaMinutes => statusLabelsHelper.rideEtaMinutes;

  /// Driver-assigned sheet first ETA line (matches map chip math).
  String get driverAssignedSheetArrivalEtaLine =>
      statusLabelsHelper.driverAssignedSheetArrivalEtaLine;

  /// Whether the map ETA chip should be visible.
  bool get shouldShowMapEtaChip => statusLabelsHelper.shouldShowMapEtaChip;

  /// Whether the sheet ETA badge should be visible.
  bool get shouldShowRideEtaBadge => statusLabelsHelper.shouldShowRideEtaBadge;

  /// Vehicle label string for sheet copy.
  String get rideVehicleLabel => statusLabelsHelper.rideVehicleLabel;

  /// Formatted arrival / created date line when applicable.
  String get arrivalDateLabel => statusLabelsHelper.arrivalDateLabel;

  /// Fare breakdown rows for Total Fare UI.
  List<FareBreakdownDisplayRow> get fareLineRows =>
      statusLabelsHelper.fareLineRows;

  /// True when [fareLineRows] is non-empty.
  bool get hasFareLineItems => statusLabelsHelper.hasFareLineItems;

  /// True when status is near destination (hides add-stop / change-drop).
  bool isNearDestination() => statusLabelsHelper.isNearDestination();

  /// Formats a fare amount for display (thousands separators).
  String priceFormatter(int? amount) =>
      statusLabelsHelper.priceFormatter(amount);

  /// Opens the stop editor to add / edit intermediate stops.
  void onEditStops() => stopsDestinationHelper.onEditStops();

  /// Previews fare/route for a new stops list (wallet guard included).
  Future<void> previewStopsUpdate(List<RideStopModel> stops) =>
      stopsDestinationHelper.previewStopsUpdate(stops);

  /// Confirms stops update; returns false on failure / insufficient wallet.
  Future<bool> applyStopsUpdate(List<RideStopModel> stops) =>
      stopsDestinationHelper.applyStopsUpdate(stops);

  /// Continues stop-update after the editor pops on confirm success.
  Future<void> onStopEditorClosedAfterConfirm() =>
      stopsDestinationHelper.onStopEditorClosedAfterConfirm();

  /// Opens the change-drop flow (location picker → preview → confirm).
  Future<void> onChangeDropLocation() =>
      stopsDestinationHelper.onChangeDropLocation();

  /// Picks a new drop via location selection; returns raw map payload or null.
  Future<Map<String, dynamic>?> pickNewDropLocation() =>
      stopsDestinationHelper.pickNewDropLocation();

  /// Previews fare/route for a destination change.
  Future<void> previewDropLocationUpdate(Map<String, dynamic> destination) =>
      stopsDestinationHelper.previewDropLocationUpdate(destination);

  /// Confirms destination change; returns false on failure.
  Future<bool> applyDropLocationUpdate(Map<String, dynamic> destination) =>
      stopsDestinationHelper.applyDropLocationUpdate(destination);

  /// Continues drop-update after the editor pops on confirm success.
  Future<void> onChangeDropLocationEditorClosedAfterConfirm() =>
      stopsDestinationHelper.onChangeDropLocationEditorClosedAfterConfirm();

  /// Opens call options (in-app / dialer) for the assigned driver.
  Future<void> callDriver() => commsLiveHelper.callDriver();

  /// Opens in-ride chat and clears the unread badge.
  void onChatTap() => commsLiveHelper.onChatTap();

  /// Minimum sheet fraction for a ride status (single source of truth for UI).
  double sheetMinFractionForStatus(String status) {
    if (status == 'near_destination') {
      return 0.35;
    }
    if (status == 'ride_in_progress' || status == 'ride_started') {
      return 0.40;
    }
    return 0.3;
  }

  /// Collapses the draggable sheet to the status-based minimum.
  void minimizeSheet() {
    animateSheetTo(sheetMinFractionForStatus(currentRideStatus.value));
  }

  /// Animates the draggable sheet and [sheetSize] when status changes layout.
  void _syncSheetLayoutForCurrentStatus() {
    final target = sheetMinFractionForStatus(currentRideStatus.value);
    // Keep map chrome in sync before the draggable listener catches up.
    updateSheetSize(target);
    if (sheetController.isAttached) {
      if ((sheetController.size - target).abs() > 0.01) {
        animateSheetTo(target);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!sheetController.isAttached) return;
        updateSheetSize(sheetController.size);
      });
    }
  }

  /// True while the map is actively tracking / animating the driver marker.
  final RxBool isTrackingRider = false.obs;

  /// Key to [AppGoogleMapState] for projection helpers (ETA overlay).
  final GlobalKey<AppGoogleMapState> mapWidgetKey =
      GlobalKey<AppGoogleMapState>();

  @override
  void onInit() {
    super.onInit();
    _initHelpers();
    bindSheetSizeListener();
    WidgetsBinding.instance.addObserver(this);
    _parseArgs();
    _bootstrap();
    ever(animatedRiderLocation, (_) => scheduleAssignedEtaOverlayRefresh());
    ever(routePoints, (List<LatLng> points) {
      if (isInitialRouteLoaded.value) return;
      final kind = TrackingRouteGeometryUtils.classifyFromPoints(points);
      if (kind == TrackingRouteGeometryKind.path) {
        recenterMap();
        mapHelper._markInitialRouteReady();
      } else if (kind == TrackingRouteGeometryKind.repeatedLocation) {
        mapHelper._markInitialRouteReady();
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

  /// Restores a persisted stop-update idempotency key after process death.
  Future<void> _loadPersistedIdempotencyKey() async {
    final key = await StorageService().read(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
    );
    if (key != null) {
      stopUpdateIdempotencyKey.value = key;
    }
  }

  /// Persists [key] so stop-update can resume after app restart.
  Future<void> _saveIdempotencyKey(String key) async {
    await StorageService().write(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
      key,
    );
  }

  /// Clears persisted stop-update key and local working preview state.
  Future<void> _clearIdempotencyKey() async {
    await StorageService().delete(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
    );
    stopUpdateWorkingStops.clear();
    stopUpdatePreview.value = null;
  }

  /// Loads markers, applies ride details (or prefetch), then joins the ride room.
  Future<void> _bootstrap() async {
    // Do not fetch sockets/API with invented map pins — surface load error instead.
    if (_navArgsInvalid) {
      _setRideLoadFailure(AppStrings.missingRideInformation.tr);
      return;
    }
    await mapHelper._loadMarkerIcons();
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
    socketHelper._handleStopUpdateRecovery();
    await socketHelper._initRideRoomSocket();
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
    cancelSafetyHelper._stopNoShowCountdown();
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
    socketHelper._recoverRealtimeStateOnResume();
  }

  /// Parses navigation args into ride id, places, fare seed, and prefetch flags.
  void _parseArgs() {
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    // Prefer toString — socket/nav args may not always be a Dart [String].
    rideId = args['rideId']?.toString().trim() ?? '';
    final plat = RideNavigationCoords.read(args, 'pickupLat');
    final plng = RideNavigationCoords.read(args, 'pickupLng');
    var dlat = RideNavigationCoords.read(args, 'destinationLat');
    var dlng = RideNavigationCoords.read(args, 'destinationLng');
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
          if (RideNavigationCoords.isValidLatLng(
            finalDestination.lat,
            finalDestination.lng,
          )) {
            dlat = finalDestination.lat;
            dlng = finalDestination.lng;
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
      } catch (e, stackTrace) {
        AppLogger.e(
          'Failed to parse destinations from navigation args',
          tag: 'DriverAcceptedController',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    // Prefer fail over inventing Dar es Salaam (or offset) when nav args omit coords.
    final pickup = RideNavigationCoords.toLatLng(plat, plng);
    final destination = RideNavigationCoords.toLatLng(dlat, dlng);
    if (pickup == null || destination == null) {
      _navArgsInvalid = true;
      // Placeholder only so late fields are initialized; UI shows load error.
      pickupLatLng = pickup ?? const LatLng(0, 0);
      destinationLatLng = destination ?? const LatLng(0, 0);
      AppLogger.w(
        'Missing or invalid pickup/destination coords in navigation args',
        tag: 'DriverAcceptedController',
      );
    } else {
      pickupLatLng = pickup;
      destinationLatLng = destination;
    }

    final rawFareBreakdown = args['fareBreakdown'];
    if (rawFareBreakdown is Map) {
      _seedFareBreakdown = Map<String, dynamic>.from(rawFareBreakdown);
    }
    routePoints.clear();
    routeTarget.value = 'pick_up';
    socketHelper._hydrateSocketSeedPayloads(args);
    mapHelper._refreshMapRouteHeader();
    _skipInitialRideDetailsFetch =
        skipInitialRideDetailsFetchFromNavigationArgs(args);
    _prefetchedRide = prefetchedRideFromNavigationArgs(args);
  }

  /// Fetches ride details with in-flight coalescing; surfaces [rideLoadError] on failure.
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

  /// Single GET `/rides/:id` attempt used by [_fetchRideDetails].
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

  /// Applies a [RideModel] to UI state; may rematch or open mid-ride cancel.
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
      socketHelper._navigateBackToFindingDriverAfterChainBroken();
      return;
    }

    if (rideNeedsMidRideCancelScreen(r)) {
      final block = r.midRideCancel;
      if (block != null) {
        await cancelSafetyHelper._maybeNavigateMidRideDriverCancelled(block);
        return;
      }
    }
    rideLoadError.value = null;
    ride.value = r;
    _applyRide(r);
    cancelSafetyHelper._syncCancelAndNoShowFromRideModel(r);
    cancelSafetyHelper._syncRouteDeviationFromRideModel(r);
    mapHelper._syncDestinationFromRide(r);
    // HTTP details can show completion before/without a matching socket tick;
    // keep bottom-sheet state and completion navigation in sync with the model.
    statusLabelsHelper._applyBottomSheetStateForStatus(
      rideStatusToApiValue(r.status),
    );
    commsLiveHelper._syncLiveActivityFromDetails(r);
    await mapHelper._loadMarkerIcons();

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
        unawaited(socketHelper._ensureRideRealtimeAfterLocationUpdate());
      }
    }
  }

  /// Retry is only offered when navigation supplied a [rideId].
  bool get canRetryRideLoad => rideId.isNotEmpty;

  /// True when the error sheet has a non-empty [rideLoadError].
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

  /// Sets [rideLoadError] and clears driver fields so no stale content shows.
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

  /// Maps driver / vehicle / PIN fields from [r] onto sheet observables.
  void _applyRide(RideModel r) {
    isPinRequired.value = r.pinRequired;
    final d = r.driverSnapshot;
    final v = r.vehicleSnapshot;
    String plateForVehicleLine = '';
    statusLabelsHelper._syncBottomSheetVehicleImage(d?.vehicleType);
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

    statusLabelsHelper._applyUnifiedDriverVehicleLine(
      modelName: (d?.vehicleModel ?? '').trim(),
      plate: plateForVehicleLine,
      fallbackModel: (v?.vehicleModel ?? '').trim(),
    );
  }

  /// GetBuilder id for the map route header (pickup / drop one-line bar).
  static const String mapRouteHeaderId = 'map_route_header';
}
