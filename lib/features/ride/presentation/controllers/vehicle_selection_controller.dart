import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/ride_repository.dart';

/// SCR-09 — vehicle + fare selection. Uses estimate + payment APIs with dummy map fallbacks.
class VehicleSelectionController extends GetxController {
  VehicleSelectionController({
    required this.homeRepository,
    required this.profileRepository,
    required this.rideRepository,
  });

  final HomeRepository homeRepository;
  final ProfileRepository profileRepository;
  final RideRepository rideRepository;

  final estimates = <FareEstimateItem>[].obs;
  final paymentMethods = <PaymentMethodModel>[].obs;
  final selectedVehicleIndex = 0.obs;
  final Rxn<PaymentMethodModel> selectedPayment = Rxn<PaymentMethodModel>();
  final isLoadingEstimates = true.obs;
  final isLoadingPayments = true.obs;
  final isBooking = false.obs;
  final isLoadingNearbyDrivers = false.obs;
  final isSocketConnected = false.obs;
  final lastSocketError = ''.obs;
  final nearbyDriverCount = 0.obs;

  /// Full route for polyline (dummy or API).
  final routePoints = <LatLng>[].obs;

  /// Nearby “driver” markers (dummy positions along/near route).
  final driverMarkerPoints = <LatLng>[].obs;

  late LocationEntity pickupEntity;
  late LocationEntity destinationEntity;

  String? _preferredVehicleTypeId;
  String? _preferredVehicleName;

  final AppSocketService _socketService = AppSocketService();
  StreamSubscription<List<NearbyDriverPoint>>? _nearbyDriversSub;
  StreamSubscription<String>? _nearbyDriversErrorSub;
  StreamSubscription<bool>? _nearbyDriversConnectionSub;

  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    _parseArguments();
    _initNearbyDriversSocket();
    _loadAll();
  }

  @override
  void onClose() {
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    _nearbyDriversConnectionSub?.cancel();
    _socketService.dispose();
    super.onClose();
  }

  void _parseArguments() {
    final raw = Get.arguments;
    final args = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    final pickupAddr = (args['pickup'] as String?)?.trim() ?? '';
    final destAddr = (args['destination'] as String?)?.trim() ?? '';

    final pLat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
    final pLng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
    final dLat = (args['destinationLat'] as num?)?.toDouble() ?? (pLat - 0.018);
    final dLng = (args['destinationLng'] as num?)?.toDouble() ?? (pLng + 0.014);

    pickupEntity = LocationEntity(lat: pLat, lng: pLng, address: pickupAddr);
    destinationEntity = LocationEntity(lat: dLat, lng: dLng, address: destAddr);

    _preferredVehicleTypeId =
        (args['preferredVehicleTypeId'] as String?)?.trim();
    _preferredVehicleName =
        (args['preferredVehicleName'] as String?)?.trim().toLowerCase();

    // Show a route immediately; replaced when fare API returns geometry.
    _buildDummyRoute(pLat, pLng, dLat, dLng);
  }

  void _buildDummyRoute(double pLat, double pLng, double dLat, double dLng) {
    final pts = <LatLng>[];
    const steps = 32;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = pLat + (dLat - pLat) * t + 0.002 * (t - 0.5) * (t - 0.5);
      final lng = pLng + (dLng - pLng) * t + 0.0015 * (t - 0.3);
      pts.add(LatLng(lat, lng));
    }
    routePoints.assignAll(pts);

    driverMarkerPoints.assignAll([
      pts[(steps * 0.25).round()],
      pts[(steps * 0.55).round()],
      pts[(steps * 0.78).round()],
    ]);
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadEstimates(), _loadPaymentMethods()]);
  }

  Future<void> _loadEstimates() async {
    isLoadingEstimates.value = true;
    final req = FareEstimateRequest(pickup: pickupEntity, destination: destinationEntity);

    final vehicleTypesResult = await homeRepository.getVehicleTypes();
    List<VehicleTypeModel> vehicleTypes = [];
    vehicleTypesResult.fold((_) {}, (list) => vehicleTypes = list);

    final result = await homeRepository.estimateFare(req);
    result.fold(
      (_) => estimates.assignAll(_dummyEstimates(vehicleTypes)),
      (model) {
        if (model.estimates.isEmpty) {
          estimates.assignAll(_dummyEstimates(vehicleTypes));
        } else {
          final normalized = model.estimates
              .map((e) => _withResolvedVehicleTypeId(e, vehicleTypes))
              .toList();
          estimates.assignAll(normalized);
          if (model.routeGeometry?.coordinates != null &&
              model.routeGeometry!.coordinates!.isNotEmpty) {
            final coords = model.routeGeometry!.coordinates!;
            final mapped = coords
                .map((c) {
                  if (c.length >= 2) return LatLng(c[1], c[0]);
                  return null;
                })
                .whereType<LatLng>()
                .toList();
            if (mapped.length >= 2) {
              routePoints.assignAll(mapped);
              final n = mapped.length;
              driverMarkerPoints.assignAll([
                mapped[(n * 0.25).floor().clamp(0, n - 1)],
                mapped[(n * 0.55).floor().clamp(0, n - 1)],
                mapped[(n * 0.78).floor().clamp(0, n - 1)],
              ]);
            }
          }
        }
      },
    );
    isLoadingEstimates.value = false;
    _applyPreferredVehicleSelection();
    _requestNearbyDriversForCurrentSelection();
    Future.microtask(_fitBounds);
  }

  /// Backend expects `vehicle_type_id` as the catalog id (e.g. Mongo `_id`), not a slug like `cab`.
  bool _looksLikeBackendVehicleTypeId(String? s) {
    final t = (s ?? '').trim();
    if (t.isEmpty) return false;
    if (t.length == 24 && RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(t)) return true;
    if (t.length == 36 && t.contains('-')) return true;
    return false;
  }

  VehicleTypeModel? _matchVehicleTypeFromEstimate(
    FareEstimateItem e,
    List<VehicleTypeModel> types,
  ) {
    final id = (e.vehicleTypeId ?? '').trim();
    final vn = (e.vehicleName ?? '').trim().toLowerCase();
    final dn = (e.displayName ?? '').trim().toLowerCase();
    for (final vt in types) {
      if (id.isNotEmpty && vt.id == id) return vt;
      if (id.isNotEmpty && vt.id.isNotEmpty && vt.key.toLowerCase() == id.toLowerCase()) {
        return vt;
      }
      if (id.isNotEmpty && vt.name.toLowerCase() == id.toLowerCase()) return vt;
      if (vn.isNotEmpty && vt.key.toLowerCase() == vn) return vt;
      if (vn.isNotEmpty && vt.name.toLowerCase() == vn) return vt;
      if (dn.isNotEmpty && vt.displayName.toLowerCase() == dn) return vt;
    }
    return null;
  }

  FareEstimateItem _withResolvedVehicleTypeId(
    FareEstimateItem e,
    List<VehicleTypeModel> types,
  ) {
    if (types.isEmpty) return e;
    final raw = (e.vehicleTypeId ?? '').trim();
    if (raw.isNotEmpty && _looksLikeBackendVehicleTypeId(raw)) {
      final exists = types.any((vt) => vt.id == raw);
      if (exists) return e;
    }
    final matched = _matchVehicleTypeFromEstimate(e, types);
    if (matched == null) return e;
    if (matched.id == raw) return e;
    return FareEstimateItem(
      vehicleTypeId: matched.id,
      vehicleName: e.vehicleName ?? matched.name,
      displayName: e.displayName ?? matched.displayName,
      fareEstimate: e.fareEstimate,
      distanceKm: e.distanceKm,
      durationMinutes: e.durationMinutes,
      baseFare: e.baseFare,
      perKmCharge: e.perKmCharge,
      perMinCharge: e.perMinCharge,
      minimumFare: e.minimumFare,
      maxPassengers: e.maxPassengers ?? matched.maxPassengers,
      currency: e.currency,
    );
  }

  void _applyPreferredVehicleSelection() {
    if (estimates.isEmpty) return;
    final id = _preferredVehicleTypeId;
    if (id != null && id.isNotEmpty) {
      final byId = estimates.indexWhere(
        (e) =>
            e.vehicleTypeId == id ||
            (e.vehicleName != null && e.vehicleName == id),
      );
      if (byId >= 0) {
        selectedVehicleIndex.value = byId;
        return;
      }
    }
    final name = _preferredVehicleName;
    if (name != null && name.isNotEmpty) {
      final byName = estimates.indexWhere((e) {
        final vn = (e.vehicleName ?? '').toLowerCase();
        final dn = (e.displayName ?? '').toLowerCase();
        return vn.contains(name) ||
            name.contains(vn) ||
            dn.contains(name) ||
            name.contains(dn);
      });
      if (byName >= 0) selectedVehicleIndex.value = byName;
    }
  }

  /// Fallback rows when estimate API fails; uses real `VehicleTypeModel.id` from `getVehicleTypes()`.
  List<FareEstimateItem> _dummyEstimates(List<VehicleTypeModel> types) {
    final sorted = (types.where((t) => t.isActive).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
    final list = sorted.isNotEmpty ? sorted : types;
    if (list.isEmpty) {
      return [
        FareEstimateItem(
          vehicleTypeId: '',
          vehicleName: 'ride',
          displayName: 'Ride',
          fareEstimate: 500,
          distanceKm: 4.2,
          durationMinutes: 10,
          maxPassengers: 4,
          currency: 'TZS',
        ),
      ];
    }
    return list.map((vt) {
      final fare = vt.baseFare > 0 ? vt.baseFare : 500;
      return FareEstimateItem(
        vehicleTypeId: vt.id,
        vehicleName: vt.name,
        displayName: vt.displayName.isNotEmpty ? vt.displayName : vt.name,
        fareEstimate: fare,
        distanceKm: 4.2,
        durationMinutes: 10,
        maxPassengers: vt.maxPassengers,
        currency: 'TZS',
      );
    }).toList();
  }

  Future<void> _loadPaymentMethods() async {
    isLoadingPayments.value = true;
    final result = await profileRepository.getPaymentMethods();
    result.fold(
      (_) => paymentMethods.assignAll(_dummyPayments()),
      (list) {
        if (list.isEmpty) {
          paymentMethods.assignAll(_dummyPayments());
        } else {
          paymentMethods.assignAll(list);
        }
      },
    );
    selectedPayment.value ??= paymentMethods.isNotEmpty ? paymentMethods.first : null;
    isLoadingPayments.value = false;
  }

  List<PaymentMethodModel> _dummyPayments() {
    return [
      PaymentMethodModel(id: 'wallet', label: 'Wallet', type: 'wallet'),
      PaymentMethodModel(id: 'card', label: 'Mastercard / Visa', type: 'card'),
      PaymentMethodModel(id: 'selcom_pesa', label: 'Selcom Pesa', type: 'selcom_pesa'),
    ];
  }

  FareEstimateItem? get selectedEstimate {
    if (estimates.isEmpty) return null;
    final i = selectedVehicleIndex.value.clamp(0, estimates.length - 1);
    return estimates[i];
  }

  int get selectedFareAmount => selectedEstimate?.fareEstimate ?? 0;

  String get currency => selectedEstimate?.currency ?? 'TZS';

  void selectVehicle(int index) {
    if (index < 0 || index >= estimates.length) return;
    selectedVehicleIndex.value = index;
    _requestNearbyDriversForCurrentSelection();
  }

  void selectPaymentMethod(PaymentMethodModel m) {
    selectedPayment.value = m;
  }

  String? _extractRideIdFromBookingResponse(Map<String, dynamic> raw) {
    String? pick(Map<String, dynamic> m) {
      final v = m['ride_id'] ?? m['_id'] ?? m['id'] ?? m['rideId'];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
      return null;
    }

    final direct = pick(raw);
    if (direct != null) return direct;
    final ride = raw['ride'];
    if (ride is Map) return pick(Map<String, dynamic>.from(ride));
    final data = raw['data'];
    if (data is Map) return pick(Map<String, dynamic>.from(data));
    return null;
  }

  Future<void> bookRide() async {
    final est = selectedEstimate;
    final pay = selectedPayment.value;
    if (est == null || pay == null) {
      Get.snackbar('Missing info', 'Select a vehicle and payment method.');
      return;
    }

    isBooking.value = true;

    final resolvedVehicleTypeId = (est.vehicleTypeId ?? '').trim();
    if (resolvedVehicleTypeId.isEmpty || !_looksLikeBackendVehicleTypeId(resolvedVehicleTypeId)) {
      isBooking.value = false;
      Get.snackbar(
        'Vehicle type',
        'Could not resolve vehicle type id. Please try again.',
      );
      return;
    }

    // 1) Validate payment first (Validate Ride Payment - Block).
    final validateRequest = ValidateRidePaymentRequest(
      fareEstimate: est.fareEstimate ?? selectedFareAmount,
      paymentMethod: pay.type,
      vehicleTypeId: resolvedVehicleTypeId,
    );
    final validationResult = await rideRepository.validateRidePayment(validateRequest);

    await validationResult.fold(
      (f) async {
        isBooking.value = false;
        Get.snackbar(
          'Payment validation failed',
          'Could not validate payment. Please try again.',
        );
      },
      (validationId) async {
        if (validationId.trim().isEmpty) {
          isBooking.value = false;
          Get.snackbar(
            'Payment validation failed',
            'Validation id missing from server response.',
          );
          return;
        }

        // Join payment room and wait for block callback before booking.
        if (!_socketService.isConnected) {
          await _socketService.connect();
        }
        _socketService.joinPaymentRoom(validationId: validationId);
        _showPaymentPendingDialog();
        final blockOk = await _waitForPaymentBlockStatus(
          timeout: const Duration(minutes: 2),
        );
        _closePaymentPendingDialogIfOpen();
        if (!blockOk) {
          isBooking.value = false;
          Get.snackbar(
            'Payment not confirmed',
            'We could not confirm your payment block. Please try again.',
          );
          return;
        }

        // 2) Only after validation, submit ride booking.
        final request = BookRideRequest(
          validationId: validationId,
          idempotencyKey: 'idem_${DateTime.now().millisecondsSinceEpoch}',
          pickup: pickupEntity,
          destination: destinationEntity,
          vehicleTypeId: resolvedVehicleTypeId,
          paymentMethod: pay.type,
        );
        final result = await homeRepository.bookRide(request);
        isBooking.value = false;
        result.fold(
          (f) => Get.snackbar('Booking failed', 'Could not complete booking. Try again.'),
          (data) {
            final rideId = _extractRideIdFromBookingResponse(data);
            if (rideId == null || rideId.isEmpty) {
              Get.snackbar('Booking', 'Ride was created but ride id is missing from the response.');
              Get.back();
              return;
            }
            Get.offNamed(
              AppRoutes.findingDriver,
              arguments: {
                'rideId': rideId,
                'pickupLat': pickupEntity.lat,
                'pickupLng': pickupEntity.lng,
                'pickupAddress': pickupEntity.address,
                'destinationAddress': destinationEntity.address,
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _waitForPaymentBlockStatus({
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final completer = Completer<bool>();
    late StreamSubscription<Map<String, dynamic>> sub;

    sub = _socketService.paymentStatusStream.listen((event) {
      final outcome = _paymentBlockOutcome(event);
      if (outcome == null) return;
      if (!completer.isCompleted) completer.complete(outcome);
    });

    try {
      return await completer.future.timeout(
        timeout,
        onTimeout: () => false,
      );
    } finally {
      await sub.cancel();
    }
  }

  bool? _paymentBlockOutcome(Map<String, dynamic> event) {
    final phase = (event['phase'] ?? '').toString().toLowerCase();
    final status = (event['status'] ?? '').toString().toLowerCase();

    // Accept both documented shapes:
    // - { phase: "block", status: "confirmed|failed" }
    // - { status: "completed|failed" } (without phase)
    if (phase.isNotEmpty && phase != 'block') return null;

    if (status == 'confirmed' || status == 'completed' || status == 'success') {
      return true;
    }
    if (status == 'failed' || status == 'error' || status == 'declined') {
      return false;
    }
    return null;
  }

  void _showPaymentPendingDialog() {
    if (Get.isDialogOpen == true) return;
    Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 132,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6DCCD),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 44),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Request sent. Please complete payment on Selcom Pesa to book your ride.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Metropolis',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF132235),
                    height: 1.3,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: StreamBuilder<int>(
                  stream: Stream<int>.periodic(
                    const Duration(seconds: 1),
                    (tick) => (120 - tick).clamp(0, 120),
                  ).take(121),
                  initialData: 120,
                  builder: (context, snapshot) {
                    final secLeft = snapshot.data ?? 120;
                    return Text(
                      'Expire in ${_formatTimer(secLeft)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Metropolis',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF364B63),
                        height: 1.33,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _closePaymentPendingDialogIfOpen() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString();
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _initNearbyDriversSocket() async {
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    _nearbyDriversConnectionSub?.cancel();

    _nearbyDriversSub = _socketService.nearbyDriversStream.listen((drivers) {
      if (drivers.isEmpty) {
        driverMarkerPoints.clear();
      } else {
        driverMarkerPoints.assignAll(
          drivers.map((d) => LatLng(d.lat, d.lng)),
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
    _nearbyDriversConnectionSub = _socketService.connectionStream.listen((ok) {
      isSocketConnected.value = ok;
      if (!ok) {
        isLoadingNearbyDrivers.value = false;
      }
    });

    await _socketService.connect();
    _requestNearbyDriversForCurrentSelection();
  }

  void _requestNearbyDriversForCurrentSelection() {
    if (pickupEntity.lat == 0 || pickupEntity.lng == 0) return;
    isLoadingNearbyDrivers.value = true;
    if (!isSocketConnected.value) {
      lastSocketError.value = 'Connecting socket...';
    }
    final vehicleType = _socketVehicleTypeForEstimate(selectedEstimate);
    _socketService.requestNearbyDrivers(
      lat: pickupEntity.lat,
      lng: pickupEntity.lng,
      vehicleType: vehicleType,
      radiusKm: 3,
    );
  }

  String? _socketVehicleTypeForEstimate(FareEstimateItem? item) {
    if (item == null) return null;
    final raw = '${item.vehicleName ?? ''} ${item.displayName ?? ''}'.toLowerCase();
    if (raw.contains('boda') || raw.contains('bike') || raw.contains('moto')) return 'Bike';
    if (raw.contains('bajaj') || raw.contains('auto') || raw.contains('three')) {
      return 'Three_Wheeler';
    }
    if (raw.contains('van')) return 'Van';
    if (raw.contains('cab') || raw.contains('car') || raw.contains('goride')) return 'Car';
    return null; // omit vehicle_type => server returns all types
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitBounds();
  }

  Future<void> _fitBounds() async {
    if (mapController == null) return;
    final pts = routePoints.isNotEmpty
        ? routePoints.toList()
        : <LatLng>[
            LatLng(pickupEntity.lat, pickupEntity.lng),
            LatLng(destinationEntity.lat, destinationEntity.lng),
          ];
    if (pts.isEmpty) return;
    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        48,
      ),
    );
  }

}
