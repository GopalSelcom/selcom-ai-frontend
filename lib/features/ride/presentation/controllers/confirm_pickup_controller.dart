import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../home/domain/repositories/home_repository.dart';

class ConfirmPickupController extends GetxController {
  ConfirmPickupController({required this.homeRepository});

  final HomeRepository homeRepository;
  final selectedLatLng = const LatLng(-6.7924, 39.2083).obs;
  final address = ''.obs;
  final isResolvingAddress = false.obs;
  final isSubmitting = false.obs;
  late LatLng _initialLatLng;
  late String initialAddress;

  GoogleMapController? mapController;
  LatLng get initialLatLng => _initialLatLng;

  bool get hasMovedFromInitial =>
      (selectedLatLng.value.latitude - _initialLatLng.latitude).abs() >
          0.000001 ||
      (selectedLatLng.value.longitude - _initialLatLng.longitude).abs() >
          0.000001;

  @override
  void onInit() {
    super.onInit();
    final raw = Get.arguments;
    final args = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final lat = (args['pickupLat'] as num?)?.toDouble() ?? -6.7924;
    final lng = (args['pickupLng'] as num?)?.toDouble() ?? 39.2083;
    selectedLatLng.value = LatLng(lat, lng);
    _initialLatLng = LatLng(lat, lng);
    initialAddress =
        (args['pickupAddress'] as String?)?.trim() ?? 'Selected pickup point';
    address.value = initialAddress;
  }

  Future<void> onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    await controller.animateCamera(
      CameraUpdate.newLatLng(selectedLatLng.value),
    );
  }

  void onCameraMove(CameraPosition position) {
    selectedLatLng.value = position.target;
  }

  Future<void> onCameraIdle() async {
    // Keep the initially selected pickup address on first paint.
    if (!hasMovedFromInitial) return;

    final lat = selectedLatLng.value.latitude;
    final lng = selectedLatLng.value.longitude;
    isResolvingAddress.value = true;
    final result = await homeRepository.reverseGeocode(lat: lat, lng: lng);
    isResolvingAddress.value = false;

    result.fold((_) {}, (data) {
      final results = data.data?.results;
      final nextAddress = (results != null && results.isNotEmpty)
          ? results.first.formattedAddress
          : null;
      if (nextAddress != null && nextAddress.trim().isNotEmpty) {
        address.value = nextAddress.trim();
      }
    });
  }

  Future<void> confirmPickup() async {
    isSubmitting.value = true;
    Get.back(
      result: {
        'pickupLat': selectedLatLng.value.latitude,
        'pickupLng': selectedLatLng.value.longitude,
        'pickupAddress': address.value.trim().isEmpty
            ? 'Selected pickup point'
            : address.value.trim(),
      },
    );
    isSubmitting.value = false;
  }
}
