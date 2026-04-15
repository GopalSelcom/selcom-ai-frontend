import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';

/// SCR-10 — finding driver: map + nearby drivers socket (same events as vehicle selection)
/// + ride room for `ride:status_update` / `ride:driver_location`.
class FindingDriverController extends GetxController {
  FindingDriverController({required this.rideRepository});

  final RideRepository rideRepository;
  final AppSocketService _socketService = AppSocketService();

  /// Total search window (product: 10 minutes).
  static const int searchTimeoutSeconds = 600;

  late final String rideId;
  late final LatLng pickupLatLng;
  late final String pickupAddress;
  late final String destinationAddress;

  final driverMarkerPoints = <LatLng>[].obs;
  final myLocation = const LatLng(-6.7927, 39.2092).obs;
  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();

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
  StreamSubscription<Map<String, dynamic>>? _rideStatusSub;
  StreamSubscription<Map<String, dynamic>>? _driverLocSub;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    _seedMockMapData();
    _loadMarkerIcons();
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
    pickupLatLng = LatLng(plat, plng);
    pickupAddress = (args['pickupAddress'] as String?)?.trim() ?? '';
    destinationAddress = (args['destinationAddress'] as String?)?.trim() ?? '';
  }

  void _seedMockMapData() {
    driverMarkerPoints.assignAll([
      const LatLng(-6.7915, 39.2078),
      const LatLng(-6.7939, 39.2107),
      const LatLng(-6.7948, 39.2069),
    ]);
  }

  Future<void> _loadMarkerIcons() async {
    try {
      nearBikeMarkerIcon.value = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(34, 34)),
        AppAssets.boda,
      );
      nearCarMarkerIcon.value = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(36, 36)),
        AppAssets.gari,
      );
      assignedDriverMarkerIcon.value = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(36, 36)),
        AppAssets.gariPlus,
      );
    } catch (_) {
      // Keep marker fallbacks from screen if custom assets fail.
    }
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
    _mockDriverAssignTimer = Timer(const Duration(seconds: 6), () {
      setMockPhase('driver_assigned');
    });
  }

  Future<void> _initRideRoomSocket() async {
    if (rideId.isEmpty) {
      // Keep visual flow working when screen is opened without a backend ride id.
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
      final status = (payload['status'] ?? '').toString().toLowerCase();
      if (status.isEmpty) return;
      if (status == 'driver_assigned' || status == 'accepted') {
        ridePhase.value = 'driver_assigned';
      } else if (status == 'cancelled' || status == 'completed') {
        Get.offAllNamed(AppRoutes.home);
      }
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      final lat = (payload['lat'] as num?)?.toDouble();
      final lng = (payload['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      assignedDriverLocation.value = LatLng(lat, lng);
      ridePhase.value = 'driver_assigned';
    });

    await _socketService.connect();
    if (_socketService.isConnected) {
      _socketService.joinRideRoom(rideId: rideId);
    }
  }

  void setMockPhase(String phase) {
    if (phase == 'driver_assigned') {
      assignedDriverLocation.value = const LatLng(-6.7921, 39.2101);
      ridePhase.value = 'driver_assigned';
      return;
    }
    assignedDriverLocation.value = null;
    ridePhase.value = 'searching';
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    c.animateCamera(CameraUpdate.newLatLngZoom(pickupLatLng, 15));
  }

  void recenterMap() {
    final focus = assignedDriverLocation.value ?? pickupLatLng;
    mapController?.animateCamera(CameraUpdate.newLatLngZoom(focus, 15));
  }

  /// Minutes label for UI (Figma-style "N minutes remain").
  int get remainingWholeMinutes =>
      (remainingSeconds.value / 60).ceil().clamp(0, searchTimeoutSeconds ~/ 60);

  Future<void> confirmCancelRide() async {
    // 1. Initial Confirmation
    final bool isAssigned = ridePhase.value == 'driver_assigned';
    final dynamic confirmResult = await Get.dialog(
      isAssigned
          ? const CancelAssignmentWarningDialog()
          : const CancelConfirmationDialog(),
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
