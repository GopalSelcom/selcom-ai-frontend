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
  final isMapReady = false.obs;

  final bookingMode = BookingMode.self.obs;
  final passengerName = ''.obs;
  final passengerPhone = ''.obs;
  final TextEditingController noteForDriverController = TextEditingController();
  VoidCallback? _pickupNoteListener;
  late LatLng _initialLatLng;
  late String initialAddress;

  /// Drives Obx for pickup note chip (TextEditingController is not reactive).
  final noteChipRevision = 0.obs;
  final isPickupNoteExpanded = false.obs;

  GoogleMapController? mapController;
  int _cameraSyncGeneration = 0;

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
    if (_pickupNoteListener != null) {
      noteForDriverController.removeListener(_pickupNoteListener!);
    }
    noteForDriverController.dispose();
    mapController = null;
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
    _initialLatLng = LatLng(lat, lng);
    selectedLatLng.value = _initialLatLng;
    initialAddress =
        (args['pickupAddress'] as String?)?.trim() ?? 'Selected pickup point';
    address.value = initialAddress;
    isMapReady.value = false;
    isPickupNoteExpanded.value = false;
    isResolvingAddress.value = false;
    isSubmitting.value = false;
    mapController = null;
    _cameraSyncGeneration++;

    _pickupNoteListener = () {
      if (isClosed) return;
      noteChipRevision.value++;
    };
    noteForDriverController.addListener(_pickupNoteListener!);
  }

  Future<void> onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    final generation = _cameraSyncGeneration;
    await _syncCameraToPickup(generation: generation);
    if (!isClosed && generation == _cameraSyncGeneration) {
      isMapReady.value = true;
    }
  }

  Future<void> _syncCameraToPickup({
    required int generation,
    int attempt = 0,
  }) async {
    final ctrl = mapController;
    if (ctrl == null || isClosed || generation != _cameraSyncGeneration) {
      return;
    }

    await SchedulerBinding.instance.endOfFrame;
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 50 * attempt));
    }

    try {
      await ctrl.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialLatLng, zoom: 16),
        ),
      );
      selectedLatLng.value = _initialLatLng;
    } catch (_) {
      if (attempt < 3 && generation == _cameraSyncGeneration) {
        await _syncCameraToPickup(generation: generation, attempt: attempt + 1);
      }
    }
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

  /// No location permission/service → always prompt.
  /// Location available → prompt only when `go/check-book-mode` returns
  /// `show_book_for_other_option: true`.
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
