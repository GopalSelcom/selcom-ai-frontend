import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/services/progress_indicator/loader.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/booking_for_someone_else_flow_bottom_sheet.dart';

enum BookingMode { self, other }

class ConfirmPickupController extends GetxController {
  ConfirmPickupController({
    required this.homeRepository,
    required this.rideRepository,
  });

  final HomeRepository homeRepository;
  final RideRepository rideRepository;
  final selectedLatLng = const LatLng(-6.7924, 39.2083).obs;
  final address = ''.obs;
  final isResolvingAddress = false.obs;
  final isSubmitting = false.obs;

  final bookingMode = BookingMode.self.obs;
  final passengerName = ''.obs;
  final passengerPhone = ''.obs;
  final TextEditingController noteForDriverController = TextEditingController();
  late final VoidCallback _pickupNoteListener;
  late LatLng _initialLatLng;
  late String initialAddress;

  /// Drives Obx for pickup note chip (TextEditingController is not reactive).
  final noteChipRevision = 0.obs;
  final isPickupNoteExpanded = false.obs;

  GoogleMapController? mapController;

  LatLng get initialLatLng => _initialLatLng;
  static const double _pickupMoveThreshold = 0.00005;

  bool get hasMovedFromInitial =>
      (selectedLatLng.value.latitude - _initialLatLng.latitude).abs() >
          _pickupMoveThreshold ||
      (selectedLatLng.value.longitude - _initialLatLng.longitude).abs() >
          _pickupMoveThreshold;

  void togglePickupNoteExpanded() {
    isPickupNoteExpanded.value = !isPickupNoteExpanded.value;
    if (!isPickupNoteExpanded.value) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void onClose() {
    noteForDriverController.removeListener(_pickupNoteListener);
    noteForDriverController.dispose();
    super.onClose();
  }

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

    _pickupNoteListener = () {
      if (isClosed) return;
      noteChipRevision.value++;
    };
    noteForDriverController.addListener(_pickupNoteListener);
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
      if (data == null) return;
      final results = data.data?.results;
      final nextAddress = (results != null && results.isNotEmpty)
          ? results.first.formattedAddress
          : null;
      if (nextAddress != null && nextAddress.trim().isNotEmpty) {
        address.value = nextAddress.trim();
      }
    });
  }

  /// No permission or location service off → always prompt.
  /// Location available → prompt only when check-book-mode flag is true.
  Future<bool> _shouldPromptBookingForSomeoneElse() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final hasLocationPermission =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!serviceEnabled || !hasLocationPermission) {
      return true;
    }

    try {
      final position = await Loader.run(
        () => Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 5)),
      );

      final checkResult = await Loader.run(
        () => rideRepository.checkBookMode(
          riderLat: position.latitude,
          riderLng: position.longitude,
          pickupLat: selectedLatLng.value.latitude,
          pickupLng: selectedLatLng.value.longitude,
        ),
      );

      return checkResult.fold(
        (_) => false,
        (result) => result.showBookForOtherOption,
      );
    } catch (_) {
      return true;
    }
  }

  Future<void> _finishWithBookingPrompt() async {
    final result = await BookingForSomeoneElseFlowBottomSheet.show();
    if (result == null) return;

    final mode = result['mode'] as BookingMode;
    final isBookedForOther = mode == BookingMode.other;
    bookingMode.value = mode;

    if (isBookedForOther) {
      passengerName.value = (result['name'] as String).trim();
      passengerPhone.value = result['phone'] as String;
      await SchedulerBinding.instance.endOfFrame;
    } else {
      passengerName.value = '';
      passengerPhone.value = '';
    }

    Get.back(
      result: {
        'pickupLat': selectedLatLng.value.latitude,
        'pickupLng': selectedLatLng.value.longitude,
        'pickupAddress': address.value.trim().isEmpty
            ? 'Selected pickup point'
            : address.value.trim(),
        'note': noteForDriverController.text.trim(),
        'isBookedForOther': isBookedForOther,
        'passengerName': isBookedForOther ? passengerName.value.trim() : null,
        'passengerPhone': isBookedForOther ? passengerPhone.value : null,
      },
    );
  }

  void _finishAsSelfBooking() {
    bookingMode.value = BookingMode.self;
    passengerName.value = '';
    passengerPhone.value = '';

    Get.back(
      result: {
        'pickupLat': selectedLatLng.value.latitude,
        'pickupLng': selectedLatLng.value.longitude,
        'pickupAddress': address.value.trim().isEmpty
            ? 'Selected pickup point'
            : address.value.trim(),
        'note': noteForDriverController.text.trim(),
        'isBookedForOther': false,
        'passengerName': null,
        'passengerPhone': null,
      },
    );
  }

  Future<void> confirmPickup() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;

    try {
      final shouldAsk = await _shouldPromptBookingForSomeoneElse();
      if (shouldAsk) {
        await _finishWithBookingPrompt();
      } else {
        _finishAsSelfBooking();
      }
    } finally {
      isSubmitting.value = false;
    }
  }
}
