import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/repositories/ride_repository.dart';

/// SCR-10 — finding driver: map + nearby drivers socket (same events as vehicle selection)
/// + ride room for `ride:status_update` / `ride:driver_location`.
class FindingDriverController extends GetxController {
  FindingDriverController({required this.rideRepository});

  final RideRepository rideRepository;

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
  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon = Rxn<BitmapDescriptor>();

  GoogleMapController? mapController;

  Timer? _countdownTimer;
  Timer? _mockDriverAssignTimer;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    _seedMockMapData();
    _loadMarkerIcons();
    _startCountdown();
    _scheduleMockDriverAssigned();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _mockDriverAssignTimer?.cancel();
    super.onClose();
  }

  void _parseArgs() {
    final raw = Get.arguments;
    final args = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
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
    c.animateCamera(
      CameraUpdate.newLatLngZoom(pickupLatLng, 15),
    );
  }

  void recenterMap() {
    final focus = assignedDriverLocation.value ?? pickupLatLng;
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(focus, 15),
    );
  }

  /// Minutes label for UI (Figma-style "N minutes remain").
  int get remainingWholeMinutes =>
      (remainingSeconds.value / 60).ceil().clamp(0, searchTimeoutSeconds ~/ 60);

  Future<void> confirmCancelRide() async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel ride?'),
        content: const Text(
          'Are you sure you want to cancel this ride request?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('No')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    Get.offAllNamed(AppRoutes.home);
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
