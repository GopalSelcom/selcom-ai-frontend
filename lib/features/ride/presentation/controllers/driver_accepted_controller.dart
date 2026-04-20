import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/direction_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';

/// SCR-11 — Driver accepted: live map, driver details, OTP.
enum RideBottomSheetState { driverAssigned, rideStarted, rideCompleted }

class DriverAcceptedController extends GetxController
    with GetSingleTickerProviderStateMixin {
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
  int? _seedRideCharge;
  int? _seedBookingFee;
  int? _seedTotalAmount;

  final Rxn<LatLng> assignedDriverLocation = Rxn<LatLng>();
  final routePoints = <LatLng>[].obs;
  final routeTarget = 'pick_up'.obs;

  final isLoadingRide = false.obs;
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
  final unreadCount = 0.obs;
  final rideBottomSheetState = RideBottomSheetState.driverAssigned.obs;
  final currentRideStatus = 'driver_assigned'.obs;
  final selectedRideRating = 4.obs;

  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();
  final Rxn<Offset> assignedDriverEtaScreenPx = Rxn<Offset>();
  final assignedDriverHeading = 0.0.obs;
  AnimationController? _moveAnimController;
  DateTime? _lastRouteFetch;

  VoidCallback? onRecenterPressed;

  GoogleMapController? mapController;
  bool _navigatedAway = false;
  DateTime? _lastCameraUpdate;

  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  bool _didJoinRideRoom = false;

  @override
  void onInit() {
    super.onInit();
    _moveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _parseArgs();
    _bootstrap();
    ever(assignedDriverLocation, (_) => scheduleAssignedEtaOverlayRefresh());
    analyticsService.logEvent('driver_assigned_screen_viewed');
  }

  Future<void> _bootstrap() async {
    await _loadMarkerIcons();
    // await _fetchRideDetails();
    await _initRideRoomSocket();
  }

  Future<void> _loadMarkerIcons() async {
    pickupIcon.value = await MapMarkerUtils.createCustomCircleMarker(
      color: const Color(0xFF4FA3FF),
    );
    dropIcon.value = await MapMarkerUtils.createCustomCircleMarker(
      color: const Color(0xFFE11D48),
    );
  }

  @override
  void onClose() {
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _chatSub?.cancel();
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
    final rawFareBreakdown = args['fareBreakdown'];
    if (rawFareBreakdown is Map) {
      final fareBreakdown = Map<String, dynamic>.from(rawFareBreakdown);
      _seedRideCharge = (fareBreakdown['ride_charge'] as num?)?.toInt();
      _seedBookingFee = (fareBreakdown['booking_fee'] as num?)?.toInt();
      _seedTotalAmount = (fareBreakdown['total_amount'] as num?)?.toInt();
    }
    _setDropRouteFallback();
    _hydrateSocketSeedPayloads(args);
  }

  void _setDropRouteFallback() {
    routeTarget.value = 'drop_off';
    routePoints.assignAll([pickupLatLng, destinationLatLng]);
  }

  void _setPickupRouteFallback() {
    final driver = assignedDriverLocation.value;
    if (driver != null) {
      routePoints.assignAll([driver, pickupLatLng]);
    } else {
      routePoints.assignAll([pickupLatLng, destinationLatLng]);
    }
    routeTarget.value = 'pick_up';
    _fetchRoadRouteFallback();
  }

  Future<void> _fetchRoadRouteFallback() async {
    final target = routeTarget.value;
    final origin = assignedDriverLocation.value;
    final pickup = pickupLatLng;
    final destination = destinationLatLng;

    if (target == 'pick_up' && origin != null) {
      final roadPoints = await DirectionService.getRoute(origin, pickup);
      _lastRouteFetch = DateTime.now();
      if (roadPoints.length > 2 && routeTarget.value == 'pick_up') {
        routePoints.assignAll(roadPoints);
      }
    } else if (target == 'drop_off') {
      // Use driver location as current origin if available, fallback to pickup.
      final start = origin ?? pickup;
      final roadPoints = await DirectionService.getRoute(start, destination);
      _lastRouteFetch = DateTime.now();
      if (roadPoints.length > 2 && routeTarget.value == 'drop_off') {
        routePoints.assignAll(roadPoints);
      }
    }
  }

  void _hydrateSocketSeedPayloads(Map<String, dynamic> args) {
    final statusRaw = args['statusPayload'];
    if (statusRaw is Map) {
      final payload = EventRiderStatusUpdateResponse.fromJson(
        Map<String, dynamic>.from(statusRaw),
      );
      _applyStatusPayload(payload);
    }
    final driverRaw = args['driverLocationPayload'];
    if (driverRaw is Map) {
      final payload = DriverLocationSocketResponse.fromJson(
        Map<String, dynamic>.from(driverRaw),
      );
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat != null && lng != null) {
        assignedDriverLocation.value = LatLng(lat, lng);
      }
    }
    final trackingRaw = args['trackingPayload'];
    if (trackingRaw is Map) {
      final payload = TrackingUpdateSocketResponse.fromJson(
        Map<String, dynamic>.from(trackingRaw),
      );
      _applyTrackingPayload(payload);
    }
  }

  // Future<void> _loadMarkerIcon() async {
  //   try {
  //     await rootBundle.load(AppAssets.gariPlus);
  //     assignedDriverMarkerIcon.value = await BitmapDescriptor.asset(
  //       const ImageConfiguration(size: Size(36, 36)),
  //       AppAssets.gariPlus,
  //     );
  //   } catch (_) {}
  // }

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
        // _applyRide(r);
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
    currentRideStatus.value = 'driver_assigned';
  }

  void _applyRide(RideModel r) {
    final d = r.driverSnapshot as DriverSnapshotModel?;
    final v = r.vehicleSnapshot;
    final vehicleTypeHint = _resolveVehicleTypeHint(
      driverVehicleType: d?.vehicleType,
      driverVehicleModel: d?.vehicleModel,
      vehicleDisplayName: v?.vehicleType,
      vehicleName: v?.vehicleModel,
      vehicleType: v?.vehicleType,
    );
    if (vehicleTypeHint.isNotEmpty) {
      loadDriverIcon(vehicleType: vehicleTypeHint);
    }

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
    _chatSub?.cancel();
    _didJoinRideRoom = false;

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _joinRideRoomIfNeeded();
    });

    _rideStatusSub = _socketService.rideStatusStream.listen((payload) {
      if (_navigatedAway) return;
      final status = (payload.status ?? '').toString().trim();
      _applyBottomSheetStateForStatus(status);
      _applyStatusPayload(payload);
      if (status.toLowerCase() == 'cancelled') {
        Get.offAllNamed(AppRoutes.home);
      }
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      if (payload.latitude == 0 || payload.longitude == 0) return;
      // Strict city-region validation: Dar es Salaam is approx -6.8, 39.2
      if (payload.latitude! < -15 ||
          payload.latitude! > 0 ||
          payload.longitude! < 20 ||
          payload.longitude! > 50)
        return;

      final lat = payload.latitude;
      final lng = payload.longitude;
      final head = payload.heading;
      if (lat == null || lng == null) return;

      final targetPos = LatLng(lat, lng);

      double targetHeading = assignedDriverHeading.value;
      if (head != null) {
        if (head is num) {
          targetHeading = head.toDouble();
        } else if (head is String) {
          targetHeading = double.tryParse(head) ?? targetHeading;
        }
      }

      _animateDriverMovement(targetPos, targetHeading);

      if (routeTarget.value.isNotEmpty) {
        if (routePoints.length <= 2) {
          _fetchRoadRouteFallback();
        } else {
          final firstPoint = routePoints.first;
          final distToPath = _calculateSimpleDist(targetPos, firstPoint);
          if (distToPath > 0.002) {
            final now = DateTime.now();
            if (_lastRouteFetch == null ||
                now.difference(_lastRouteFetch!).inSeconds > 20) {
              _fetchRoadRouteFallback();
            }
          }
        }
      }
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((payload) {
      if (payload != null) _applyTrackingPayload(payload);
    });

    // Ensure socket is connected for the active-ride entry path too.
    await _socketService.connect();
    if (_socketService.isConnected) {
      _joinRideRoomIfNeeded();
    }

    _chatSub = _socketService.chatStream.listen((data) {
      final payloadRideId =
          (data['ride_id'] ?? data['rideId'])?.toString().trim() ?? '';

      if (payloadRideId != rideId) return;

      final senderType =
          (data['sender_type'] ?? data['sender'] ?? data['role'])
              ?.toString()
              .toLowerCase() ??
          '';

      final bool isFromRider =
          senderType == 'rider' ||
          senderType == 'user' ||
          senderType == 'passenger';

      if (!isFromRider && !Get.currentRoute.contains(AppRoutes.rideMessage)) {
        unreadCount.value++;

        final msg = data['message'] ?? data['text'] ?? 'New message';

        NotificationService().showLocalNotification(
          title: 'New Message',
          body: msg.toString(),
          payload: jsonEncode(data),
        );
      }
    });
  }

  void _joinRideRoomIfNeeded() {
    if (_didJoinRideRoom || !_socketService.isConnected || rideId.isEmpty) {
      return;
    }
    _socketService.joinRideRoom(rideId: rideId);
    _didJoinRideRoom = true;
  }

  Future<void> loadDriverIcon({String? vehicleType}) async {
    try {
      String asset = AppAssets.imgCab;
      if (vehicleType != null) {
        final vt = vehicleType.toLowerCase();
        if (vt.contains('boda') || vt.contains('bike')) {
          asset = AppAssets.imgBoda;
        } else if (vt.contains('bajaj')) {
          asset = AppAssets.imgBajaji;
        }
      }
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getResizedMarker(
        asset,
        150,
      );
    } catch (_) {
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getResizedMarker(
        AppAssets.imgBoda,
        150,
      );
    }
  }

  String _resolveVehicleTypeHint({
    String? driverVehicleType,
    String? vehicleDisplayName,
    String? vehicleName,
    String? vehicleType,
    String? driverVehicleModel,
  }) {
    final parts = <String>[
      driverVehicleType ?? '',
      vehicleDisplayName ?? '',
      vehicleName ?? '',
      vehicleType ?? '',
      driverVehicleModel ?? '',
    ];
    return parts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' ')
        .toLowerCase();
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
    onRecenterPressed?.call();
    _fitRouteBounds(force: true);
  }

  Future<void> _fitRouteBounds({bool force = false}) async {
    final ctrl = mapController;
    if (ctrl == null) return;

    // Throttling: prevent rapid animations unless forced (e.g. by recenter button)
    // At most one update every 5 seconds to avoid flickering on every socket event.
    final now = DateTime.now();
    if (!force &&
        _lastCameraUpdate != null &&
        now.difference(_lastCameraUpdate!) < const Duration(seconds: 5)) {
      return;
    }

    final points = <LatLng>[];
    final assigned = assignedDriverLocation.value;

    // "Show driver to pickup only" when in driverAssigned status
    if (rideBottomSheetState.value == RideBottomSheetState.driverAssigned) {
      if (assigned != null) points.add(assigned);
      points.add(pickupLatLng);
    } else {
      // Focusing on segment: Pickup/Current -> Destination
      if (assigned != null) points.add(assigned);
      points.add(destinationLatLng);
    }

    if (routePoints.isNotEmpty) {
      points.addAll(routePoints);
    }

    // Sanity Filter: Remove (0,0) and extreme outliers relative to the driver.
    if (assigned != null) {
      final filtered = points.where((p) {
        if (p.latitude == 0 && p.longitude == 0) return false;
        final dLat = (p.latitude - assigned.latitude).abs();
        final dLng = (p.longitude - assigned.longitude).abs();
        return dLat < 0.2 && dLng < 0.2; // Approx 20km
      }).toList();
      points.clear();
      points.addAll(filtered);
    } else {
      points.removeWhere((p) => p.latitude == 0 && p.longitude == 0);
    }

    if (points.isEmpty) return;
    _lastCameraUpdate = now;

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
          southwest: LatLng(minLat - 0.001, minLng - 0.001),
          northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
        ),
        64,
      ),
    );
  }

  void _applyStatusPayload(EventRiderStatusUpdateResponse payload) {
    final status = (payload.status ?? '').toString().trim();
    if (status.isNotEmpty) {
      _applyBottomSheetStateForStatus(status);
      _applyRouteFallbackForStatus(status);
    }

    final d = payload.driverSnapshot;
    final v = payload.vehicleSnapshot;
    final vehicleTypeHint = _resolveVehicleTypeHint(
      driverVehicleType: d?.vehicleType,
      driverVehicleModel: d?.vehicleModel,
      vehicleDisplayName: v?.displayName,
      vehicleName: v?.vehicleName,
      vehicleType: v?.vehicleType,
    );
    if (vehicleTypeHint.isNotEmpty) {
      loadDriverIcon(vehicleType: vehicleTypeHint);
    }

    if (d != null) {
      if ((d.name ?? '').trim().isNotEmpty) driverName.value = d.name!.trim();
      if ((d.phone ?? '').trim().isNotEmpty)
        driverPhone.value = d.phone!.trim();
      if ((d.lat) != null && (d.lng) != null) {
        assignedDriverLocation.value = LatLng(d.lat!, d.lng!);
      }
      final otp = (payload.pinCode ?? '').replaceAll(RegExp(r'\s'), '');
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

    if (v != null) {
      final type = (v.displayName ?? v.vehicleName ?? v.vehicleType ?? '')
          .trim();
      if (type.isNotEmpty) {
        final suffix = plateLinePrimary.value + plateLineSecondary.value;
        driverVehicleLine.value = suffix.isNotEmpty ? '$type - $suffix' : type;
      }
    }

    final oldStatus = currentRideStatus.value;
    final oldTarget = routeTarget.value;

    final target = _normalizeRouteTarget(payload.routeTarget);
    if (target == 'pick_up') {
      routeTarget.value = target;
      final coords = payload.routeGeometry?.coordinates;
      if (coords != null && coords.isNotEmpty && coords.length > 2) {
        routePoints.assignAll(_toLatLngPolyline(coords));
      } else {
        _fetchRoadRouteFallback();
      }
    } else if (target == 'drop_off') {
      routeTarget.value = target;
      final coords = payload.routeGeometry?.coordinates;
      if (coords != null && coords.isNotEmpty && coords.length > 2) {
        routePoints.assignAll(_toLatLngPolyline(coords));
      } else {
        _fetchRoadRouteFallback();
      }
    } else if (status.isNotEmpty) {
      // Active-ride entry can provide status without routeTarget.
      _applyRouteFallbackForStatus(status);
    }

    // Only re-fit camera if status or route target actually changed.
    // This prevents frequent zoom-outs on every location update.
    if (currentRideStatus.value != oldStatus ||
        routeTarget.value != oldTarget) {
      _fitRouteBounds();
    }
  }

  void _applyBottomSheetStateForStatus(String rawStatus) {
    final status = rawStatus.trim();
    final canonicalStatus = status
        .replaceAll('ridestatus.', '')
        .replaceAll('RideStatus.', '')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)}_${m.group(2)}',
        )
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    final normalizedStatus = canonicalStatus.toLowerCase();
    if (status.isEmpty) return;
    currentRideStatus.value = normalizedStatus;

    if (normalizedStatus == 'cancelled') {
      return;
    }

    RideBottomSheetState nextState = RideBottomSheetState.driverAssigned;
    if (normalizedStatus == 'completed' ||
        normalizedStatus == 'ride_completed') {
      nextState = RideBottomSheetState.rideCompleted;
    } else if (normalizedStatus == 'ride_started' ||
        normalizedStatus == 'ride_in_progress' ||
        normalizedStatus == 'near_destination') {
      nextState = RideBottomSheetState.rideStarted;
    }

    // Prevent stale socket events from downgrading progress state.
    final current = rideBottomSheetState.value;
    if (current == RideBottomSheetState.rideCompleted &&
        nextState != RideBottomSheetState.rideCompleted) {
      return;
    }
    if (current == RideBottomSheetState.rideStarted &&
        nextState == RideBottomSheetState.driverAssigned) {
      return;
    }

    rideBottomSheetState.value = nextState;
  }

  void _applyRouteFallbackForStatus(String rawStatus) {
    // Only apply fallback if we don't already have points.
    if (routePoints.isNotEmpty) return;

    final status = rawStatus.trim();
    final canonicalStatus = status
        .replaceAll('ridestatus.', '')
        .replaceAll('RideStatus.', '')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)}_${m.group(2)}',
        )
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    final normalizedStatus = canonicalStatus.toLowerCase();
    if (status.isEmpty) return;

    const pickupStatuses = {'accepted', 'driver_assigned', 'driver_arriving'};
    const dropStatuses = {
      'driver_arrived',
      'ride_started',
      'ride_in_progress',
      'near_destination',
      'ride_completed',
      'completed',
    };

    if (pickupStatuses.contains(normalizedStatus)) {
      _setPickupRouteFallback();
      _fetchRoadRouteFallback();
      return;
    }

    if (dropStatuses.contains(normalizedStatus)) {
      _setDropRouteFallback();
      _fetchRoadRouteFallback();
    }
  }

  String get rideProgressTitle {
    switch (currentRideStatus.value) {
      case 'ride_completed':
      case 'completed':
        return 'You have arrived!';
      case 'near_destination':
        return 'Almost There';
      case 'ride_in_progress':
        return 'On Your Way';
      case 'ride_started':
        return 'Ride Started';
      case 'driver_arrived':
        return 'Driver Arrived';
      case 'driver_arriving':
        return 'Driver En Route';
      case 'driver_assigned':
      default:
        return 'Driver Assigned';
    }
  }

  String get rideProgressSubtitle {
    switch (currentRideStatus.value) {
      case 'near_destination':
        return 'Approaching your destination';
      case 'ride_in_progress':
        return 'Heading to your destination';
      case 'ride_started':
        return 'Trip has started';
      case 'driver_arrived':
        return 'Driver has reached pickup';
      case 'driver_arriving':
      case 'driver_assigned':
        return 'Driver is heading to pickup';
      case 'ride_completed':
      case 'completed':
        return arrivalDateLabel;
      default:
        return 'Arrived in ${etaLabel.value.toLowerCase()}';
    }
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    final eta = payload.eta;
    if (eta != null && eta > 0) {
      final convertedTime = eta / 60;
      etaLabel.value = '$convertedTime Mins';
      arrivalLabel.value =
          'Driver will arriving in ${convertedTime <= 1 ? '1 min' : '$convertedTime mins'}...';
    }

    String target = _normalizeRouteTarget(payload.routeTarget);
    final coords = payload.routeGeometry?.coordinates;

    // If target is missing, infer it from the status
    if (target.isEmpty) {
      final status = (payload.status ?? '').toLowerCase();
      if (status.contains('progress') || status.contains('started')) {
        target = 'drop_off';
      } else if (status.contains('assigned') || status.contains('arriving')) {
        target = 'pick_up';
      }
    }

    if (target == 'pick_up') {
      routeTarget.value = target;
      if (coords != null && coords.isNotEmpty) {
        final newPoints = _toLatLngPolyline(coords);
        if (newPoints.length > 5) {
          routePoints.assignAll(newPoints);
        } else if (routePoints.length <= 2) {
          _fetchRoadRouteFallback();
        }
      }
    } else if (target == 'drop_off') {
      routeTarget.value = target;
      if (coords != null && coords.isNotEmpty) {
        final newPoints = _toLatLngPolyline(coords);
        if (newPoints.length > 5) {
          routePoints.assignAll(newPoints);
        } else if (routePoints.length <= 2) {
          _fetchRoadRouteFallback();
        }
      }
    }
    // _fitRouteBounds() removed from here to prevent frequent zoom-outs.
  }

  void _animateDriverMovement(LatLng targetPos, double targetHeading) {
    if (assignedDriverLocation.value == null) {
      assignedDriverLocation.value = targetPos;
      assignedDriverHeading.value = targetHeading;
      return;
    }

    final startPos = assignedDriverLocation.value!;
    final startHeading = assignedDriverHeading.value;

    _moveAnimController?.stop();
    _moveAnimController?.reset();

    final Animation<double> curve = CurvedAnimation(
      parent: _moveAnimController!,
      curve: Curves.linear,
    );

    _moveAnimController?.addListener(() {
      final t = curve.value;
      final currentPos = _interpolateLatLng(startPos, targetPos, t);
      assignedDriverLocation.value = currentPos;
      assignedDriverHeading.value = _interpolateAngle(
        startHeading,
        targetHeading,
        t,
      );

      // Perform real-time trimming for visual smoothness
      _trimRoutePoints(currentPos);
    });

    _moveAnimController?.forward();
  }

  void _trimRoutePoints(LatLng currentPos) {
    if (routePoints.length < 3) return;

    int closestIndex = -1;
    // ~50m threshold for trimming
    const double trimThreshold = 0.0005;

    // Check upcoming segments for progress
    int checkCount = routePoints.length > 8 ? 8 : routePoints.length;
    for (int i = 0; i < checkCount; i++) {
      final dist = _calculateSimpleDist(currentPos, routePoints[i]);
      if (dist < trimThreshold) {
        closestIndex = i;
        break;
      }
    }

    if (closestIndex > 0) {
      routePoints.removeRange(0, closestIndex);
      // Ensure the line starts exactly at the driver for a clean look
      routePoints[0] = currentPos;
    }
  }

  double _calculateSimpleDist(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() + (a.longitude - b.longitude).abs();
  }

  LatLng _interpolateLatLng(LatLng a, LatLng b, double t) {
    final lat = a.latitude + (b.latitude - a.latitude) * t;
    final lng = a.longitude + (b.longitude - a.longitude) * t;
    return LatLng(lat, lng);
  }

  double _interpolateAngle(double a, double b, double t) {
    // Basic linear interpolation for heading.
    // In a production app, you might want to handle the 0/360 wrap-around smoothly.
    return a + (b - a) * t;
  }

  String _normalizeRouteTarget(String? target) {
    final t = (target ?? '').trim().toLowerCase();
    if (t == 'pickup' || t == 'pick_up') return 'pick_up';
    if (t == 'dropoff' || t == 'drop_off' || t == 'destination') {
      return 'drop_off';
    }
    return '';
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

    // Clean string for tel: link
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback: try launch regardless if canLaunch fails on some systems
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Error launching dialer: $e");
      Get.snackbar('Call', 'Error opening phone dialer');
    }
  }

  void onChatTap() {
    unreadCount.value = 0;
    Get.toNamed(
      AppRoutes.rideMessage,
      arguments: {
        'rideId': rideId,
        'driverName': driverName.value,
        'driverPhone': driverPhone.value,
        'driverSubtitle': plateLinePrimary.value + plateLineSecondary.value,
        'riderName': 'Rider', // Default placeholder
        'initialStatus': _mapBottomSheetToRideStatus(
          rideBottomSheetState.value,
        ).name,
      },
    );
  }

  RideStatus _mapBottomSheetToRideStatus(RideBottomSheetState state) {
    switch (state) {
      case RideBottomSheetState.driverAssigned:
        return RideStatus.driverAssigned;
      case RideBottomSheetState.rideStarted:
        return RideStatus.rideStarted;
      case RideBottomSheetState.rideCompleted:
        return RideStatus.rideCompleted;
    }
  }

  void setRideRating(int rating) {
    if (rating < 1 || rating > 5) return;
    selectedRideRating.value = rating;
  }

  void finishCompletedRide() {
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
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

  String get rideChargeLabel {
    final amount =
        ride.value?.fareBreakdown?.rideCharge ??
        _seedRideCharge ??
        ride.value?.fareEstimate ??
        100;
    return 'TZS $amount.00';
  }

  String get bookingFeeLabel {
    final amount =
        ride.value?.fareBreakdown?.bookingFee ?? _seedBookingFee ?? 0;
    return 'TZS $amount.00';
  }

  String get totalAmountLabel {
    final amount =
        ride.value?.fareBreakdown?.totalAmount ??
        _seedTotalAmount ??
        ride.value?.finalFare ??
        ride.value?.fareEstimate ??
        100;
    return 'TZS $amount.00';
  }

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
      const CancelReasonSelectionDialog(
        reasons: [
          'Driver Asked To Cancel',
          'Driver Asked To Pay Offline',
          'Taking Too Long To Arrive',
          'Selected Wrong Pickup Location',
          'Booked By Mistake',
          'Others',
        ],
      ),
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
