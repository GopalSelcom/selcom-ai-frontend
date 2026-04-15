import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';

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

  final remainingSeconds = searchTimeoutSeconds.obs;
  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();
  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();
  final routeTarget = 'pick_up'.obs;
  final activeRoutePoints = <LatLng>[].obs;

  final currentStatusLabel = 'Finding Your Driver'.obs;
  final currentDescriptionLabel =
      'The driver will pick you up as soon as possible\nafter they confirm your order'.obs;

  final Rxn<EventRiderStatusUpdateResponse> latestRideStatusPayload =
      Rxn<EventRiderStatusUpdateResponse>();
  final Rxn<DriverLocationSocketResponse> latestDriverLocationPayload =
      Rxn<DriverLocationSocketResponse>();
  final Rxn<TrackingUpdateSocketResponse> latestTrackingPayload =
      Rxn<TrackingUpdateSocketResponse>();
  final driverName = 'John Doe'.obs;
  final driverPhone = '+255 700 000 000'.obs;
  final selectedRideIndex = 0.obs;

  GoogleMapController? mapController;

  Timer? _countdownTimer;
  Timer? _mockDriverAssignTimer;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;

  bool _didNavigateToAccepted = false;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    _startCountdown();
    _initRideRoomSocket();
    _loadMarkerIcons();
  }

  Future<void> _loadMarkerIcons() async {
    pickupIcon.value = await MapMarkerUtils.createCustomCircleMarker(
      color: const Color(0xFF4FA3FF),
    );
    dropIcon.value = await MapMarkerUtils.createCustomCircleMarker(
      color: const Color(0xFFE11D48),
    );
    // Initial attempt to load a generic driver icon or wait for assignment
    await _loadDriverMarkerIcon();
  }

  Future<void> _loadDriverMarkerIcon({String? vehicleType}) async {
    try {
      String asset = AppAssets.imgCab;
      if (vehicleType != null) {
        final vt = vehicleType.toLowerCase();
        if (vt.contains('boda') || vt.contains('bike')) asset = AppAssets.imgBoda;
        else if (vt.contains('bajaj')) asset = AppAssets.imgBajaji;
      }
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getResizedMarker(asset, 150);
    } catch (_) {
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
    _socketService.dispose();
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
    _setPickupRouteFallback();
  }

  void _setPickupRouteFallback() {
    final driver = assignedDriverLocation.value;
    if (driver != null) {
      activeRoutePoints.assignAll([driver, pickupLatLng]);
    } else {
      activeRoutePoints.assignAll([pickupLatLng, destinationLatLng]);
    }
    routeTarget.value = 'pick_up';
  }

  void _setDropRouteFallback() {
    activeRoutePoints.assignAll([pickupLatLng, destinationLatLng]);
    routeTarget.value = 'drop_off';
  }

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
  }

  Future<void> _autoCancelRide() async {
    if (rideId.isEmpty) return;

    // Show a small loader or snackbar to inform user
    Get.snackbar(
      'Search Timeout',
      'No drivers found within 9 minutes. Cancelling ride...',
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );

    final result = await rideRepository.cancelRide(
      rideId,
      'Search timeout: no driver found',
    );
    result.fold(
      (failure) {
        // If it fails, we still go home because the search is technically over
        Get.offAllNamed(AppRoutes.home);
      },
      (success) {
        Get.offAllNamed(AppRoutes.home);
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
    _mockDriverAssignTimer?.cancel();
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

    _rideStatusSub = _socketService.rideStatusStream.listen((payload) {
      latestRideStatusPayload.value = payload;
      final status = (payload.status ?? '').toString().toLowerCase();
      _applyStatusPayload(payload);
      if (status.isEmpty) return;

      switch (status) {
        case 'driver_assigned':
        case 'accepted':
          currentStatusLabel.value = 'Driver Assigned';
          currentDescriptionLabel.value =
              'A driver has accepted your ride and is on the way.';
          _loadDriverMarkerIcon(vehicleType: payload.driverSnapshot?.vehicleType);
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
          currentDescriptionLabel.value = 'You are on your way to the destination.';
          _setDropRouteFallback();
          _fitRouteBounds();
          break;
        case 'ride_completed':
          currentStatusLabel.value = 'Ride Completed';
          currentDescriptionLabel.value = 'You have reached your destination.';
          Get.snackbar('Success', 'Ride completed successfully!');
          Future.delayed(const Duration(seconds: 2), () {
            Get.offAllNamed(AppRoutes.home);
          });
          break;
        case 'cancelled':
          currentStatusLabel.value = 'Ride Cancelled';
          currentDescriptionLabel.value = 'The ride has been cancelled.';
          Get.snackbar('Cancelled', 'Your ride was cancelled.');
          Get.offAllNamed(AppRoutes.home);
          break;
        case 'no_driver_found':
          currentStatusLabel.value = 'No Driver Found';
          currentDescriptionLabel.value = 'We couldn\'t find a driver nearby.';
          Get.snackbar('Ride Cancelled', 'No drivers nearby. Please try again later.',
              backgroundColor: Colors.black87, colorText: Colors.white);
          Get.offAllNamed(AppRoutes.home);
          break;
      }
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      latestDriverLocationPayload.value = payload;
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat == null || lng == null) return;
      assignedDriverLocation.value = LatLng(lat, lng);
      if (routeTarget.value == 'pick_up') {
        _setPickupRouteFallback();
      }
      _fitRouteBounds();
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((payload) {
      if (payload == null) return;
      latestTrackingPayload.value = payload;
      _applyTrackingPayload(payload);
    });

    await _socketService.connect();
    if (_socketService.isConnected) {
      _socketService.joinRideRoom(rideId: rideId);
    }
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
      destinationLatLng,
      ...activeRoutePoints,
      if (assignedDriverLocation.value != null) assignedDriverLocation.value!,
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
      CancelConfirmationDialog(),
      barrierDismissible: false,
    );

    if (confirmResult != true) return;

    // 2. Reason Selection
    final String? reason = await Get.dialog<String>(
      const CancelReasonSelectionDialog(),
      barrierDismissible: false,
    );

    if (reason == null) return;

    // 3. Perform Cancellation
    if (rideId.isEmpty) {
      Get.snackbar('Cancel failed', 'Ride id is missing.');
      return;
    }

    final result = await rideRepository.cancelRide(rideId, reason);
    result.fold(
      (_) => Get.snackbar('Cancel failed', 'Could not cancel. Try again.'),
      (success) {
        if (success) {
          Get.offAllNamed(AppRoutes.home);
        } else {
          Get.snackbar('Cancel failed', 'Please try again.');
        }
      },
    );
  }

  final rideOptions = const <MockRideOption>[
    MockRideOption(
      name: 'GoRide Card',
      capacity: '4',
      eta: '10 min away',
      dropAt: 'Drop 1:11 pm',
      fare: 'TZS 500',
      assetPath: AppAssets.gari,
      nearFast: true,
    ),
    MockRideOption(
      name: 'Bajaji',
      capacity: '3',
      eta: '5 min away',
      dropAt: 'Drop 1:09 pm',
      fare: 'TZS 100',
      assetPath: AppAssets.bajaj,
    ),
    MockRideOption(
      name: 'Boda',
      capacity: '1',
      eta: '1 min away',
      dropAt: 'Drop 1:00 pm',
      fare: 'TZS 100',
      assetPath: AppAssets.boda,
    ),
  ];

  String get selectedFare => rideOptions[selectedRideIndex.value].fare;

  void selectRideOption(int index) {
    if (index < 0 || index >= rideOptions.length) return;
    selectedRideIndex.value = index;
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

class MockRideOption {
  final String name;
  final String capacity;
  final String eta;
  final String dropAt;
  final String fare;
  final String assetPath;
  final bool nearFast;

  const MockRideOption({
    required this.name,
    required this.capacity,
    required this.eta,
    required this.dropAt,
    required this.fare,
    required this.assetPath,
    this.nearFast = false,
  });
}
