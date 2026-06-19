import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/ride_fare_settled_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/address_display_utils.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/book_any_fare_settled_ui.dart';
import '../../../../shared/utils/driver_search_timeout_from_cancel_time.dart';
import '../../../../shared/utils/ride_active_navigation.dart';
import '../../../../shared/utils/ride_pickup_status_labels.dart';
import '../../../../shared/utils/ride_status_normalizer.dart';
import '../../../../shared/utils/map_route_marker_utils.dart';
import '../../../../shared/utils/route_map_marker_icons.dart';
import '../../../../shared/utils/route_pin_letter_style.dart';
import '../../../../shared/utils/map_vehicle_marker_utils.dart';
import '../../../../shared/utils/socket_ride_scope.dart';
import '../../../../shared/utils/tracking_route_geometry_utils.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/repositories/ride_repository.dart';
import '../utils/cancel_ride_flow.dart';

/// SCR-10 — finding driver: search UI only; on assignment navigates to [AppRoutes.driverAccepted].
class FindingDriverController extends GetxController {
  FindingDriverController({required this.rideRepository});

  final RideRepository rideRepository;
  final AppSocketService _socketService = AppSocketService();

  /// Total search window in seconds (from API `cancel_time` ms, else default 9 min).
  late final int _searchTimeoutSeconds;
  static const int _defaultSearchTimeoutSeconds = 540;

  late final String rideId;
  late final LatLng pickupLatLng;
  late final LatLng destinationLatLng;
  late final String pickupAddress;
  late final String destinationAddress;
  late final String? requestedVehicleType;
  late final Map<String, dynamic>? fareBreakdown;
  final intermediateStops = <String>[].obs;
  final destinations = <LocationEntity>[].obs;

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

  final nearbyDriverCount = 0.obs;
  final driverMarkerPoints = <LatLng>[].obs;
  final isSocketConnected = false.obs;
  final lastSocketError = ''.obs;
  final isLoadingNearbyDrivers = false.obs;

  final remainingSeconds = _defaultSearchTimeoutSeconds.obs;
  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();
  final Rxn<LatLng> animatedRiderLocation = Rxn<LatLng>();
  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();
  final stopIcons = <BitmapDescriptor>[].obs;
  final Map<String, BitmapDescriptor> _redRouteLetterIcons = {};
  final Map<String, BitmapDescriptor> _greenRouteLetterIcons = {};
  bool _routeLetterIconsLoaded = false;

  bool get usesMultiStopRouteMarkers => destinations.length > 1;

  final routeTarget = ''.obs;
  final activeRoutePoints = <LatLng>[].obs;

  /// Sheet headline — driven by [RidePickupStatusLabels] from socket/API status.
  final currentStatusLabel = AppStrings.findingYourDriver.tr.obs;

  /// Sheet subline — paired with [currentStatusLabel].
  final currentDescriptionLabel =
      AppStrings.findingDriverDefaultDescription.tr.obs;

  /// Canonical pickup-phase status (`searching`, `driver_assigned`, …).
  final normalizedRideStatus = 'searching'.obs;
  final isRideCancelled = false.obs;
  final isReasonProcessing = false.obs;
  final isCancelPayProcessing = false.obs;

  final currentEtaSeconds = 0.0.obs;
  final sheetSize = 0.42.obs;
  final Rxn<EventRiderStatusUpdateResponse> latestRideStatusPayload =
      Rxn<EventRiderStatusUpdateResponse>();
  final Rxn<DriverLocationSocketResponse> latestDriverLocationPayload =
      Rxn<DriverLocationSocketResponse>();
  bool _hasReceivedTrackingUpdate = false;
  final Rxn<TrackingUpdateSocketResponse> latestTrackingPayload =
      Rxn<TrackingUpdateSocketResponse>();
  final driverName = ''.obs;
  final driverPhone = ''.obs;

  final isBookedForOther = false.obs;
  final passengerName = RxnString();
  final passengerPhone = RxnString();

  GoogleMapController? mapController;

  Timer? _countdownTimer;
  Timer? _mockDriverAssignTimer;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;
  StreamSubscription<RideFareSettledResponse>? _fareSettledSub;
  StreamSubscription<List<Driver>>? _nearbyDriversSub;
  StreamSubscription<String>? _nearbyDriversErrorSub;

  bool _didNavigateToAccepted = false;

  /// Suppresses duplicate cancel UI when the user initiated cancel (socket may also fire `cancelled`).
  bool _isUserInitiatedCancellation = false;

  /// Ensures only one no-driver terminal dialog (timeout auto-cancel + socket can both fire).
  bool _noDriverDialogShown = false;

  /// When false, hide search countdown/progress (driver matched or later).
  bool get isSearchingPhase =>
      isRideSearchingStatus(normalizedRideStatus.value);

  /// Updates sheet copy from [RidePickupStatusLabels] after status normalization.
  void _applyPickupStatusLabels(String normalized) {
    normalizedRideStatus.value = normalized.isEmpty ? 'searching' : normalized;
    currentStatusLabel.value = RidePickupStatusLabels.titleFor(
      normalizedRideStatus.value,
    );
    currentDescriptionLabel.value = RidePickupStatusLabels.descriptionFor(
      normalizedRideStatus.value,
    );
  }

  String _driverNameFromPayload(EventRiderStatusUpdateResponse payload) {
    final name = payload.driverSnapshot?.name?.trim() ?? '';
    return name.isNotEmpty ? name : AppStrings.driver.tr;
  }

  /// Stops search UI and opens driver-accepted (once per ride).
  void _onDriverAssignedPhase(
    String normalized,
    EventRiderStatusUpdateResponse payload,
  ) {
    _countdownTimer?.cancel();
    _loadDriverMarkerIcon(vehicleType: payload.driverSnapshot?.vehicleType);
    if (!_didNavigateToAccepted) {
      _navigateToDriverAccepted();
    }
  }

  /// Central handler for `ride:status_update` and HTTP catch-up on this screen.
  ///
  /// Always normalizes [rawStatus] first — never compare raw socket strings directly.
  void _handleRideStatus(
    String rawStatus,
    EventRiderStatusUpdateResponse payload,
  ) {
    final normalized = normalizeRideStatusString(rawStatus);
    if (normalized.isEmpty) return;

    // Refresh labels immediately so the user sees the right phase before navigation.
    _applyPickupStatusLabels(normalized);

    switch (normalized) {
      case 'searching':
        break;
      case 'driver_assigned':
      case 'accepted':
      case 'driver_arriving':
      case 'driver_en_route':
      case 'en_route':
        _onDriverAssignedPhase(normalized, payload);
        break;
      case 'driver_arrived':
        _onDriverAssignedPhase(normalized, payload);
        if (_hasReceivedTrackingUpdate) _fitRouteBounds();
        break;
      case 'ride_started':
      case 'ride_in_progress':
        final driver = _driverNameFromPayload(payload);
        currentStatusLabel.value = AppStrings.driverStartedYourRide.trParams({
          'driverName': driver,
        });
        currentDescriptionLabel.value = AppStrings.rideStartedDescription.tr;
        _onDriverAssignedPhase(normalized, payload);
        if (_hasReceivedTrackingUpdate) _fitRouteBounds();
        break;
      case 'ride_completed':
        currentStatusLabel.value = AppStrings.rideCompleted.tr;
        currentDescriptionLabel.value =
            AppStrings.youHaveReachedYourDestination.tr;
        break;
      case 'cancelled':
        if (_isUserInitiatedCancellation) return;
        isRideCancelled.value = true;
        currentStatusLabel.value = AppStrings.rideCancelled.tr;
        currentDescriptionLabel.value = AppStrings.theRideHasBeenCancelled.tr;
        LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(AppStrings.yourRideWasCancelled.tr);
        break;
      case 'no_driver_found':
      case 'no_drivers_found':
        isRideCancelled.value = true;
        currentStatusLabel.value = AppStrings.noDriverFound.tr;
        currentDescriptionLabel.value =
            AppStrings.weCouldntFindADriverNearby.tr;
        LiveActivityManager().endActivity(rideId);
        _showNoDriverFoundDialogThenGoHome(
          AppStrings.noDriversNearbyPleaseTryAgainLater.tr,
        );
        break;
      default:
        if (shouldLeaveFindingDriverForPickup(normalized)) {
          _onDriverAssignedPhase(normalized, payload);
        } else {
          developer.log(
            "⚠️ Unhandled Socket Status: $normalized",
            name: 'ORDER_TRACKING',
          );
        }
        break;
    }
  }

  void updateSheetSize(double size) {
    sheetSize.value = size;
  }

  void _showCancelDialogThenGoHome(String message) {
    Future.delayed(Duration.zero, () {
      AppDialogs.showErrorDialog(
        title: AppStrings.searchEnded.tr,
        message: message,
        onConfirm: () => Get.offAllNamed(AppRoutes.home),
      );
    });
  }

  void _showNoDriverFoundDialogThenGoHome(String message) {
    if (_noDriverDialogShown) return;
    _noDriverDialogShown = true;
    Future.delayed(Duration.zero, () {
      AppDialogs.showErrorDialog(
        title: AppStrings.searchEnded.tr,
        message: message,
        onConfirm: () => Get.offAllNamed(AppRoutes.home),
      );
    });
  }

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    _startCountdown();
    _initNearbyDriversSocket();
    _initRideRoomSocket();
    _loadMarkerIcons();
    // HTTP catch-up in case socket events were missed during room join.
    unawaited(_syncInitialRideStatusFromApi());
  }

  /// Polls ride details once so we don't stay on "Finding driver" after assignment.
  Future<void> _syncInitialRideStatusFromApi() async {
    if (rideId.isEmpty) return;
    final result = await rideRepository.getRideDetails(rideId);
    result.fold((_) {}, (ride) {
      final rawStatus = rideStatusToApiValue(ride.status);
      final normalized = normalizeRideStatusString(rawStatus);
      if (isRideSearchingStatus(normalized)) return;

      final d = ride.driverSnapshot;
      DriverSnapshot? driverSnapshot;
      if (d is DriverSnapshotModel) {
        driverSnapshot = DriverSnapshot(
          name: d.name,
          phone: d.phone,
          avatarUrl: d.avatarUrl,
          vehicleColor: d.vehicleColor,
          vehicleModel: d.vehicleModel,
          vehicleRegistrationNumber: d.vehicleRegistrationNumber,
          vehicleType: d.vehicleType,
          verificationCode: d.verificationCode,
          rating: d.rating,
        );
      } else if (d != null) {
        driverSnapshot = DriverSnapshot(
          name: d.name,
          phone: d.phone,
          avatarUrl: d.avatarUrl,
          rating: d.rating,
        );
      }

      final payload = EventRiderStatusUpdateResponse(
        rideId: ride.id,
        status: rawStatus,
        pinCode: ride.pinCode,
        pinRequired: ride.pinRequired,
        driverSnapshot: driverSnapshot,
      );
      latestRideStatusPayload.value = payload;
      _handleRideStatus(rawStatus, payload);
    });
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

  BitmapDescriptor redRouteLetterIconForSequentialIndex(int sequentialIndex) {
    final letter = MapRouteMarkerUtils.letterAt(sequentialIndex + 1);
    return RouteMapMarkerIcons.cached(
          letter: letter,
          color: RoutePinLetterStyle.intermediateColor(sequentialIndex),
        ) ??
        dropIcon.value ??
        BitmapDescriptor.defaultMarker;
  }

  Future<void> _loadMarkerIcons() async {
    await _ensureRouteLetterIcons();

    if (usesMultiStopRouteMarkers) {
      final intermediateCount = destinations.length - 1;
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

      stopIcons.assignAll(
        List<BitmapDescriptor>.generate(
          intermediateCount,
          (i) => _redRouteLetterIcons[MapRouteMarkerUtils.letterAt(i + 1)]!,
        ),
      );
    } else {
      pickupIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'P',
        color: RoutePinLetterStyle.pickupColor,
      );
      dropIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'D',
        color: RoutePinLetterStyle.destinationColor,
      );
      stopIcons.clear();
    }

    // Initial attempt to load the icon for the requested vehicle type
    await _loadDriverMarkerIcon(vehicleType: requestedVehicleType);
  }

  Future<void> _loadDriverMarkerIcon({String? vehicleType}) async {
    try {
      final asset = MapVehicleMarkerUtils.markerAssetForVehicleType(
        vehicleType,
      );
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        asset,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        AppAssets.mapMarkerCab,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    }
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _mockDriverAssignTimer?.cancel();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _fareSettledSub?.cancel();
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    super.onClose();
  }

  void _parseArgs() {
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    rideId = (args['rideId'] as String?)?.trim() ?? '';
    final plat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
    final plng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
    final dlat = (args['destinationLat'] as num?)?.toDouble() ?? (plat - 0.018);
    final dlng = (args['destinationLng'] as num?)?.toDouble() ?? (plng + 0.014);
    pickupLatLng = LatLng(plat, plng);
    destinationLatLng = LatLng(dlat, dlng);
    pickupAddress = (args['pickupAddress'] as String?)?.trim() ?? '';
    destinationAddress = (args['destinationAddress'] as String?)?.trim() ?? '';
    requestedVehicleType = args['vehicleType'] as String?;

    final List<dynamic>? ds = args['destinations'];
    if (ds != null && ds.isNotEmpty) {
      try {
        final List<LocationEntity> locs = ds
            .map((e) {
              if (e is LocationEntity) return e;
              if (e is Map<String, dynamic>) {
                return LocationEntity(
                  lat: (e['lat'] as num?)?.toDouble() ?? 0.0,
                  lng: (e['lng'] as num?)?.toDouble() ?? 0.0,
                  address: (e['address'] as String?) ?? '',
                );
              }
              return null;
            })
            .whereType<LocationEntity>()
            .toList();

        destinations.assignAll(locs);
        if (locs.length > 1) {
          // All except the last one (which is the main destination) are intermediate stops
          intermediateStops.assignAll(
            locs.take(locs.length - 1).map((e) => e.address).toList(),
          );
        }
      } catch (e) {
        debugPrint('Error parsing destinations: $e');
      }
    }

    final rawFareBreakdown = args['fareBreakdown'];
    fareBreakdown = rawFareBreakdown is Map
        ? Map<String, dynamic>.from(rawFareBreakdown)
        : null;

    isBookedForOther.value = (args['isBookedForOther'] as bool?) ?? false;
    passengerName.value = args['passengerName'] as String?;
    passengerPhone.value = args['passengerPhone'] as String?;

    _searchTimeoutSeconds = driverSearchTimeoutSecondsFromCancelTimeMillis(
      args['cancel_time'],
    );

    activeRoutePoints.clear();
    routeTarget.value = 'pick_up';
  }

  void _setPickupRouteFallback() {
    routeTarget.value = 'pick_up';
    final driver = assignedDriverLocation.value;
    if (driver != null) {
      final pLat = driver.latitude;
      final pLng = driver.longitude;
      final dLat = pickupLatLng.latitude;
      final dLng = pickupLatLng.longitude;

      final pts = <LatLng>[];
      const steps = 24;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final lat = pLat + (dLat - pLat) * t + 0.001 * (t - 0.5) * (t - 0.5);
        final lng = pLng + (dLng - pLng) * t + 0.0008 * (t - 0.3);
        pts.add(LatLng(lat, lng));
      }
      activeRoutePoints.assignAll(pts);
    } else {
      activeRoutePoints.clear();
    }
  }

  void _setDropRouteFallback() {
    activeRoutePoints.assignAll([pickupLatLng, destinationLatLng]);
    routeTarget.value = 'drop_off';
  }

  bool get shouldShowPickupRoute => routeTarget.value == 'pick_up';

  bool get shouldShowDropRoute => routeTarget.value == 'drop_off';

  bool get shouldShowDestinationMarker => shouldShowDropRoute;

  bool get shouldShowDriverMarker =>
      assignedDriverLocation.value != null && shouldShowPickupRoute;

  void _startCountdown() {
    remainingSeconds.value = _searchTimeoutSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value <= 0) {
        _countdownTimer?.cancel();
        _autoCancelRide();
        return;
      }
      remainingSeconds.value--;
    });
    _syncLiveActivity();
  }

  Future<void> _syncLiveActivity() async {
    try {
      if (Platform.isIOS && LiveActivityManager().isTracking(rideId)) return;

      await LiveActivityManager().startActivity(
        orderId: rideId,
        status: 'SEARCHING',
        driverName: AppStrings.findingYourDriver.tr,
        vehicleName: requestedVehicleType ?? '',
        plateNumber: '',
        isCompleted: false,
        etaSeconds: currentEtaSeconds.value,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      developer.log(
        "❌ Error in FindingDriverController._syncLiveActivity: $e",
        name: 'ORDER_TRACKING',
      );
      debugPrint('❌ Error syncing Live Activity: $e');
    }
  }

  Future<void> _autoCancelRide() async {
    if (rideId.isEmpty || _noDriverDialogShown) return;

    final result = await rideRepository.cancelRide(
      rideId,
      AppStrings.searchTimeoutNoDriverFound.tr,
    );
    result.fold(
      (failure) async {
        await LiveActivityManager().endActivity(rideId);
        _showNoDriverFoundDialogThenGoHome(
          AppStrings.noDriversFoundWithin9MinutesCancellingRide.tr,
        );
      },
      (success) async {
        await LiveActivityManager().endActivity(rideId);
        _showNoDriverFoundDialogThenGoHome(
          AppStrings.noDriversFoundWithin9MinutesCancellingRide.tr,
        );
      },
    );
  }

  void _scheduleMockDriverAssigned() {
    _mockDriverAssignTimer?.cancel();
    _mockDriverAssignTimer = Timer(
      const Duration(seconds: 6),
      _navigateToDriverAccepted,
    );
  }

  void _navigateToDriverAccepted() {
    if (_didNavigateToAccepted) return;
    _didNavigateToAccepted = true;
    _countdownTimer?.cancel();
    _mockDriverAssignTimer?.cancel();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    final statusPayload = latestRideStatusPayload.value;
    final driverLocPayload = latestDriverLocationPayload.value;
    final trackingPayload = latestTrackingPayload.value;
    Get.offNamed(
      AppRoutes.driverAccepted,
      arguments: {
        'rideId': rideId,
        'pickupLat': pickupLatLng.latitude,
        'pickupLng': pickupLatLng.longitude,
        'pickupAddress': pickupAddress,
        'destinationLat': destinationLatLng.latitude,
        'destinationLng': destinationLatLng.longitude,
        'destinationAddress': destinationAddress,
        'destinations': destinations.toList(),
        'statusPayload': statusPayload?.toJson(),
        'driverLocationPayload': driverLocPayload?.toJson(),
        'trackingPayload': trackingPayload?.toJson(),
        'fareBreakdown': fareBreakdown,
      },
    );
  }

  Future<void> _initRideRoomSocket() async {
    if (rideId.isEmpty) {
      _scheduleMockDriverAssigned();
      return;
    }

    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _fareSettledSub?.cancel();

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _socketService.joinRideRoom(rideId: rideId);
    });

    _rideStatusSub = _socketService.rideStatusStream.listen((payload) async {
      if (!socketPayloadIsForRide(
        activeRideId: rideId,
        payloadRideId: payload.rideId,
      )) {
        return;
      }
      developer.log(
        "📥 Socket Event: ride_status_stream - Status: ${payload.status} for ride $rideId",
        name: 'ORDER_TRACKING',
        error: jsonEncode(payload.toJson()),
      );
      latestRideStatusPayload.value = payload;
      _applyStatusPayload(payload);
      // Status string drives labels + navigation; route/ETA handled in _applyStatusPayload.
      _handleRideStatus(payload.status?.toString() ?? '', payload);
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      latestDriverLocationPayload.value = payload;
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat == null || lng == null) return;
      assignedDriverLocation.value = LatLng(lat, lng);
      if (_hasReceivedTrackingUpdate) {
        _fitRouteBounds();
      }
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((payload) {
      if (payload == null) return;
      if (!socketPayloadIsForRide(
        activeRideId: rideId,
        payloadRideId: payload.rideId,
      )) {
        return;
      }
      _hasReceivedTrackingUpdate = true;
      latestTrackingPayload.value = payload;
      _applyTrackingPayload(payload);
    });

    _fareSettledSub = _socketService.rideFareSettledStream.listen((payload) {
      BookAnyFareSettledUi.maybeShow(payload: payload, rideId: rideId);
    });

    if (_socketService.isConnected) {
      _socketService.joinRideRoom(rideId: rideId);
      // Removed redundant _syncLiveActivity() call to respect 'APNs-only' update model
    }
  }

  // Removed _syncLiveActivityFromPayload to respect 'APNs-only' update model

  Future<void> _initNearbyDriversSocket() async {
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();

    _nearbyDriversSub = _socketService.nearbyDriversStream.listen((drivers) {
      if (drivers.isEmpty) {
        driverMarkerPoints.clear();
      } else {
        driverMarkerPoints.assignAll(
          drivers
              .map(
                (d) => LatLng(
                  double.parse(d.lat ?? "0"),
                  double.parse(d.lng ?? "0"),
                ),
              )
              .toList(),
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

    _socketService.connectionStream.listen((ok) {
      isSocketConnected.value = ok;
      if (ok) {
        _requestNearbyDrivers();
      }
    });

    if (_socketService.isConnected) {
      isSocketConnected.value = true;
      _requestNearbyDrivers();
    }
  }

  void _requestNearbyDrivers() {
    if (pickupLatLng.latitude == 0 || pickupLatLng.longitude == 0) return;
    isLoadingNearbyDrivers.value = true;
    _socketService.requestNearbyDrivers(
      lat: pickupLatLng.latitude,
      lng: pickupLatLng.longitude,
      vehicleType: requestedVehicleType,
      radiusKm: 1000,
    );
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitRouteBounds();
  }

  void openProfile() {
    Get.to(() => ProfileScreen());
  }

  void recenterMap() {
    _fitRouteBounds();
  }

  Future<void> _fitRouteBounds() async {
    final ctrl = mapController;
    if (ctrl == null) return;
    final points = <LatLng>[
      pickupLatLng,
      if (shouldShowDropRoute) destinationLatLng,
      ...activeRoutePoints,
      if (shouldShowPickupRoute && assignedDriverLocation.value != null)
        assignedDriverLocation.value!,
    ];

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    await ctrl.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.006, minLng - 0.006),
          northeast: LatLng(maxLat + 0.006, maxLng + 0.006),
        ),
        56,
      ),
    );
  }

  void _applyStatusPayload(EventRiderStatusUpdateResponse payload) {
    final d = payload.driverSnapshot;
    if (d?.lat != null && d?.lng != null) {
      assignedDriverLocation.value = LatLng(d!.lat!, d.lng!);
    }
    final target = _normalizeRouteTarget(payload.routeTarget);
    _applyTrackingRouteGeometry(
      target: target,
      coordinates: payload.routeGeometry?.coordinates,
      fitCamera: true,
    );
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    var target = _normalizeRouteTarget(payload.routeTarget);
    if (target.isEmpty) {
      final status = (payload.status ?? '').toLowerCase();
      if (status.contains('progress') || status.contains('started')) {
        target = 'drop_off';
      } else if (status.contains('assigned') || status.contains('arriving')) {
        target = 'pick_up';
      }
    }
    final previousTarget = routeTarget.value;
    final previousPoints = activeRoutePoints.toList();
    _applyTrackingRouteGeometry(
      target: target,
      coordinates: payload.routeGeometry?.coordinates,
      fitCamera: false,
    );
    final routeChanged =
        routeTarget.value != previousTarget ||
        !TrackingRouteGeometryUtils.routesEquivalent(
          previousPoints,
          activeRoutePoints,
        );
    if ((payload.eta ?? 0) > 0) {
      currentEtaSeconds.value = (payload.eta ?? 0).toDouble();
      // Removed redundant _syncLiveActivity() call to respect 'APNs-only' update model
    }
    if (routeChanged) {
      _fitRouteBounds();
    }
  }

  void _applyTrackingRouteGeometry({
    required String target,
    required List<List<double>>? coordinates,
    required bool fitCamera,
  }) {
    if (target != 'pick_up' && target != 'drop_off') return;

    routeTarget.value = target;
    if (!_hasReceivedTrackingUpdate) return;

    final kind = TrackingRouteGeometryUtils.classify(coordinates);
    switch (kind) {
      case TrackingRouteGeometryKind.empty:
        if (_hasReceivedTrackingUpdate) {
          if (target == 'pick_up') {
            _setPickupRouteFallback();
          } else {
            _setDropRouteFallback();
          }
          if (fitCamera) _fitRouteBounds();
        } else if (activeRoutePoints.isNotEmpty) {
          activeRoutePoints.clear();
        }
        return;
      case TrackingRouteGeometryKind.repeatedLocation:
      case TrackingRouteGeometryKind.path:
        final nextPoints = TrackingRouteGeometryUtils.pointsForMap(coordinates);
        if (TrackingRouteGeometryUtils.routesEquivalent(
          activeRoutePoints,
          nextPoints,
        )) {
          return;
        }
        activeRoutePoints.assignAll(nextPoints);
        if (fitCamera &&
            kind == TrackingRouteGeometryKind.path &&
            nextPoints.length >= 2) {
          _fitRouteBounds();
        }
        return;
    }
  }

  String _normalizeRouteTarget(String? target) {
    final t = (target ?? '').trim().toLowerCase();
    if (t == 'pickup' || t == 'pick_up') return 'pick_up';
    if (t == 'dropoff' || t == 'drop_off' || t == 'destination') {
      return 'drop_off';
    }
    return '';
  }

  int get remainingWholeMinutes =>
      (remainingSeconds.value ~/ 60).clamp(0, _searchTimeoutSeconds ~/ 60);

  /// Countdown shown as `M:SS` (e.g. 9:00 → 8:59 → …) aligned with [remainingSeconds].
  String findingDriverCountdownMmSs() {
    final s = remainingSeconds.value.clamp(0, 999999);
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  /// Localized "X min remaining" — whole minutes = floor(seconds / 60) so 8:59 shows 8.
  String findingDriverMinutesRemainLabel() {
    final mins = remainingSeconds.value ~/ 60;
    return AppStrings.findingDriverMinutesRemain.trParams({'minutes': '$mins'});
  }

  /// User cancel from the searching bottom sheet — shared [CancelRideFlow].
  Future<void> confirmCancelRide() {
    return CancelRideFlow(
      rideRepository: rideRepository,
      rideId: rideId,
      isReasonProcessing: isReasonProcessing,
      isCancelPayProcessing: isCancelPayProcessing,
      onCancelApiStarted: () => _isUserInitiatedCancellation = true,
      onCancelApiFailed: () => _isUserInitiatedCancellation = false,
    ).run();
  }

  void searchAgain() {
    Get.offNamed(
      AppRoutes.booking,
      arguments: {
        'pickup': pickupAddress,
        'pickupLat': pickupLatLng.latitude,
        'pickupLng': pickupLatLng.longitude,
        'destination': destinationAddress,
        'destinationLat': destinationLatLng.latitude,
        'destinationLng': destinationLatLng.longitude,
        'destinations': destinations.toList(),
      },
    );
  }
}
