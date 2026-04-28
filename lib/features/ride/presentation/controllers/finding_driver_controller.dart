import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';

/// SCR-10 — finding driver: search UI only; on assignment navigates to [AppRoutes.driverAccepted].
class FindingDriverController extends GetxController {
  FindingDriverController({required this.rideRepository});

  final RideRepository rideRepository;
  final AppSocketService _socketService = AppSocketService();

  /// Total search window (product: 9 minutes).
  static const int searchTimeoutSeconds = 540;

  late final String rideId;
  late final LatLng pickupLatLng;
  late final LatLng destinationLatLng;
  late final String pickupAddress;
  late final String destinationAddress;
  late final String? requestedVehicleType;
  late final Map<String, dynamic>? fareBreakdown;

  final nearbyDriverCount = 0.obs;
  final driverMarkerPoints = <LatLng>[].obs;
  final isSocketConnected = false.obs;
  final lastSocketError = ''.obs;
  final isLoadingNearbyDrivers = false.obs;

  final remainingSeconds = searchTimeoutSeconds.obs;
  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();
  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();
  final routeTarget = ''.obs;
  final activeRoutePoints = <LatLng>[].obs;

  final currentStatusLabel = 'Finding Your Driver'.obs;
  final currentDescriptionLabel =
      'The driver will pick you up as soon as possible\nafter they confirm your order'
          .obs;
  final isRideCancelled = false.obs;

  final currentEtaSeconds = 0.0.obs;
  final sheetSize = 0.42.obs;
  final Rxn<EventRiderStatusUpdateResponse> latestRideStatusPayload =
      Rxn<EventRiderStatusUpdateResponse>();
  final Rxn<DriverLocationSocketResponse> latestDriverLocationPayload =
      Rxn<DriverLocationSocketResponse>();
  final Rxn<TrackingUpdateSocketResponse> latestTrackingPayload =
      Rxn<TrackingUpdateSocketResponse>();
  final driverName = ''.obs;
  final driverPhone = ''.obs;

  GoogleMapController? mapController;

  Timer? _countdownTimer;
  Timer? _mockDriverAssignTimer;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;
  StreamSubscription<List<Driver>>? _nearbyDriversSub;
  StreamSubscription<String>? _nearbyDriversErrorSub;

  bool _didNavigateToAccepted = false;

  void updateSheetSize(double size) {
    sheetSize.value = size;
  }

  void _showCancelDialogThenGoHome(String message) {
    Future.delayed(Duration.zero, () {
      AppDialogs.showErrorDialog(
        title: 'Search Ended',
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
  }

  Future<void> _loadMarkerIcons() async {
    pickupIcon.value = await MapMarkerUtils.createTextMarker(
      text: 'P',
      color: AppColors.mapPickupMarkerBlue,
    );
    dropIcon.value = await MapMarkerUtils.createTextMarker(
      text: 'D',
      color: AppColors.mapDropMarkerGreen,
    );
    // Initial attempt to load the icon for the requested vehicle type
    await _loadDriverMarkerIcon(vehicleType: requestedVehicleType);
  }

  Future<void> _loadDriverMarkerIcon({String? vehicleType}) async {
    try {
      final asset = VehicleImageUtils.imageAssetForVehicleType(vehicleType);
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getResizedMarker(
        asset,
        150,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      // Fallback
      assignedDriverMarkerIcon.value = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(36, 36)),
        AppAssets.gariPlus,
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
    final rawFareBreakdown = args['fareBreakdown'];
    fareBreakdown = rawFareBreakdown is Map
        ? Map<String, dynamic>.from(rawFareBreakdown)
        : null;
    _buildDummyRoute(plat, plng, dlat, dlng);
    _setPickupRouteFallback();
  }

  void _buildDummyRoute(double pLat, double pLng, double dLat, double dLng) {
    // We only show the full route (pickup to destination) if the status is NOT "Finding Your Driver"
    // or if we explicitly want to show the intent.
    // However, per request, we should focus on Driver -> Pickup.
    // If no driver is assigned, we'll keep activeRoutePoints empty (just show pulse).
    activeRoutePoints.clear();
  }

  void _setPickupRouteFallback() {
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
    routeTarget.value = 'pick_up';
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
    remainingSeconds.value = searchTimeoutSeconds;
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
      if (rideId.isEmpty) return;

      await LiveActivityManager().startActivity(
        orderId: rideId,
        status: 'SEARCHING',
        driverName: 'Finding Your Driver',
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
    if (rideId.isEmpty) return;

    final result = await rideRepository.cancelRide(
      rideId,
      'Search timeout: no driver found',
    );
    result.fold(
      (failure) async {
        await LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(
          'No drivers found within 9 minutes. Please try again.',
        );
      },
      (success) async {
        await LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(
          'No drivers found within 9 minutes. Please try again.',
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

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _socketService.joinRideRoom(rideId: rideId);
    });

    _rideStatusSub = _socketService.rideStatusStream.listen((payload) async {
      developer.log(
        "📥 Socket Event: ride_status_stream - Status: ${payload.status} for ride $rideId",
        name: 'ORDER_TRACKING',
        error: jsonEncode(payload.toJson()),
      );
      latestRideStatusPayload.value = payload;
      final status = (payload.status ?? '').toString().trim().toLowerCase();
      _applyStatusPayload(payload);
      // Removed _syncLiveActivityFromPayload(payload) to respect 'APNs-only' update model
      if (status.isEmpty) return;

      switch (status) {
        case 'driver_assigned':
        case 'accepted':
          currentStatusLabel.value = 'Driver Assigned';
          currentDescriptionLabel.value =
              'A driver has accepted your ride and is on the way.';
          _loadDriverMarkerIcon(
            vehicleType: payload.driverSnapshot?.vehicleType,
          );
          _navigateToDriverAccepted();
          break;
        case 'driver_arrived':
          currentStatusLabel.value = 'Driver Arrived';
          currentDescriptionLabel.value =
              'Your driver has arrived at the pickup location.';
          _setDropRouteFallback();
          _fitRouteBounds();
          break;
        case 'ride_started':
        case 'ride_in_progress':
          currentStatusLabel.value = 'Ride Started';
          currentDescriptionLabel.value =
              'You are on your way to the destination.';
          _setDropRouteFallback();
          _fitRouteBounds();
          break;
        case 'ride_completed':
          currentStatusLabel.value = 'Ride Completed';
          currentDescriptionLabel.value = 'You have reached your destination.';
          break;
        case 'cancelled':
          isRideCancelled.value = true;
          currentStatusLabel.value = 'Ride Cancelled';
          currentDescriptionLabel.value = 'The ride has been cancelled.';
          LiveActivityManager().endActivity(rideId);
          _showCancelDialogThenGoHome(AppStrings.yourRideWasCancelled.tr);
          break;
        case 'no_driver_found':
        case 'no_drivers_found':
          isRideCancelled.value = true;
          currentStatusLabel.value = 'No Driver Found';
          currentDescriptionLabel.value = 'We couldn\'t find a driver nearby.';
          LiveActivityManager().endActivity(rideId);
          _showCancelDialogThenGoHome(
            AppStrings.noDriversNearbyPleaseTryAgainLater.tr,
          );
          break;
        default:
          developer.log(
            "⚠️ Unhandled Socket Status: $status",
            name: 'ORDER_TRACKING',
          );
          break;
      }
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      latestDriverLocationPayload.value = payload;
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat == null || lng == null) return;
      assignedDriverLocation.value = LatLng(lat, lng);
      if (shouldShowPickupRoute) {
        _setPickupRouteFallback();
      }
      _fitRouteBounds();
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((payload) {
      if (payload == null) return;
      latestTrackingPayload.value = payload;
      _applyTrackingPayload(payload);
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

  /// Debug: jump to SCR-11 without waiting for socket (only in debug builds).
  void debugSkipToDriverAccepted() {
    assert(kDebugMode);
    _navigateToDriverAccepted();
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
    final coords = payload.routeGeometry?.coordinates;
    if (target == 'pick_up') {
      if (coords != null && coords.isNotEmpty) {
        activeRoutePoints.assignAll(_toLatLngPolyline(coords));
      } else {
        _setPickupRouteFallback();
      }
      routeTarget.value = 'pick_up';
    } else if (target == 'drop_off') {
      if (coords != null && coords.isNotEmpty) {
        activeRoutePoints.assignAll(_toLatLngPolyline(coords));
      } else {
        _setDropRouteFallback();
      }
      routeTarget.value = 'drop_off';
    }
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    final target = _normalizeRouteTarget(payload.routeTarget);
    final coords = payload.routeGeometry?.coordinates;
    if (target == 'pick_up') {
      routeTarget.value = 'pick_up';
      if (coords != null && coords.isNotEmpty) {
        activeRoutePoints.assignAll(_toLatLngPolyline(coords));
      } else {
        _setPickupRouteFallback();
      }
    } else if (target == 'drop_off') {
      routeTarget.value = 'drop_off';
      if (coords != null && coords.isNotEmpty) {
        activeRoutePoints.assignAll(_toLatLngPolyline(coords));
      } else {
        _setDropRouteFallback();
      }
    }
    if ((payload.eta ?? 0) > 0) {
      currentEtaSeconds.value = (payload.eta ?? 0).toDouble();
      // Removed redundant _syncLiveActivity() call to respect 'APNs-only' update model
    }
    _fitRouteBounds();
  }

  String _normalizeRouteTarget(String? target) {
    final t = (target ?? '').trim().toLowerCase();
    if (t == 'pickup' || t == 'pick_up') return 'pick_up';
    if (t == 'dropoff' || t == 'drop_off' || t == 'destination') {
      return 'drop_off';
    }
    return '';
  }

  List<LatLng> _toLatLngPolyline(List<List<double>> coords) {
    return coords
        .where((c) => c.length >= 2)
        .map((c) => LatLng(c[1], c[0]))
        .toList();
  }

  int get remainingWholeMinutes =>
      (remainingSeconds.value / 60).ceil().clamp(0, searchTimeoutSeconds ~/ 60);

  Future<void> confirmCancelRide() async {
    // 1. Initial Confirmation
    // final bool isAssigned = ridePhase.value == 'driver_assigned';
    final dynamic confirmResult = await Get.dialog(
      /*isAssigned
          ? const CancelAssignmentWarningDialog()
          : const */
      const CancelConfirmationDialog(),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );

    if (confirmResult != true) return;

    // 2. Reason Selection
    final String? reason = await Get.dialog<String>(
      const CancelReasonSelectionDialog(
        reasons: [
          'Taking too long to confirm the ride',
          'Wait time too long',
          'Selected wrong pickup location',
          'Selected wrong drop location',
          'Booked by mistake',
          'Changed my mind',
          'Others',
        ],
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );

    if (reason == null) return;
    if (rideId.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.cancelFailed.tr,
        message: AppStrings.rideIdIsMissing.tr,
      );
      return;
    }

    final charges = await rideRepository.getCancellationCharges(rideId);
    bool canProceed = false;
    await charges.fold(
      (_) async {
        AppDialogs.showErrorDialog(
          title: AppStrings.cancelFailed.tr,
          message: AppStrings.couldNotCancelTryAgain.tr,
        );
      },
      (data) async {
        final selectedPolicy = data.policy.firstWhereOrNull(
          (p) => p.status.toLowerCase() == data.currentStatus.toLowerCase(),
        );
        final proceed = await Get.dialog<bool>(
          CancellationChargesDialog(
            canCancel: data.canCancel,
            cancellationFee: data.cancellationFee,
            netRefund: data.netRefund,
            policyLabel: selectedPolicy?.label ?? '',
          ),
          barrierDismissible: false,
          barrierColor: AppColors.overlayBlack12,
        );
        canProceed = proceed == true;
      },
    );
    if (!canProceed) return;

    // 3. Perform Cancellation
    final result = await rideRepository.cancelRide(rideId, reason);
    result.fold(
      (_) => AppDialogs.showErrorDialog(
        title: AppStrings.cancelFailed.tr,
        message: AppStrings.couldNotCancelTryAgain.tr,
      ),
      (success) async {
        if (!success) {
          AppDialogs.showErrorDialog(
            title: AppStrings.cancelFailed.tr,
            message: AppStrings.pleaseTryAgain.tr,
          );
        } else {
          await LiveActivityManager().endActivity(rideId);
        }
      },
    );
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
      },
    );
  }

  void openRideMessage() {
    Get.toNamed(
      AppRoutes.rideMessage,
      arguments: <String, dynamic>{
        'rideId': rideId,
        'driverName': driverName.value,
        'driverPhone': driverPhone.value, // Added driverPhone
        'initialStatus': 'searching',
      },
    );
  }
}
