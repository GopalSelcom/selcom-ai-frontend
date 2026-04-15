import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';

import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';

/// SCR-10 — finding driver: search UI only; on assignment navigates to [AppRoutes.driverAccepted].
class FindingDriverController extends GetxController {
  FindingDriverController({required this.rideRepository});

  final RideRepository rideRepository;
  final AppSocketService _socketService = AppSocketService();

  /// Total search window (product: 10 minutes).
  static const int searchTimeoutSeconds = 600;

  late final String rideId;
  late final LatLng pickupLatLng;
  late final LatLng destinationLatLng;
  late final String pickupAddress;
  late final String destinationAddress;

  final remainingSeconds = searchTimeoutSeconds.obs;
  final ridePhase = 'searching'.obs;
  final driverName = 'John Doe'.obs;
  final driverPhone = '+255 700 000 000'.obs;
  final driverRating = '4'.obs;
  final driverVehicle = 'Volkswagen'.obs;
  final driverPlate = 'HG5045'.obs;
  final vehicleDisplay = 'Toyota corolla, White'.obs;
  final etaLabel = '10 Mins'.obs;
  final arrivalLabel = 'Driver will arriving in 1 min...'.obs;
  final otpDigits = const ['2', '7', '5', '6'].obs;
  final plateDigits = const ['T772', 'BBE'].obs;
  final isDebugUiSwitcherVisible = kDebugMode.obs;
  final selectedRideIndex = 0.obs;
  final Rxn<BitmapDescriptor> nearBikeMarkerIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> nearCarMarkerIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();

  GoogleMapController? mapController;

  Timer? _countdownTimer;
  Timer? _mockDriverAssignTimer;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;

  bool _didNavigateToAccepted = false;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    _startCountdown();
    _initRideRoomSocket();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _mockDriverAssignTimer?.cancel();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
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
  }

  void _startCountdown() {
    remainingSeconds.value = searchTimeoutSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value <= 0) return;
      remainingSeconds.value--;
    });
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

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _socketService.joinRideRoom(rideId: rideId);
    });

    _rideStatusSub = _socketService.rideStatusStream.listen((payload) {
      final status = (payload.status ?? '').toString().toLowerCase();
      if (status.isEmpty) return;
      if (status == 'driver_assigned' || status == 'accepted') {
        _navigateToDriverAccepted();
      } else if (status == 'cancelled' || status == 'completed') {
        Get.offAllNamed(AppRoutes.home);
      }
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat == null || lng == null) return;
      _navigateToDriverAccepted();
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
    final p = pickupLatLng;
    final d = destinationLatLng;

    final minLat = p.latitude < d.latitude ? p.latitude : d.latitude;
    final maxLat = p.latitude > d.latitude ? p.latitude : d.latitude;
    final minLng = p.longitude < d.longitude ? p.longitude : d.longitude;
    final maxLng = p.longitude > d.longitude ? p.longitude : d.longitude;

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
