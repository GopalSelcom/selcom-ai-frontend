import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/core/utils/map_marker_utils.dart';

import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import '../../../../core/data/models/responses/payment_status_response/payment_status_response.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../payment/presentation/widgets/payment_status_dialog.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../payment/presentation/controllers/payment_method_controller.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/ride_repository.dart';

/// SCR-09 — vehicle + fare selection.
class VehicleSelectionController extends GetxController {
  VehicleSelectionController({
    required this.homeRepository,
    required this.profileRepository,
    required this.rideRepository,
    required this.paymentMethodController,
  });

  final HomeRepository homeRepository;
  final ProfileRepository profileRepository;
  final RideRepository rideRepository;
  final PaymentMethodController paymentMethodController;

  final estimates = <FareEstimateItem>[].obs;
  final selectedVehicleIndex = 0.obs;
  final isLoadingEstimates = true.obs;
  final isBooking = false.obs;
  final isLoadingNearbyDrivers = false.obs;
  final isSocketConnected = false.obs;
  final lastSocketError = ''.obs;
  final nearbyDriverCount = 0.obs;
  final paymentStatus = PaymentStatus.pending.obs;
  final paymentTimerSeconds = 120.obs;
  final isRouteReady = false.obs;
  final isLocationIconsReady = false.obs;
  final isMapVisualReady = false.obs;

  /// Full route for polyline (API).
  final routePoints = <LatLng>[].obs;

  /// Nearby “driver” markers (dummy positions along/near route).
  final driverMarkerPoints = <LatLng>[].obs;

  late LocationEntity pickupEntity;
  late LocationEntity destinationEntity;
  final destinations = <LocationEntity>[].obs;

  String? _preferredVehicleTypeId;
  String? _preferredVehicleName;
  final _vehicleTypes = <VehicleTypeModel>[];

  AppSocketService get _socketService => Get.find<AppSocketService>();
  StreamSubscription<List<Driver>>? _nearbyDriversSub;
  StreamSubscription<String>? _nearbyDriversErrorSub;
  StreamSubscription<bool>? _nearbyDriversConnectionSub;

  GoogleMapController? mapController;

  BitmapDescriptor? driverIcon;
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropIcon;
  final stopIcons = <BitmapDescriptor>[].obs;

  @override
  void onInit() {
    super.onInit();
    _parseArguments();
    loadLocationIcons();
    _initNearbyDriversSocket();
    _loadAll();
  }

  @override
  void onClose() {
    _nearbyDriversSub?.cancel();
    _nearbyDriversErrorSub?.cancel();
    _nearbyDriversConnectionSub?.cancel();
    super.onClose();
  }

  void _parseArguments() {
    final raw = Get.arguments;
    if (kDebugMode) {
      debugPrint('[VehicleSelection] Raw Get.arguments => $raw');
    }

    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    if (args.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[VehicleSelection] WARNING: Arguments are empty or not a Map.',
        );
      }
    }

    final pickupAddr = (args['pickup'] as String?)?.trim() ?? '';
    final pLat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
    final pLng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
    pickupEntity = LocationEntity(lat: pLat, lng: pLng, address: pickupAddr);

    final List<dynamic>? ds = args['destinations'];
    if (ds != null && ds.isNotEmpty) {
      destinations.assignAll(ds.cast<LocationEntity>());
      destinationEntity = destinations.last;
    } else {
      // Legacy support
      final destAddr = (args['destination'] as String?)?.trim() ?? '';
      final dLat =
          (args['destinationLat'] as num?)?.toDouble() ?? (pLat - 0.018);
      final dLng =
          (args['destinationLng'] as num?)?.toDouble() ?? (pLng + 0.014);
      destinationEntity = LocationEntity(
        lat: dLat,
        lng: dLng,
        address: destAddr,
      );
      destinations.assignAll([destinationEntity]);
    }

    if (kDebugMode) {
      debugPrint(
        '[VehicleSelection] Parsed args => '
        'pickup=(${pickupEntity.lat},${pickupEntity.lng}), '
        'destinationsCount=${destinations.length}, '
        'finalDestination=(${destinationEntity.lat},${destinationEntity.lng})',
      );
    }

    _preferredVehicleTypeId = (args['preferredVehicleTypeId'] as String?)
        ?.trim();
    _preferredVehicleName = (args['preferredVehicleName'] as String?)
        ?.trim()
        .toLowerCase();

    isRouteReady.value = false;
  }

  Future<void> _loadAll() async {
    await _loadEstimates();
  }

  Future<void> _loadEstimates() async {
    isLoadingEstimates.value = true;
    isRouteReady.value = false;
    routePoints.clear();
    driverMarkerPoints.clear();
    final req = FareEstimateRequest(
      pickup: pickupEntity,
      destinations: destinations.toList(),
    );

    final vehicleTypesResult = await homeRepository.getVehicleTypes();
    List<VehicleTypeModel> vehicleTypes = [];
    vehicleTypesResult.fold((_) {}, (list) => vehicleTypes = list);
    _vehicleTypes
      ..clear()
      ..addAll(vehicleTypes);

    final result = await homeRepository.estimateFare(req);
    result.fold(
      (f) {
        if (kDebugMode)
          debugPrint('[VehicleSelection] Fare estimate error: $f');
        estimates.assignAll(_dummyEstimates(vehicleTypes));
        isRouteReady.value = false;
      },
      (model) {
        if (kDebugMode) {
          debugPrint(
            '[VehicleSelection] Fare estimate success => '
            'estimates=${model.estimates.length}, '
            'routeGeometry=${model.routeGeometry != null}, '
            'points=${model.routeGeometry?.coordinates?.length ?? 0}',
          );
        }
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
              isRouteReady.value = true;
              if (kDebugMode) {
                debugPrint(
                  '[VehicleSelection] API route geometry applied => '
                  'points=${mapped.length}, '
                  'first=${mapped.first.latitude},${mapped.first.longitude}, '
                  'last=${mapped.last.latitude},${mapped.last.longitude}',
                );
              }
              final n = mapped.length;
              driverMarkerPoints.assignAll([
                mapped[(n * 0.25).floor().clamp(0, n - 1)],
                mapped[(n * 0.55).floor().clamp(0, n - 1)],
                mapped[(n * 0.78).floor().clamp(0, n - 1)],
              ]);
            } else {
              _useStraightLineFallback();
            }
          } else {
            _useStraightLineFallback();
          }
        }
      },
    );
    isLoadingEstimates.value = false;
    _applyPreferredVehicleSelection();

    if (estimates.isNotEmpty) {
      await loadDriverIcon();
    }

    _requestNearbyDriversForCurrentSelection();
    Future.microtask(_fitBounds);
  }

  void _useStraightLineFallback() {
    final list = [
      LatLng(pickupEntity.lat, pickupEntity.lng),
      ...destinations.map((d) => LatLng(d.lat, d.lng)),
    ];
    routePoints.assignAll(list);
    isRouteReady.value = true;
    if (kDebugMode) {
      debugPrint(
        '[VehicleSelection] Using straight-line fallback for routePoints.',
      );
    }
  }

  Future<void> loadDriverIcon() async {
    driverIcon = await MapMarkerUtils.getResizedMarker(
      vehicleImage(estimates[selectedVehicleIndex.value]),
      150,
    );
  }

  Future<void> loadLocationIcons() async {
    try {
      final bool isMulti = destinations.length > 1;

      if (!isMulti) {
        // Single Stop: P (Blue) and D (Green)
        pickupIcon = await MapMarkerUtils.createTextMarker(
          text: 'P',
          color: const Color(0xFF4FA3FF),
        );
        dropIcon = await MapMarkerUtils.createTextMarker(
          text: 'D',
          color: const Color(0xFF34C759), // Green for Destination
        );
        stopIcons.clear();
      } else {
        // Multi Stop: A (Blue), B, C... (Red), Last Letter (Green)
        const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
        pickupIcon = await MapMarkerUtils.createTextMarker(
          text: 'A',
          color: const Color(0xFF4FA3FF),
        );

        stopIcons.clear();
        // Generate all possible intermediate letters as Red
        for (int i = 1; i < letters.length; i++) {
          final icon = await MapMarkerUtils.createTextMarker(
            text: letters[i],
            color: const Color(0xFFE11D48), // Red for Intermediate Stops
          );
          stopIcons.add(icon);
        }

        // Destination letter (Green)
        final destIndex = destinations.length; // If 2 drops, index is 2 (C)
        final label = (destIndex < letters.length)
            ? letters[destIndex]
            : letters.last;
        dropIcon = await MapMarkerUtils.createTextMarker(
          text: label,
          color: const Color(0xFF34C759), // Green for Destination
        );
      }
    } catch (e) {
      if (kDebugMode)
        debugPrint('[VehicleSelection] Error loading markers: $e');
    }
    isLocationIconsReady.value =
        pickupIcon != null && dropIcon != null && stopIcons.isNotEmpty;
  }

  bool get isMapDataReady => isRouteReady.value && routePoints.length >= 2;

  String vehicleImage(FareEstimateItem e) {
    final n = '${e.vehicleName ?? ''} ${e.displayName ?? ''}'.toLowerCase();
    if (n.contains('boda') || n.contains('bike') || n.contains('moto')) {
      return AppAssets.imgBoda;
    }
    if (n.contains('bajaj') || n.contains('auto')) return AppAssets.imgBajaji;
    return AppAssets.imgCab;
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
      if (id.isNotEmpty &&
          vt.id.isNotEmpty &&
          vt.key.toLowerCase() == id.toLowerCase()) {
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

  FareEstimateItem? get selectedEstimate {
    if (estimates.isEmpty) return null;
    final i = selectedVehicleIndex.value.clamp(0, estimates.length - 1);
    return estimates[i];
  }

  int get selectedFareAmount => selectedEstimate?.fareEstimate ?? 0;

  String get currency => selectedEstimate?.currency ?? 'TZS';

  Future<void> selectVehicle(int index) async {
    if (index < 0 || index >= estimates.length) return;
    selectedVehicleIndex.value = index;
    await loadDriverIcon();
    _requestNearbyDriversForCurrentSelection();
  }

  Future<void> bookRide() async {
    if (isBooking.value) return;

    final est = selectedEstimate;
    final pay = paymentMethodController.selectedPayment.value;
    if (est == null || pay == null) {
      Get.snackbar('Missing info', 'Select a vehicle and payment method.');
      return;
    }

    isBooking.value = true;
    try {
      final resolvedVehicleTypeId = (est.vehicleTypeId ?? '').trim();
      if (resolvedVehicleTypeId.isEmpty ||
          !_looksLikeBackendVehicleTypeId(resolvedVehicleTypeId)) {
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
      final validationResult = await rideRepository.validateRidePayment(
        validateRequest,
      );

      await validationResult.fold(
        (f) async {
          Get.snackbar(
            'Payment validation failed',
            'Could not validate payment. Please try again.',
          );
        },
        (validationId) async {
          if (validationId.trim().isEmpty) {
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
          String txnId = generateTransactionId();

          rideRepository.walletDummyPaymentRequest(
            DummyPaymentRequest(
              result: "SUCCESS",
              transId: txnId,
              validationId: validationId,
            ),
          );
          _showPaymentStatusDialog();

          final blockOk = await _waitForPaymentBlockStatus(
            timeout: const Duration(minutes: 2),
          );

          if (blockOk) {
            paymentStatus.value = PaymentStatus.success;
            await Future.delayed(const Duration(seconds: 2));
          }

          _closePaymentStatusDialogIfOpen();
          if (!blockOk) {
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
            destinations: destinations.toList(),
            vehicleTypeId: resolvedVehicleTypeId,
            paymentMethod: pay.type,
          );
          final result = await homeRepository.bookRide(request);
          result.fold(
            (f) {
              // Clean the message if it contains "Exception: "
              String msg = f.message;
              if (msg.startsWith('Exception: ')) {
                msg = msg.replaceFirst('Exception: ', '');
              }
              Get.snackbar(
                'Booking failed',
                msg,
                backgroundColor: Colors.black87,
                colorText: Colors.white,
              );
            },
            (data) {
              final rideId = data.data?.ride?.id;
              if (rideId == null || rideId.isEmpty) {
                Get.snackbar(
                  'Booking',
                  data.message ??
                      'Ride was created but ride id is missing from the response.',
                  backgroundColor: Colors.black87,
                  colorText: Colors.white,
                );
                return;
              }
              Get.offNamed(
                AppRoutes.findingDriver,
                arguments: {
                  'rideId': rideId,
                  'vehicleType': _socketVehicleTypeForEstimate(est),
                  'pickupLat': pickupEntity.lat,
                  'pickupLng': pickupEntity.lng,
                  'pickupAddress': pickupEntity.address,
                  'destinationLat': destinationEntity.lat,
                  'destinationLng': destinationEntity.lng,
                  'destinationAddress': destinationEntity.address,
                  'fareBreakdown': data.data?.ride?.fareBreakdown?.toJson(),
                },
              );
            },
          );
        },
      );
    } finally {
      // Small delay to ensure snackbars or navigation have time to settle if needed,
      // but primarily just reset the booking state.
      isBooking.value = false;
    }
  }

  String generateTransactionId() {
    final random = Random();
    int randomNumber = random.nextInt(100000); // 0 to 99999

    // pad with leading zeros if needed
    String formattedNumber = randomNumber.toString().padLeft(5, '0');

    return 'DEV-BLOCK-$formattedNumber';
  }

  Future<bool> _waitForPaymentBlockStatus({
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final completer = Completer<bool>();
    late StreamSubscription<PaymentStatusUpdateResponse> sub;

    sub = _socketService.paymentStatusStream.listen((event) {
      final outcome = _paymentBlockOutcome(event);
      if (outcome == null) return;
      if (!completer.isCompleted) completer.complete(outcome);
    });

    try {
      return await completer.future.timeout(timeout, onTimeout: () => false);
    } finally {
      await sub.cancel();
    }
  }

  bool? _paymentBlockOutcome(PaymentStatusUpdateResponse event) {
    final phase = (event.phase ?? '').toString().toLowerCase();
    final status = (event.status ?? '').toString().toLowerCase();

    // Accept both documented shapes:
    // - { phase: "block", status: "confirmed|failed" }
    // - { status: "completed|failed" } (without phase)
    if (phase.isNotEmpty && phase != 'block') return null;

    if (status == 'confirmed') {
      return true;
    }
    if (status == 'failed') {
      return false;
    }
    return null;
  }

  void _showPaymentStatusDialog() {
    paymentStatus.value = PaymentStatus.pending;
    paymentTimerSeconds.value = 120;

    if (Get.isDialogOpen == true) return;

    Get.dialog<void>(
      Obx(
        () => PaymentStatusDialog(
          status: paymentStatus.value,
          secondsRemaining: paymentStatus.value == PaymentStatus.pending
              ? paymentTimerSeconds.value
              : null,
        ),
      ),
      barrierDismissible: false,
    );

    // Start local timer for the dialog display
    _startPaymentTimer();
  }

  Timer? _paymentTimer;

  void _startPaymentTimer() {
    _paymentTimer?.cancel();
    _paymentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (paymentTimerSeconds.value <= 0) {
        timer.cancel();
      } else {
        paymentTimerSeconds.value--;
      }
    });
  }

  void _closePaymentStatusDialogIfOpen() {
    _paymentTimer?.cancel();
    if (Get.isDialogOpen == true) {
      Get.back();
    }
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
          drivers.map(
            (d) => LatLng(double.parse(d.lat ?? ""), double.parse(d.lng ?? "")),
          ),
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
      radiusKm: 1000,
    );
  }

  String? _socketVehicleTypeForEstimate(FareEstimateItem? item) {
    if (item == null) return null;

    // Pass API vehicle_types.key directly in socket event payload.
    final estimateTypeId = (item.vehicleTypeId ?? '').trim();
    if (estimateTypeId.isEmpty || _vehicleTypes.isEmpty) {
      return null; // omit vehicle_type if key cannot be resolved
    }

    final matched = _vehicleTypes.firstWhereOrNull(
      (v) => v.id == estimateTypeId,
    );
    final key = matched?.key.trim();
    if (key == null || key.isEmpty) return null;
    return key;
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitBounds();

    // Manage visual readiness with delay similar to old setState logic
    if (!isMapVisualReady.value) {
      Future.delayed(const Duration(milliseconds: 220), () {
        isMapVisualReady.value = true;
      });
    }
  }

  void onCameraIdle() {
    if (!isMapVisualReady.value) {
      isMapVisualReady.value = true;
    }
  }

  Future<void> _fitBounds() async {
    if (mapController == null || routePoints.length < 2) return;
    final pts = routePoints.toList();
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
