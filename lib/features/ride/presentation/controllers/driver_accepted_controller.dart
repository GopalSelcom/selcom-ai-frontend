import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';

/// SCR-11 — Driver accepted: live map, driver details, OTP, cancel (SCR-12 flow later).
enum RideBottomSheetState { driverAssigned, rideStarted, rideCompleted }

class DriverAcceptedController extends GetxController {
  DriverAcceptedController({
    required this.rideRepository,
    required this.analyticsService,
  });

  final RideRepository rideRepository;
  final AnalyticsService analyticsService;

  final AppSocketService _socketService = AppSocketService();

  late final String rideId;
  late final LatLng pickupLatLng;
  late final LatLng destinationLatLng;
  late final String pickupAddress;
  late final String destinationAddress;

  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();
  final routePoints = <LatLng>[].obs;

  final isLoadingRide = true.obs;
  final Rxn<RideModel> ride = Rxn<RideModel>();

  final driverName = ''.obs;
  final driverPhone = ''.obs;
  final driverRating = ''.obs;
  final driverVehicleLine = ''.obs;
  final plateLinePrimary = ''.obs;
  final plateLineSecondary = ''.obs;
  final vehicleSubtitle = ''.obs;
  final otpDigits = <String>[].obs;
  final etaLabel = '10 Mins'.obs;
  final arrivalLabel = 'Driver will arriving in 1 min...'.obs;
  final rideBottomSheetState = RideBottomSheetState.driverAssigned.obs;
  final selectedRideRating = 4.obs;

  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<Offset> assignedDriverEtaScreenPx = Rxn<Offset>();

  GoogleMapController? mapController;
  bool _navigatedAway = false;

  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;

  @override
  void onInit() {
    super.onInit();
    _parseArgs();
    _loadMarkerIcon();
    _bootstrap();
    ever(assignedDriverLocation, (_) => scheduleAssignedEtaOverlayRefresh());
    analyticsService.logEvent('driver_assigned_screen_viewed');
  }

  Future<void> _bootstrap() async {
    await _fetchRideDetails();
    await _initRideRoomSocket();
  }

  @override
  void onClose() {
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
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
    _buildRoutePolyline();
  }

  void _buildRoutePolyline() {
    final p = pickupLatLng;
    final d = destinationLatLng;
    const steps = 24;
    final pts = <LatLng>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat =
          p.latitude +
          (d.latitude - p.latitude) * t +
          0.0012 * (t - 0.5) * (t - 0.5);
      final lng =
          p.longitude + (d.longitude - p.longitude) * t + 0.001 * (t - 0.3);
      pts.add(LatLng(lat, lng));
    }
    routePoints.assignAll(pts);
  }

  Future<void> _loadMarkerIcon() async {
    try {
      assignedDriverMarkerIcon.value = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(36, 36)),
        AppAssets.gariPlus,
      );
    } catch (_) {}
  }

  Future<void> _fetchRideDetails() async {
    if (rideId.isEmpty) {
      _applyMockContent();
      isLoadingRide.value = false;
      assignedDriverLocation.value ??= const LatLng(-6.7921, 39.2101);
      return;
    }
    final result = await rideRepository.getRideDetails(rideId);
    result.fold(
      (_) {
        _applyMockContent();
        assignedDriverLocation.value ??= const LatLng(-6.7921, 39.2101);
      },
      (r) {
        ride.value = r;
        _applyRide(r);
      },
    );
    isLoadingRide.value = false;
  }

  void _applyMockContent() {
    driverName.value = 'John Doe';
    driverPhone.value = '';
    driverRating.value = '4';
    driverVehicleLine.value = 'Volkswagen';
    plateLinePrimary.value = 'T 772';
    plateLineSecondary.value = 'BBE';
    vehicleSubtitle.value = 'Toyota corolla, White';
    otpDigits.assignAll(['2', '7', '5', '6']);
    arrivalLabel.value = 'Driver will arriving in 1 min...';
  }

  void _applyRide(RideModel r) {
    final d = r.driverSnapshot as DriverSnapshotModel?;
    final v = r.vehicleSnapshot;

    if (d != null) {
      driverName.value = d.name;
      driverPhone.value = d.phone;
      driverRating.value = d.rating > 0 ? d.rating.toStringAsFixed(1) : '—';

      // If vehicle snapshot is missing or generic, use fields from driver snapshot
      final plate = (d.vehicleRegistrationNumber ?? '').trim();
      final model = (d.vehicleModel ?? '').trim();
      final color = (d.vehicleColor ?? '').trim();
      final type = (d.vehicleType ?? '').trim();

      if (plate.isNotEmpty) {
        driverVehicleLine.value = type.isNotEmpty ? '$type - $plate' : plate;
        final compact = plate.replaceAll(' ', '');
        if (compact.length > 3) {
          final mid = compact.length ~/ 2;
          plateLinePrimary.value = compact.substring(0, mid);
          plateLineSecondary.value = compact.substring(mid);
        } else {
          plateLinePrimary.value = plate;
          plateLineSecondary.value = '';
        }
      }
      if (model.isNotEmpty || color.isNotEmpty) {
        vehicleSubtitle.value = [
          model,
          color,
        ].where((e) => e.isNotEmpty).join(', ').trim();
      }

      final otp = (d.verificationCode ?? '').replaceAll(RegExp(r'\s'), '');
      if (otp.isNotEmpty) {
        otpDigits.assignAll(otp.split('').take(4).toList());
      } else {
        otpDigits.assignAll(['—', '—', '—', '—']);
      }
    } else {
      driverName.value = 'Driver';
      driverPhone.value = '';
      driverRating.value = '—';
      otpDigits.assignAll(['—', '—', '—', '—']);
    }

    if (v != null && vehicleSubtitle.value.isEmpty) {
      vehicleSubtitle.value =
          '${v.vehicleMake} ${v.vehicleModel}, ${v.vehicleColor}'.trim();
      if (driverVehicleLine.value.isEmpty) {
        driverVehicleLine.value = '${v.vehicleType} - ${v.plateNumber}';
      }
    }
  }

  Future<void> _initRideRoomSocket() async {
    if (rideId.isEmpty) return;

    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _socketService.joinRideRoom(rideId: rideId);
    });

    _rideStatusSub = _socketService.rideStatusStream.listen((payload) {
      if (_navigatedAway) return;
      final status = (payload.status ?? '').toString().toLowerCase();
      _applyStatusPayload(payload);

      if (status == 'cancelled' || status == 'completed') {
        if (status == 'cancelled') {
          Get.offAllNamed(AppRoutes.home);
          return;
        }
        rideBottomSheetState.value = RideBottomSheetState.rideCompleted;
        return;
      }
      if (status == 'ride_started' || status == 'ride_in_progress') {
        rideBottomSheetState.value = RideBottomSheetState.rideStarted;
        return;
      }
      rideBottomSheetState.value = RideBottomSheetState.driverAssigned;
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat == null || lng == null) return;
      assignedDriverLocation.value = LatLng(lat, lng);
      _fitRouteBounds();
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((payload) {
      if (payload == null) return;
      _applyTrackingPayload(payload);
    });

    await _socketService.connect();
    if (_socketService.isConnected) {
      _socketService.joinRideRoom(rideId: rideId);
    }
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitRouteBounds();
    scheduleAssignedEtaOverlayRefresh();
  }

  void scheduleAssignedEtaOverlayRefresh() {
    Future.microtask(refreshAssignedDriverEtaOverlay);
  }

  Future<void> refreshAssignedDriverEtaOverlay() async {
    final ctrl = mapController;
    final pos = assignedDriverLocation.value;
    if (ctrl == null || pos == null) {
      assignedDriverEtaScreenPx.value = null;
      return;
    }
    final px = await AppMapService.screenOffsetFor(ctrl, pos);
    assignedDriverEtaScreenPx.value = px;
  }

  void recenterMap() {
    _fitRouteBounds();
    scheduleAssignedEtaOverlayRefresh();
  }

  Future<void> _fitRouteBounds() async {
    final ctrl = mapController;
    if (ctrl == null) return;
    final points = <LatLng>[pickupLatLng, destinationLatLng];
    final assigned = assignedDriverLocation.value;
    if (assigned != null) points.add(assigned);
    if (routePoints.isNotEmpty) points.addAll(routePoints);

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

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

  void _applyStatusPayload(EventRiderStatusUpdateResponse payload) {
    final d = payload.driverSnapshot;
    if (d != null) {
      if ((d.name ?? '').trim().isNotEmpty) driverName.value = d.name!.trim();
      if ((d.phone ?? '').trim().isNotEmpty)
        driverPhone.value = d.phone!.trim();
      if ((d.lat) != null && (d.lng) != null) {
        assignedDriverLocation.value = LatLng(d.lat!, d.lng!);
      }
      final otp = (d.verificationCode ?? '').replaceAll(RegExp(r'\s'), '');
      if (otp.isNotEmpty) {
        otpDigits.assignAll(otp.split('').take(4).toList());
      }
      final vehicleModel = (d.vehicleModel ?? '').trim();
      final vehicleColor = (d.vehicleColor ?? '').trim();
      final plate = (d.vehicleRegistrationNumber ?? '').trim();
      final vehicleType = (d.vehicleType ?? '').trim();

      if (vehicleModel.isNotEmpty || vehicleColor.isNotEmpty) {
        final subtitle = '$vehicleModel, $vehicleColor'
            .replaceAll(RegExp(r'(^,\s*|\s*,\s*$)'), '')
            .trim();
        if (subtitle.isNotEmpty) vehicleSubtitle.value = subtitle;
      }
      if (vehicleType.isNotEmpty || plate.isNotEmpty) {
        driverVehicleLine.value = [
          vehicleType,
          plate,
        ].where((e) => e.isNotEmpty).join(' - ');
      }
      if (plate.isNotEmpty) {
        final compact = plate.replaceAll(' ', '');
        if (compact.length > 3) {
          final mid = compact.length ~/ 2;
          plateLinePrimary.value = compact.substring(0, mid);
          plateLineSecondary.value = compact.substring(mid);
        } else {
          plateLinePrimary.value = plate;
          plateLineSecondary.value = '';
        }
      }
    }

    final v = payload.vehicleSnapshot;
    if (v != null) {
      final type = (v.displayName ?? v.vehicleName ?? v.vehicleType ?? '')
          .trim();
      if (type.isNotEmpty) {
        final suffix = plateLinePrimary.value + plateLineSecondary.value;
        driverVehicleLine.value = suffix.isNotEmpty ? '$type - $suffix' : type;
      }
    }

    if ((payload.routeTarget ?? '').toLowerCase() == 'pick_up') {
      final coords = payload.routeGeometry?.coordinates;
      if (coords != null && coords.isNotEmpty) {
        routePoints.assignAll(_toLatLngPolyline(coords));
      }
    }

    _fitRouteBounds();
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    final eta = payload.eta;
    if (eta != null && eta > 0) {
      etaLabel.value = '$eta Mins';
      arrivalLabel.value =
          'Driver will arriving in ${eta <= 1 ? '1 min' : '$eta mins'}...';
    }

    final target = (payload.routeTarget ?? '').toLowerCase();
    if (target == 'pick_up') {
      final coords = payload.routeGeometry?.coordinates;
      if (coords != null && coords.isNotEmpty) {
        routePoints.assignAll(_toLatLngPolyline(coords));
      }
    }
    _fitRouteBounds();
  }

  List<LatLng> _toLatLngPolyline(List<List<double>> coords) {
    return coords
        .where((c) => c.length >= 2)
        .map((c) => LatLng(c[1], c[0]))
        .toList();
  }

  void openProfile() {
    Get.to(() => ProfileScreen());
  }

  Future<void> callDriver() async {
    final phone = driverPhone.value.trim();
    if (phone.isEmpty) {
      Get.snackbar('Call', 'Phone number unavailable');
      return;
    }
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar('Call', 'Unable to open phone dialer');
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
      Get.snackbar('Call', 'Error opening phone dialer');
    }
  }

  void onChatTap() {
    Get.toNamed(
      AppRoutes.rideMessage,
      arguments: {
        'rideId': rideId,
        'driverName': driverName.value,
        'driverPhone': driverPhone.value,
        'driverSubtitle': plateLinePrimary.value + plateLineSecondary.value,
        'riderName': 'Rider', // Default placeholder
      },
    );
  }

  void setRideRating(int rating) {
    if (rating < 1 || rating > 5) return;
    selectedRideRating.value = rating;
  }

  void finishCompletedRide() {
    Get.offAllNamed(AppRoutes.home);
  }

  String get pickupTitle => _firstAddressLine(pickupAddress);
  String get destinationTitle => _firstAddressLine(destinationAddress);
  String get rideVehicleLabel {
    final value = driverVehicleLine.value.trim();
    if (value.isNotEmpty) return value.split('-').first.trim();
    return 'Boda';
  }

  String get arrivalDateLabel {
    final value = ride.value;
    if (value == null) return '05th Mar 2026 . 08:08PM';
    return DateFormat('dd\'th\' MMM yyyy . hh:mma').format(value.createdAt);
  }

  String get rideChargeLabel => 'TZS ${ride.value?.fareEstimate ?? 100}.00';
  String get bookingFeeLabel => 'TZS ${ride.value?.fareEstimate ?? 100}.00';
  String get totalAmountLabel =>
      'TZS ${ride.value?.finalFare ?? ride.value?.fareEstimate ?? 100}.00';
  String get paymentModeLabel {
    final method = ride.value?.paymentMethod.name ?? 'wallet';
    switch (method) {
      case 'mobileMoney':
        return 'Mobile Money';
      case 'selcomPesa':
        return 'Selcom Pesa';
      case 'card':
        return 'Card';
      default:
        return 'Wallet';
    }
  }

  String _firstAddressLine(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return 'Unknown location';
    return trimmed.split(',').first.trim();
  }

  Future<void> confirmCancelRide() async {
    // 1. Initial Confirmation
    final dynamic confirmResult = await Get.dialog(
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
    final result = await rideRepository.cancelRide(rideId, 'rider_cancelled');
    result.fold(
      (_) => Get.snackbar('Cancel failed', 'Could not cancel. Try again.'),
      (success) {
        if (success) {
          _navigatedAway = true;
          Get.offAllNamed(AppRoutes.home);
        } else {
          Get.snackbar('Cancel failed', 'Please try again.');
        }
      },
    );
  }
}
