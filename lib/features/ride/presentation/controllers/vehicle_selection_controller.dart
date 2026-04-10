import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

/// SCR-09 — vehicle + fare selection. Uses estimate + payment APIs with dummy map fallbacks.
class VehicleSelectionController extends GetxController {
  VehicleSelectionController({
    required this.homeRepository,
    required this.profileRepository,
  });

  final HomeRepository homeRepository;
  final ProfileRepository profileRepository;

  final estimates = <FareEstimateItem>[].obs;
  final paymentMethods = <PaymentMethodModel>[].obs;
  final selectedVehicleIndex = 0.obs;
  final Rxn<PaymentMethodModel> selectedPayment = Rxn<PaymentMethodModel>();
  final isLoadingEstimates = true.obs;
  final isLoadingPayments = true.obs;
  final isBooking = false.obs;

  /// Full route for polyline (dummy or API).
  final routePoints = <LatLng>[].obs;

  /// Nearby “driver” markers (dummy positions along/near route).
  final driverMarkerPoints = <LatLng>[].obs;

  late LocationEntity pickupEntity;
  late LocationEntity destinationEntity;

  String? _preferredVehicleTypeId;
  String? _preferredVehicleName;

  GoogleMapController? mapController;

  @override
  void onInit() {
    super.onInit();
    _parseArguments();
    _loadAll();
  }

  void _parseArguments() {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
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
    final result = await homeRepository.estimateFare(req);
    result.fold(
      (_) => estimates.assignAll(_dummyEstimates()),
      (model) {
        if (model.estimates.isEmpty) {
          estimates.assignAll(_dummyEstimates());
        } else {
          estimates.assignAll(model.estimates);
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
    Future.microtask(_fitBounds);
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

  List<FareEstimateItem> _dummyEstimates() {
    return [
      FareEstimateItem(
        vehicleTypeId: 'cab',
        vehicleName: 'cab',
        displayName: 'GoRide Card',
        fareEstimate: 500,
        distanceKm: 4.2,
        durationMinutes: 10,
        maxPassengers: 4,
        currency: 'TZS',
      ),
      FareEstimateItem(
        vehicleTypeId: 'bajaji',
        vehicleName: 'bajaji',
        displayName: 'Bajaji',
        fareEstimate: 100,
        distanceKm: 4.2,
        durationMinutes: 5,
        maxPassengers: 3,
        currency: 'TZS',
      ),
      FareEstimateItem(
        vehicleTypeId: 'boda',
        vehicleName: 'boda',
        displayName: 'Boda',
        fareEstimate: 100,
        distanceKm: 4.2,
        durationMinutes: 1,
        maxPassengers: 1,
        currency: 'TZS',
      ),
    ];
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
  }

  void selectPaymentMethod(PaymentMethodModel m) {
    selectedPayment.value = m;
  }

  Future<void> bookRide() async {
    final est = selectedEstimate;
    final pay = selectedPayment.value;
    if (est == null || pay == null) {
      Get.snackbar('Missing info', 'Select a vehicle and payment method.');
      return;
    }
    isBooking.value = true;
    final request = BookRideRequest(
      validationId: 'client_preview_${DateTime.now().millisecondsSinceEpoch}',
      idempotencyKey: 'idem_${DateTime.now().millisecondsSinceEpoch}',
      pickup: pickupEntity,
      destination: destinationEntity,
      vehicleTypeId: est.vehicleTypeId ?? 'unknown',
      paymentMethod: pay.type,
    );
    final result = await homeRepository.bookRide(request);
    isBooking.value = false;
    result.fold(
      (f) => Get.snackbar('Booking failed', 'Could not complete booking. Try again.'),
      (data) {
        Get.snackbar('Success', 'Ride request submitted.');
        Get.back();
      },
    );
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitBounds();
  }

  Future<void> _fitBounds() async {
    if (mapController == null || routePoints.isEmpty) return;
    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;
    for (final p in routePoints) {
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
