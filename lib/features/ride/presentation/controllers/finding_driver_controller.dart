import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../domain/repositories/ride_repository.dart';

/// SCR-10 — finding driver: map + nearby drivers socket (same events as vehicle selection)
/// + ride room for `ride:status_update` / `ride:driver_location`.
class FindingDriverController extends GetxController {
  FindingDriverController({required this.rideRepository});

  final RideRepository rideRepository;

  final AppSocketService _socket = AppSocketService();

  /// Total search window (product: 10 minutes).
  static const int searchTimeoutSeconds = 600;

  late final String rideId;
  late final LatLng pickupLatLng;
  late final String pickupAddress;
  late final String destinationAddress;

  final driverMarkerPoints = <LatLng>[].obs;
  /// When server sends `ride:driver_location`, show assigned driver on map.
  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();

  final isSocketConnected = false.obs;
  final lastSocketError = ''.obs;
  final nearbyDriverCount = 0.obs;

  final remainingSeconds = searchTimeoutSeconds.obs;
  final ridePhase = 'searching'.obs;

  GoogleMapController? mapController;

  Timer? _countdownTimer;
  Timer? _nearbyRefreshTimer;

  StreamSubscription<List<NearbyDriverPoint>>? _driversSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<Map<String, dynamic>>? _rideStatusSub;
  StreamSubscription<Map<String, dynamic>>? _driverLocSub;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    if (rideId.isEmpty) {
      Future.microtask(() {
        Get.snackbar('Ride', 'Missing ride id.');
        Get.back();
      });
      return;
    }
    _startCountdown();
    _initSocket();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _nearbyRefreshTimer?.cancel();
    _driversSub?.cancel();
    _errorSub?.cancel();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _socket.dispose();
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

  void _startCountdown() {
    remainingSeconds.value = searchTimeoutSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds.value <= 0) return;
      remainingSeconds.value--;
    });
  }

  Future<void> _initSocket() async {
    _driversSub?.cancel();
    _errorSub?.cancel();
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();

    _driversSub = _socket.nearbyDriversStream.listen((drivers) {
      if (drivers.isEmpty) {
        driverMarkerPoints.clear();
      } else {
        driverMarkerPoints.assignAll(drivers.map((d) => LatLng(d.lat, d.lng)));
      }
      nearbyDriverCount.value = drivers.length;
      lastSocketError.value = '';
    });

    _errorSub = _socket.errorStream.listen((msg) {
      lastSocketError.value = msg;
    });

    _connectionSub = _socket.connectionStream.listen((ok) {
      isSocketConnected.value = ok;
      if (ok) {
        if (rideId.isNotEmpty) {
          _socket.joinRideRoom(rideId: rideId);
        }
        _emitNearbyDriversAllTypes();
      }
    });

    _rideStatusSub = _socket.rideStatusStream.listen(_onRideStatus);

    _driverLocSub = _socket.rideDriverLocationStream.listen((payload) {
      final lat = (payload['lat'] as num?)?.toDouble();
      final lng = (payload['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        assignedDriverLocation.value = LatLng(lat, lng);
      }
    });

    await _socket.connect();
    if (rideId.isNotEmpty) {
      _socket.joinRideRoom(rideId: rideId);
    }
    _emitNearbyDriversAllTypes();

    _nearbyRefreshTimer?.cancel();
    _nearbyRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (isSocketConnected.value) _emitNearbyDriversAllTypes();
    });
  }

  /// Same as vehicle selection when `vehicle_type` is omitted — all vehicle types.
  void _emitNearbyDriversAllTypes() {
    _socket.requestNearbyDrivers(
      lat: pickupLatLng.latitude,
      lng: pickupLatLng.longitude,
      vehicleType: null,
      radiusKm: 3,
    );
  }

  void _onRideStatus(Map<String, dynamic> event) {
    final status = (event['status'] ?? '').toString().toLowerCase();
    ridePhase.value = status.isEmpty ? ridePhase.value : status;

    if (status == 'driver_assigned') {
      Get.snackbar('Driver found', 'A driver has been assigned to your ride.');
      // TODO(SCR-11): Get.offNamed(AppRoutes.driverAccepted, arguments: { 'rideId': rideId, ... });
    } else if (status == 'no_driver_found') {
      final msg = (event['message'] as String?)?.trim() ??
          'No drivers available. Try again later.';
      Get.dialog<void>(
        AlertDialog(
          title: const Text('No drivers'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.offAllNamed(AppRoutes.home);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (status == 'cancelled') {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    c.animateCamera(
      CameraUpdate.newLatLngZoom(pickupLatLng, 15),
    );
  }

  void recenterMap() {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(pickupLatLng, 15),
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

    final result = await rideRepository.cancelRide(rideId, 'rider_cancelled');
    result.fold(
      (f) => Get.snackbar('Cancel failed', 'Could not cancel. Try again.'),
      (success) {
        if (success) {
          Get.offAllNamed(AppRoutes.home);
        } else {
          Get.snackbar('Cancel failed', 'Please try again.');
        }
      },
    );
  }
}
