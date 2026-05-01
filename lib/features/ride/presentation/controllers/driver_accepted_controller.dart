import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/ride_stops_update_response.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/payment_status_response/payment_status_response.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:selcom_rides_frontend/features/ride/data/models/stop_update_models.dart';
import 'package:selcom_rides_frontend/core/data/models/requests/validate_ride_payment_request.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/utils/receipt_pdf_generator.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/repositories/ride_repository.dart';
import '../widgets/cancel_ride_dialogs.dart';
import '../widgets/stop_update_progress_modal.dart';
import '../../../../core/services/storage_service.dart';
import '../screens/ride_details_screen.dart';
import 'ride_details_controller.dart';

/// SCR-11 — Driver accepted: live map, driver details, OTP.
enum RideBottomSheetState { driverAssigned, rideStarted }

class DriverAcceptedController extends GetxController
    with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
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
  final driverAvatarUrl = ''.obs;
  final driverRating = ''.obs;
  final driverVehicleLine = ''.obs;
  final bottomSheetVehicleImageAsset = AppAssets.imgCab.obs;
  final plateLinePrimary = ''.obs;
  final plateLineSecondary = ''.obs;
  final vehicleSubtitle = ''.obs;
  final otpDigits = <String>[].obs;
  final isPinRequired = true.obs;
  final etaLabel = '10 Mins'.obs;
  final currentEtaSeconds = 0.0.obs;
  final arrivalLabel = 'Driver will arriving in 1 min...'.obs;
  final unreadCount = 0.obs;
  final rideBottomSheetState = RideBottomSheetState.driverAssigned.obs;
  final currentRideStatus = 'driver_assigned'.obs;
  final selectedRideRating = 4.obs;
  final isReasonProcessing = false.obs;
  final isCancelPayProcessing = false.obs;

  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();
  final stopIcons = <BitmapDescriptor>[].obs;
  final Rxn<Offset> assignedDriverEtaScreenPx = Rxn<Offset>();
  final assignedDriverHeading = 0.0.obs;
  AnimationController? _moveAnimController;

  VoidCallback? onRecenterPressed;

  GoogleMapController? mapController;
  bool _navigatedAway = false;
  DateTime? _lastCameraUpdate;
  bool _openedCompletedRideDetails = false;

  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStatusSub;
  StreamSubscription<EventRiderStatusUpdateResponse>? _rideStopSub;
  StreamSubscription<DriverLocationSocketResponse>? _driverLocSub;
  StreamSubscription<TrackingUpdateSocketResponse?>? _trackingSub;
  StreamSubscription<Map<String, dynamic>>? _chatSub;
  StreamSubscription<RideStopsUpdatedResponse>? _rideStopsUpdatedSub;
  StreamSubscription<RideStopsUpdateFailedResponse>? _rideStopsUpdateFailedSub;
  StreamSubscription<PaymentStatusUpdateResponse>? _paymentStatusSub;
  bool _didJoinRideRoom = false;
  bool _isHandlingAppResume = false;

  final RxDouble sheetSize = 0.3.obs;

  // Mid-Ride Stops State
  final isUpdatingStops = false.obs;
  final stopUpdateIdempotencyKey = ''.obs;
  final Rxn<StopUpdatePreviewModel> stopUpdatePreview =
      Rxn<StopUpdatePreviewModel>();
  final Rxn<StopUpdateAppliedModel> stopUpdateApplied =
      Rxn<StopUpdateAppliedModel>();
  final stopUpdateProgressStep =
      0.obs; // 0: Idle, 1: Payment, 2: Route, 3: Success
  final stopUpdateWorkingStops = <RideStopEntity>[].obs;

  void updateSheetSize(double size) {
    sheetSize.value = size;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _moveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _parseArgs();
    _bootstrap();
    ever(assignedDriverLocation, (_) => scheduleAssignedEtaOverlayRefresh());
    ever(routePoints, (List<LatLng> points) {
      if (points.length > 2) {
        recenterMap();
      }
    });
    ever(
      isUpdatingStops,
      (bool updating) => _handleStopUpdateProgress(updating),
    );
    _loadPersistedIdempotencyKey();
    analyticsService.logEvent('driver_assigned_screen_viewed');
  }

  Future<void> _loadPersistedIdempotencyKey() async {
    final key = await StorageService().read(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
    );
    if (key != null) {
      stopUpdateIdempotencyKey.value = key;
    }
  }

  Future<void> _saveIdempotencyKey(String key) async {
    await StorageService().write(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
      key,
    );
  }

  Future<void> _clearIdempotencyKey() async {
    await StorageService().delete(
      '${StorageKeys.stopsIdempotencyPrefix}$rideId',
    );
    stopUpdateWorkingStops.clear();
    stopUpdatePreview.value = null;
  }

  Future<void> _bootstrap() async {
    await _loadMarkerIcons();
    await _fetchRideDetails();
    _handleStopUpdateRecovery();
    await _initRideRoomSocket();
  }

  void _handleStopUpdateRecovery() {
    final pending = ride.value?.pendingStopsUpdate;
    if (pending == null) return;

    if (pending.status == 'pending_payment') {
      // Trust the backend: if it's in the response, it's not expired yet
      stopUpdatePreview.value = StopUpdatePreviewModel(
        fareChanged: true,
        oldFareEstimate: ride.value?.fareEstimate ?? 0,
        newFareEstimate: pending.newFare ?? 0,
        deltaAmount: pending.deltaAmount,
        direction: pending.direction,
        newDistanceKm: 0,
        newDurationMin: 0,
        waypointCharge: 0,
        legs: [],
        stopsDiff: StopUpdateDiffModel(
          added: [],
          removed: [],
          reordered: false,
        ),
      );
      stopUpdateWorkingStops.assignAll(pending.stops);
      if (pending.idempotencyKey != null) {
        stopUpdateIdempotencyKey.value = pending.idempotencyKey!;
        _saveIdempotencyKey(pending.idempotencyKey!);
      }
    } else if (pending.status == 'pending_da') {
      isUpdatingStops.value = true;
      stopUpdateProgressStep.value = 2; // Route update phase
      _startStopUpdateTimeout();
    }
  }

  Future<void> _loadMarkerIcons() async {
    final bool isMulti = ride.value?.isMultiStop ?? false;
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

    if (!isMulti) {
      // Single Stop: P (Blue) and D (Green)
      pickupIcon.value = await MapMarkerUtils.createTextMarker(
        text: 'P',
        color: AppColors.mapPickupMarkerBlue,
      );
      dropIcon.value = await MapMarkerUtils.createTextMarker(
        text: 'D',
        color: AppColors.mapDropMarkerGreen,
      );
      stopIcons.clear();
    } else {
      // Multi Stop: A (Blue), B, C... (Red), Last (Green)
      pickupIcon.value = await MapMarkerUtils.createTextMarker(
        text: 'A',
        color: AppColors.mapPickupMarkerBlue,
      );

      stopIcons.clear();
      // Intermediate stops are Red
      for (int i = 1; i < letters.length; i++) {
        final icon = await MapMarkerUtils.createTextMarker(
          text: letters[i],
          color: AppColors.mapStopMarkerRed,
        );
        stopIcons.add(icon);
      }

      // Final destination icon (Green)
      final sList = ride.value?.stops ?? [];
      final destIndex = sList.length + 1; // 1 for pickup + number of stops
      final label = (destIndex < letters.length)
          ? letters[destIndex]
          : letters.last;

      dropIcon.value = await MapMarkerUtils.createTextMarker(
        text: label,
        color: AppColors.mapDropMarkerGreen,
      );
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _rideStopSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _chatSub?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _recoverRealtimeStateOnResume();
  }

  void _recoverRealtimeStateOnResume() {
    if (_isHandlingAppResume || rideId.isEmpty) return;
    _isHandlingAppResume = true;
    Future.microtask(() async {
      try {
        await _fetchRideDetails();
        await _socketService.connect();
        _didJoinRideRoom = false;
        _joinRideRoomIfNeeded();
      } finally {
        _isHandlingAppResume = false;
      }
    });
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
  }

  void _hydrateSocketSeedPayloads(Map<String, dynamic> args) {
    developer.log(
      "💧 Hydrating socket seed payloads from args",
      name: 'ORDER_TRACKING',
      error: args.toString(),
    );
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
    isLoadingRide.value = true;
    final result = await rideRepository.getRideDetails(rideId);
    result.fold(
      (f) {
        _applyMockContent();
        assignedDriverLocation.value ??= const LatLng(-6.7921, 39.2101);
      },
      (r) {
        ride.value = r;
        _applyRide(r);
        _syncLiveActivityFromDetails(r);
        _loadMarkerIcons(); // Refresh icons with new ride context

        // Debug logging for the "Stuck" state issues
        if (isUpdatingStops.value) {
          debugPrint(
            "STOPS_UPDATE_POLL: step=${stopUpdateProgressStep.value}, "
            "pendingStatus=${r.pendingStopsUpdate?.status}, "
            "rideStopsCount=${r.stops.length}, "
            "workingStopsCount=${stopUpdateWorkingStops.length}",
          );
        }

        // Hardening: If we are stuck in recalculating step and pending update is gone, it succeeded!
        if (isUpdatingStops.value && stopUpdateProgressStep.value == 2) {
          if (r.pendingStopsUpdate == null) {
            _clearIdempotencyKey();
            stopUpdateProgressStep.value = 3; // Success!
            isUpdatingStops.value = false;
          } else if (stopUpdateWorkingStops.isNotEmpty &&
              r.stops.length == stopUpdateWorkingStops.length) {
            // Also succeed if the confirmed stops list now matches our target list count
            _clearIdempotencyKey();
            stopUpdateProgressStep.value = 3; // Success!
            isUpdatingStops.value = false;
          }
        }
      },
    );
    isLoadingRide.value = false;
    _fitRouteBounds(force: true);
  }

  void _applyMockContent() {
    driverName.value = 'John Doe';
    driverPhone.value = '';
    driverAvatarUrl.value = '';
    bottomSheetVehicleImageAsset.value = AppAssets.imgBoda;
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
    isPinRequired.value = r.pinRequired;
    final d = r.driverSnapshot as DriverSnapshotModel?;
    final v = r.vehicleSnapshot;
    String plateForVehicleLine = '';
    final vehicleTypeHint = _resolveVehicleTypeHint(
      driverVehicleType: d?.vehicleType,
      driverVehicleModel: d?.vehicleModel,
      vehicleDisplayName: v?.vehicleType,
      vehicleName: v?.vehicleModel,
      vehicleType: v?.vehicleType,
    );
    _syncBottomSheetVehicleImage(vehicleTypeHint);
    if (vehicleTypeHint.isNotEmpty) {
      loadDriverIcon(vehicleType: vehicleTypeHint);
    }

    if (d != null) {
      driverName.value = d.name;
      driverPhone.value = d.phone;
      driverAvatarUrl.value = (d.avatarUrl ?? '').trim();
      driverRating.value = d.rating > 0 ? d.rating.toStringAsFixed(1) : '—';

      // If vehicle snapshot is missing or generic, use fields from driver snapshot
      final plate = (d.vehicleRegistrationNumber ?? '').trim();
      final model = (d.vehicleModel ?? '').trim();
      final color = (d.vehicleColor ?? '').trim();
      plateForVehicleLine = plate;

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
      if (model.isNotEmpty || color.isNotEmpty) {
        vehicleSubtitle.value = [
          model,
          color,
        ].where((e) => e.isNotEmpty).join(', ').trim();
      }

      if (isPinRequired.value) {
        final pin = r.pinCode.trim();
        final vCode = (d.verificationCode ?? '').trim();
        final otp = (pin.isNotEmpty ? pin : vCode).replaceAll(
          RegExp(r'\s'),
          '',
        );

        if (otp.isNotEmpty) {
          otpDigits.assignAll(otp.split('').take(4).toList());
        } else {
          otpDigits.assignAll(['—', '—', '—', '—']);
        }
      } else {
        otpDigits.clear();
      }
    } else {
      driverName.value = 'Driver';
      driverPhone.value = '';
      driverAvatarUrl.value = '';
      driverRating.value = '—';
      if (isPinRequired.value) {
        otpDigits.assignAll(['—', '—', '—', '—']);
      } else {
        otpDigits.clear();
      }
    }

    if (v != null && vehicleSubtitle.value.isEmpty) {
      vehicleSubtitle.value =
          '${v.vehicleMake} ${v.vehicleModel}, ${v.vehicleColor}'.trim();
    }

    _applyUnifiedDriverVehicleLine(
      modelName: (d?.vehicleModel ?? '').trim(),
      plate: plateForVehicleLine,
      fallbackModel: (v?.vehicleModel ?? '').trim(),
    );
  }

  Future<void> _initRideRoomSocket() async {
    if (rideId.isEmpty) return;

    _connectionSub?.cancel();
    _rideStatusSub?.cancel();
    _driverLocSub?.cancel();
    _trackingSub?.cancel();
    _chatSub?.cancel();
    _rideStopsUpdatedSub?.cancel();
    _rideStopsUpdateFailedSub?.cancel();
    _paymentStatusSub?.cancel();
    _didJoinRideRoom = false;

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _joinRideRoomIfNeeded();
    });

    _rideStatusSub = _socketService.rideStatusStream.listen((payload) async {
      developer.log(
        "📥 Socket Event: ride_status_stream - Status: ${payload.status} for ride $rideId",
        name: 'ORDER_TRACKING',
        error: jsonEncode(payload.toJson()),
      );
      if (_navigatedAway) return;
      final status = (payload.status ?? '').toString().trim();
      _applyBottomSheetStateForStatus(status);
      _applyStatusPayload(payload);
      final normalized = status.toLowerCase();
      await _syncLiveActivityFromStatusPayload(payload);
      if (normalized == 'cancelled' || normalized == 'no_driver_found') {
        _navigatedAway = true;
        await LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(
          normalized == 'no_driver_found'
              ? AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr
              : AppStrings.rideCancelled.tr,
        );
      }
    });

    _rideStopSub = _socketService.rideStopUpdateStream.listen((payload) {
      if (_navigatedAway) return;
      _applyStatusPayload(payload);
    });

    _driverLocSub = _socketService.rideDriverLocationStream.listen((payload) {
      if (payload.latitude == 0 || payload.longitude == 0) return;
      // Strict city-region validation: Dar es Salaam is approx -6.8, 39.2
      if (payload.latitude! < -15 ||
          payload.latitude! > 0 ||
          payload.longitude! < 20 ||
          payload.longitude! > 50) {
        return;
      }

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
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((
      payload,
    ) async {
      if (payload != null) {
        developer.log(
          "📥 Socket Event: tracking_update_socket - Target: ${payload.routeTarget} for ride $rideId",
          name: 'ORDER_TRACKING',
          error: jsonEncode(payload.toJson()),
        );
        _applyTrackingPayload(payload);
      }
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
          title: AppStrings.newMessage.tr,
          body: msg.toString(),
          payload: jsonEncode(data),
        );
      }
    });

    _rideStopsUpdatedSub = _socketService.rideStopsUpdatedStream.listen((res) {
      if (res.rideId != rideId) return;
      _clearIdempotencyKey();
      isUpdatingStops.value = false;
      stopUpdateProgressStep.value = 3; // Success
      _fetchRideDetails();
    });

    _rideStopsUpdateFailedSub = _socketService.rideStopsUpdateFailedStream.listen((
      res,
    ) {
      if (res.rideId != rideId) return;
      _clearIdempotencyKey();
      isUpdatingStops.value = false;
      stopUpdateProgressStep.value = 0;

      String userMessage = res.reason;
      if (res.reason == 'da_patch_rejected') {
        userMessage =
            "Driver's app couldn't be updated. Your billing has been adjusted back.";
      } else if (res.reason == 'payment_failed') {
        userMessage = "Payment hold update failed. No charges applied.";
      }

      AppDialogs.showErrorDialog(title: 'Update Failed', message: userMessage);
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
      final asset = VehicleImageUtils.imageAssetForVehicleType(vehicleType);
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getResizedMarker(
        asset,
        150,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getResizedMarker(
        AppAssets.imgBoda,
        150,
      );
    }
  }

  void _showCancelDialogThenGoHome(String message) {
    AppDialogs.showErrorDialog(
      title: 'Ride Cancelled',
      message: message,
      onConfirm: () => Get.offAllNamed(AppRoutes.home),
    );
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

  void _syncBottomSheetVehicleImage(String? vehicleTypeHint) {
    final previousAsset = bottomSheetVehicleImageAsset.value;
    bottomSheetVehicleImageAsset
        .value = VehicleImageUtils.imageAssetForVehicleType(
      vehicleTypeHint,
      // Keep previously resolved vehicle image when an event payload
      // doesn't include enough vehicle metadata (common during stop transitions).
      fallbackAsset: previousAsset.isNotEmpty
          ? previousAsset
          : AppAssets.imgCab,
    );
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

      // Also include all stops for multi-stop rides to show the whole route
      final stops = ride.value?.stops ?? [];
      for (final s in stops) {
        points.add(LatLng(s.lat, s.lng));
      }
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
    String plateForVehicleLine = '';
    final vehicleTypeHint = _resolveVehicleTypeHint(
      driverVehicleType: d?.vehicleType,
      driverVehicleModel: d?.vehicleModel,
      vehicleDisplayName: v?.displayName,
      vehicleName: v?.vehicleName,
      vehicleType: v?.vehicleType,
    );
    _syncBottomSheetVehicleImage(vehicleTypeHint);
    if (vehicleTypeHint.isNotEmpty) {
      loadDriverIcon(vehicleType: vehicleTypeHint);
    }

    if (payload.pinRequired != null) {
      isPinRequired.value = payload.pinRequired == true;
    }

    if (d != null) {
      if ((d.name ?? '').trim().isNotEmpty) driverName.value = d.name!.trim();
      if ((d.phone ?? '').trim().isNotEmpty) {
        driverPhone.value = d.phone!.trim();
      }
      final avatar = (d.avatarUrl ?? '').trim();
      if (avatar.isNotEmpty) {
        driverAvatarUrl.value = avatar;
      }
      if ((d.lat) != null && (d.lng) != null) {
        assignedDriverLocation.value = LatLng(d.lat!, d.lng!);
      }
      if (isPinRequired.value) {
        final pin = (payload.pinCode ?? '').trim();
        final vCode = (payload.driverSnapshot?.verificationCode ?? '').trim();
        final otp = (pin.isNotEmpty ? pin : vCode).replaceAll(
          RegExp(r'\s'),
          '',
        );

        if (otp.isNotEmpty) {
          otpDigits.assignAll(otp.split('').take(4).toList());
        } else if (otpDigits.isEmpty) {
          otpDigits.assignAll(['—', '—', '—', '—']);
        }
      } else {
        otpDigits.clear();
      }
      final vehicleModel = (d.vehicleModel ?? '').trim();
      final vehicleColor = (d.vehicleColor ?? '').trim();
      final plate = (d.vehicleRegistrationNumber ?? '').trim();
      plateForVehicleLine = plate;

      if (vehicleModel.isNotEmpty || vehicleColor.isNotEmpty) {
        final subtitle = '$vehicleModel, $vehicleColor'
            .replaceAll(RegExp(r'(^,\s*|\s*,\s*$)'), '')
            .trim();
        if (subtitle.isNotEmpty) vehicleSubtitle.value = subtitle;
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

    _applyUnifiedDriverVehicleLine(
      modelName: (d?.vehicleModel ?? '').trim(),
      plate: plateForVehicleLine,
      fallbackModel: (v?.vehicleName ?? '').trim(),
    );

    if (!isPinRequired.value) {
      otpDigits.clear();
    }

    final oldStatus = currentRideStatus.value;
    final oldTarget = routeTarget.value;

    final target = _normalizeRouteTarget(payload.routeTarget);
    if (target == 'pick_up') {
      routeTarget.value = target;
      final coords = payload.routeGeometry?.coordinates;
      if (coords != null && coords.isNotEmpty && coords.length > 2) {
        routePoints.assignAll(_toLatLngPolyline(coords));
      }
    } else if (target == 'drop_off') {
      routeTarget.value = target;
      final coords = payload.routeGeometry?.coordinates;
      if (coords != null && coords.isNotEmpty && coords.length > 2) {
        routePoints.assignAll(_toLatLngPolyline(coords));
      }
    } else if (status.isNotEmpty) {
      // Active-ride entry can provide status without routeTarget.
      _applyRouteFallbackForStatus(status);
    }

    if (payload.currentStopIndex != null) {
      final currentRide = ride.value;
      if (currentRide != null) {
        ride.value = currentRide.copyWith(
          currentStopIndex: payload.currentStopIndex,
        );
      }
    }

    // Only re-fit camera if status or route target actually changed.
    // This prevents frequent zoom-outs on every location update.
    if (currentRideStatus.value != oldStatus ||
        routeTarget.value != oldTarget) {
      _fitRouteBounds();
    }
  }

  void _applyUnifiedDriverVehicleLine({
    required String modelName,
    required String plate,
    String fallbackModel = '',
  }) {
    final model = modelName.trim().isNotEmpty
        ? modelName.trim()
        : fallbackModel.trim();
    final registration = plate.trim();
    final line = [model, registration].where((e) => e.isNotEmpty).join(' - ');
    if (line.isNotEmpty) {
      driverVehicleLine.value = line;
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

    if (normalizedStatus == 'cancelled' ||
        normalizedStatus == 'no_driver_found') {
      return;
    }

    RideBottomSheetState nextState = RideBottomSheetState.driverAssigned;
    if (normalizedStatus == 'ride_started' ||
        normalizedStatus == 'ride_in_progress' ||
        normalizedStatus == 'near_destination' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'ride_completed') {
      nextState = RideBottomSheetState.rideStarted;
    }

    // Only allow state to move backwards if we are currently in 'rideCompleted'.
    // This maintains the fix for the "sticky finish button" while preventing
    // accidental regressions from 'rideStarted' back to 'driverAssigned'.
    final currentState = rideBottomSheetState.value;
    if (currentState == RideBottomSheetState.rideStarted &&
        nextState == RideBottomSheetState.driverAssigned) {
      return; // Block regression while trip is in progress
    }

    rideBottomSheetState.value = nextState;
    final isCompletedStatus =
        normalizedStatus == 'completed' || normalizedStatus == 'ride_completed';
    if (isCompletedStatus) {
      _openCompletedRideDetailsScreen();
    }
  }

  void _openCompletedRideDetailsScreen() {
    if (_openedCompletedRideDetails) return;
    final normalizedCurrentStatus = currentRideStatus.value
        .trim()
        .toLowerCase();
    if (normalizedCurrentStatus != 'completed' &&
        normalizedCurrentStatus != 'ride_completed') {
      return;
    }
    RideModel? currentRide = ride.value;
    if (currentRide == null) {
      _fetchRideDetails().whenComplete(_openCompletedRideDetailsScreen);
      return;
    }
    final normalizedRideModelStatus = currentRide.status.name
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)}_${m.group(2)}',
        )
        .toLowerCase();
    final isRideModelCompleted =
        normalizedRideModelStatus == 'completed' ||
        normalizedRideModelStatus == 'ride_completed';
    if (!isRideModelCompleted) {
      _fetchRideDetails().whenComplete(() {
        final refreshedRide = ride.value;
        if (refreshedRide == null) return;
        final refreshedStatus = refreshedRide.status.name
            .replaceAllMapped(
              RegExp(r'([a-z0-9])([A-Z])'),
              (m) => '${m.group(1)}_${m.group(2)}',
            )
            .toLowerCase();
        if (refreshedStatus == 'completed' ||
            refreshedStatus == 'ride_completed') {
          _openCompletedRideDetailsScreen();
        }
      });
      return;
    }
    // Normalize payload for details screen: force completed status and review UI.
    // Socket/status payloads can be slightly delayed, so we make this explicit.
    final completedRide = currentRide.copyWith(
      status: RideStatus.rideCompleted,
      showReviewUi: true,
    );
    _openedCompletedRideDetails = true;
    if (Get.isRegistered<RideDetailsController>()) {
      Get.delete<RideDetailsController>();
    }
    Get.off(
      () => RideDetailsScreen(
        ride: completedRide,
        openedFromCompletionFlow: true,
      ),
      binding: BindingsBuilder(
        () => Get.put(
          RideDetailsController(
            ride: completedRide,
            openedFromCompletionFlow: true,
          ),
        ),
      ),
    );
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
      return;
    }

    if (dropStatuses.contains(normalizedStatus)) {
      _setDropRouteFallback();
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
    final etaSeconds = currentEtaSeconds.value;
    final etaMinutes = etaSeconds > 0 ? (etaSeconds / 60).ceil() : 0;
    final hasEta = etaMinutes > 0;
    switch (currentRideStatus.value) {
      case 'near_destination':
        return hasEta
            ? 'Arrived in ${etaMinutes.toString()} mins'
            : 'Approaching your destination';
      case 'ride_in_progress':
        return hasEta
            ? 'Arrived in ${etaMinutes.toString()} mins'
            : 'Heading to your destination';
      case 'ride_started':
        return hasEta
            ? 'Arrived in ${etaMinutes.toString()} mins'
            : 'Trip has started';
      case 'driver_arrived':
        return 'Driver has reached pickup';
      case 'driver_arriving':
      case 'driver_assigned':
        return 'Driver is heading to pickup';
      case 'ride_completed':
      case 'completed':
        return arrivalDateLabel;
      default:
        return hasEta
            ? 'Arrived in ${etaMinutes.toString()} mins'
            : 'Trip has started';
    }
  }

  int get rideEtaMinutes {
    final etaSeconds = currentEtaSeconds.value;
    if (etaSeconds <= 0) return 0;
    return (etaSeconds / 60).ceil();
  }

  bool get shouldShowRideEtaBadge {
    final status = currentRideStatus.value;
    if (rideEtaMinutes <= 0) return false;
    return status == 'ride_started' ||
        status == 'ride_in_progress' ||
        status == 'near_destination';
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    final status = (payload.status ?? '').toString().trim().toLowerCase();
    if (status.isNotEmpty) {
      // Only trigger state updates from tracking payloads if it's a major transition.
      // High-frequency tracking often contains stale 'assigned' statuses.
      if (status.contains('started') ||
          status.contains('progress') ||
          status.contains('complete') ||
          status.contains('arrived')) {
        _applyBottomSheetStateForStatus(status);
      }
    }

    if (status == 'cancelled' || status == 'no_driver_found') {
      _navigatedAway = true;
      _showCancelDialogThenGoHome(
        status == 'no_driver_found'
            ? AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr
            : AppStrings.rideCancelled.tr,
      );
      return;
    }

    final eta = payload.eta;
    if (eta != null && eta > 0) {
      currentEtaSeconds.value = eta.toDouble();
      final convertedTime = eta / 60;
      etaLabel.value = '${convertedTime.toInt()} Mins';
      arrivalLabel.value =
          'Driver will arriving in ${convertedTime.toInt() <= 1 ? '1 min' : '${convertedTime.toInt()} mins'}...';
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
        }
      }
    } else if (target == 'drop_off') {
      routeTarget.value = target;
      if (coords != null && coords.isNotEmpty) {
        final newPoints = _toLatLngPolyline(coords);
        if (newPoints.length > 5) {
          routePoints.assignAll(newPoints);
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
      AppDialogs.showErrorDialog(
        title: AppStrings.call.tr,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    _showCallOptionsBottomSheet(phone);
  }

  void _showCallOptionsBottomSheet(String phone) {
    Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonBase,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.call.tr,
                    style: AppTextStyles.homeTitle.copyWith(
                      fontSize: 18.sp,
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                _callOptionTile(
                  title: 'In app calling',
                  icon: Icons.phone_in_talk_outlined,
                  onTap: () {
                    if (Get.isBottomSheetOpen ?? false) {
                      Get.back();
                    }
                    AppDialogs.showInfoDialog(
                      title: 'Coming soon',
                      message: 'In app calling will available soon',
                    );
                  },
                ),
                SizedBox(height: 10.h),
                _callOptionTile(
                  title: 'Normal call',
                  icon: Icons.call_outlined,
                  onTap: () {
                    if (Get.isBottomSheetOpen ?? false) {
                      Get.back();
                    }
                    _callDriverViaPhoneDialer(phone);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
    );
  }

  Widget _callOptionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textHeading, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.textHeading,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: AppColors.textMapHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callDriverViaPhoneDialer(String phone) async {
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
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint("Error launching dialer: $e");
      AppDialogs.showErrorDialog(
        title: AppStrings.call.tr,
        message: AppStrings.errorOpeningPhoneDialer.tr,
      );
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
    }
  }

  void setRideRating(int rating) {
    if (rating < 1 || rating > 5) return;
    selectedRideRating.value = rating;
  }

  Future<void> downloadSlip() async {
    if (rideId.isEmpty) return;
    try {
      AppDialogs.showLoadingDialog();
      final response = await rideRepository.getReceipt(rideId);
      final receiptModel = response.fold((l) => null, (r) => r);

      if (receiptModel == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppDialogs.showErrorDialog(message: 'Could not fetch receipt details.');
        return;
      }

      final rideData = ride.value;
      if (rideData == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        AppDialogs.showErrorDialog(message: 'Ride details are missing.');
        return;
      }

      final file = await ReceiptPdfGenerator.generateReceiptPdf(
        receipt: receiptModel,
      );

      if (Get.isDialogOpen ?? false) Get.back();
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        AppDialogs.showErrorDialog(
          message: 'Could not open PDF: ${result.message}',
        );
      }
    } catch (e, stackTrace) {
      if (Get.isDialogOpen ?? false) Get.back();
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppDialogs.showErrorDialog(
        message: 'Could not download slip. Please try again later.',
      );
    }
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
    return CurrencyFormatter.format(amount);
  }

  String get bookingFeeLabel {
    final amount =
        ride.value?.fareBreakdown?.bookingFee ?? _seedBookingFee ?? 0;
    return CurrencyFormatter.format(amount);
  }

  String get totalAmountLabel {
    final amount =
        ride.value?.fareBreakdown?.totalAmount ??
        _seedTotalAmount ??
        ride.value?.finalFare ??
        ride.value?.fareEstimate ??
        100;
    return CurrencyFormatter.format(amount);
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
      const CancelConfirmationDialog(),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );

    if (confirmResult != true) return;

    // 2. Reason Selection + Charges Fetch (keep first dialog open while loading)
    String? selectedReason;
    dynamic cancellationData;
    String selectedPolicyLabel = '';

    await Get.dialog<void>(
      CancelReasonSelectionDialog(
        reasons: [
          'Driver asked to cancel',
          'Driver asked to pay offline',
          'Taking too long to arrive',
          'Selected wrong pickup location',
          'Booked by mistake',
          'Others',
        ],
        isProcessing: isReasonProcessing,
        onContinueTap: (reason) async {
          if (rideId.isEmpty) {
            AppDialogs.showErrorDialog(
              title: AppStrings.cancelFailed.tr,
              message: AppStrings.rideIdIsMissing.tr,
            );
            return;
          }
          isReasonProcessing.value = true;
          final charges = await rideRepository.getCancellationCharges(rideId);
          isReasonProcessing.value = false;
          await charges.fold(
            (_) async {
              AppDialogs.showErrorDialog(
                title: AppStrings.cancelFailed.tr,
                message: AppStrings.couldNotCancelTryAgain.tr,
              );
            },
            (data) async {
              final selectedPolicy = data.policy.firstWhereOrNull(
                (p) =>
                    p.status.toLowerCase() == data.currentStatus.toLowerCase(),
              );
              selectedReason = reason;
              cancellationData = data;
              selectedPolicyLabel = selectedPolicy?.label ?? '';
              Get.back();
            },
          );
        },
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
    if (selectedReason == null || cancellationData == null) return;

    // 3. Charges dialog + Cancel API (loading on Cancel & Pay button)
    await Get.dialog<bool>(
      CancellationChargesDialog(
        canCancel: cancellationData.canCancel,
        cancellationFee: cancellationData.cancellationFee,
        netRefund: cancellationData.netRefund,
        policyLabel: selectedPolicyLabel,
        isProcessing: isCancelPayProcessing,
        onConfirmTap: () async {
          _navigatedAway = true;
          isCancelPayProcessing.value = true;
          final result = await rideRepository.cancelRide(
            rideId,
            'rider_cancelled',
          );
          isCancelPayProcessing.value = false;
          result.fold(
            (_) {
              _navigatedAway = false;
              AppDialogs.showErrorDialog(
                title: AppStrings.cancelFailed.tr,
                message: AppStrings.couldNotCancelTryAgain.tr,
              );
            },
            (success) async {
              if (success) {
                await Get.offAllNamed(AppRoutes.home);
                unawaited(LiveActivityManager().endActivity(rideId));
              } else {
                _navigatedAway = false;
                AppDialogs.showErrorDialog(
                  title: AppStrings.cancelFailed.tr,
                  message: AppStrings.pleaseTryAgain.tr,
                );
              }
            },
          );
        },
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
  }

  Future<void> _syncLiveActivityFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
  ) async {
    try {
      if (rideId.isEmpty) return;
      final status = (payload.status ?? '').toString().toUpperCase();

      // Handle termination for cancellation, but keep it alive for COMPLETED
      if (status.contains('CANCELLED') || status.contains('NO_DRIVER_FOUND')) {
        await LiveActivityManager().endActivity(rideId);
        return;
      }

      // If completed, sync one last time as isCompleted: true (handled by the handoff model update logic if needed,
      // but here we just ensure we don't 'END' it).
      if (status.contains('COMPLETED')) {
        // We can call update if we want to ensure the final UI shows,
        // or just return and let APNs handle the final 'true' state.
        // To be safe and responsive, we sync the final state.
        await LiveActivityManager().startActivity(
          orderId: rideId,
          status: status,
          isCompleted: true,
        );
        return;
      }

      // startActivity call removed to respect 'APNs-only' update model
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      developer.log(
        "❌ Error in DriverAcceptedController._syncLiveActivityFromStatusPayload: $e",
        name: 'ORDER_TRACKING',
      );
    }
  }

  // _syncLiveActivityFromTrackingPayload removed to respect 'APNs-only' update model

  Future<void> _syncLiveActivityFromDetails(RideModel r) async {
    try {
      if (rideId.isEmpty) return;

      // Convert enum status (e.g. driverAssigned) to backend-style (e.g. DRIVER_ASSIGNED)
      final statusStr = r.status.name
          .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'),
            (m) => '${m.group(1)}_${m.group(2)}',
          )
          .toUpperCase();

      await LiveActivityManager().startActivity(
        orderId: rideId,
        status: statusStr,
        driverName: r.driverSnapshot?.name ?? 'Driver Assigned',
        vehicleName:
            '${r.vehicleSnapshot?.vehicleType ?? ''} ${r.vehicleSnapshot?.vehicleModel ?? ''}'
                .trim(),
        driverAvatarUrl: r.driverSnapshot?.avatarUrl ?? '',
        plateNumber: r.vehicleSnapshot?.plateNumber ?? '',
        isCompleted: r.status == RideStatus.rideCompleted,
        etaSeconds: currentEtaSeconds.value,
        driverLatitude: assignedDriverLocation.value?.latitude,
        driverLongitude: assignedDriverLocation.value?.longitude,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint('❌ Error syncing Live Activity from Details: $e');
    }
  }

  bool isNearDestination() {
    return currentRideStatus.value.toLowerCase() == 'near_destination';
  }

  void onEditStops() {
    if (isUpdatingStops.value) {
      AppDialogs.showInfoDialog(
        title: 'Update in progress',
        message: 'A previous update is still being processed.',
      );
      return;
    }
    stopUpdateIdempotencyKey.value = Uuid().v4();
    Get.toNamed(AppRoutes.stopEditor, arguments: {'ride': ride.value});
  }

  Future<void> previewStopsUpdate(List<RideStopEntity> stops) async {
    isUpdatingStops.value = true;
    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await rideRepository.updateStops(
      rideId,
      stops: stopsJson,
      confirm: false,
      idempotencyKey: stopUpdateIdempotencyKey.value,
    );

    result.fold(
      (f) {
        isUpdatingStops.value = false;
        AppDialogs.showErrorDialog(title: 'Error', message: f.message);
      },
      (res) {
        if (res is StopUpdatePreviewModel) {
          stopUpdatePreview.value = res;
          // Generate key if not present and save it
          if (stopUpdateIdempotencyKey.value.isEmpty) {
            stopUpdateIdempotencyKey.value = const Uuid().v4();
          }
          _saveIdempotencyKey(stopUpdateIdempotencyKey.value);
        }
        isUpdatingStops.value = false;
      },
    );
  }

  Future<void> applyStopsUpdate(List<RideStopEntity> stops) async {
    final pending = ride.value?.pendingStopsUpdate;
    if (pending != null &&
        pending.status == 'pending_payment' &&
        pending.validationId != null) {
      // RESUME FLOW: Skip PUT /stops and go straight to payment dummy
      isUpdatingStops.value = true;
      await _processPaymentHold(pending.validationId!, pending.direction);
      return;
    }

    isUpdatingStops.value = true;
    stopUpdateProgressStep.value = 1; // Updating payment/Starting
    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await rideRepository.updateStops(
      rideId,
      stops: stopsJson,
      confirm: true,
      idempotencyKey: stopUpdateIdempotencyKey.value,
    );

    result.fold(
      (f) {
        _clearIdempotencyKey(); // Clear on failure
        isUpdatingStops.value = false;
        stopUpdateProgressStep.value = 0;
        AppDialogs.showErrorDialog(title: 'Error', message: f.message);
      },
      (res) async {
        if (res is StopUpdateAppliedModel) {
          stopUpdateApplied.value = res;
          await _processPaymentHold(
            res.blockUpdateValidationId ?? '',
            res.direction,
          );
        }
      },
    );
  }

  List<Map<String, dynamic>> _buildStopsPayloadForUpdate(
    List<RideStopEntity> stops,
  ) {
    final destination = ride.value?.destination;
    final destinationLat = destination?.lat ?? destinationLatLng.latitude;
    final destinationLng = destination?.lng ?? destinationLatLng.longitude;
    final destinationAddr = (destination?.address ?? destinationAddress).trim();

    final payload = <Map<String, dynamic>>[
      {
        'lat': destinationLat,
        'lng': destinationLng,
        'address': destinationAddr,
      },
    ];

    for (final stop in stops) {
      final sameAsDestinationByCoord =
          (stop.lat - destinationLat).abs() < 0.000001 &&
          (stop.lng - destinationLng).abs() < 0.000001;
      final sameAsDestinationByAddress =
          stop.address.trim().toLowerCase() == destinationAddr.toLowerCase();
      if (sameAsDestinationByCoord || sameAsDestinationByAddress) {
        continue;
      }
      payload.add({'lat': stop.lat, 'lng': stop.lng, 'address': stop.address});
    }

    return payload;
  }

  Future<void> _processPaymentHold(
    String validationId,
    String direction,
  ) async {
    if (direction == 'up') {
      stopUpdateProgressStep.value = 1; // Show payment step
      // For development, we use dummy payment as per guide
      await rideRepository.walletDummyPaymentRequest(
        DummyPaymentRequest(
          result: "SUCCESS",
          transId: 'TXN-${const Uuid().v4()}',
          validationId: validationId,
        ),
      );
    } else if (direction == 'down') {
      stopUpdateProgressStep.value = 2; // Jump to route update (silent payment)
    } else {
      stopUpdateProgressStep.value = 2; // Jump to route update (no payment)
    }

    // The socket listeners will handle the rest of the flow
    _startStopUpdateTimeout();
  }

  void _startStopUpdateTimeout() {
    Future.delayed(const Duration(seconds: 90), () {
      if (isUpdatingStops.value) {
        isUpdatingStops.value = false;
        stopUpdateProgressStep.value = 0;
        AppDialogs.showInfoDialog(
          title: 'Taking longer than expected',
          message: 'The update is taking some time. Please check back shortly.',
        );
        _fetchRideDetails();
      }
    });

    // Periodic poll fallback for socket events
    _pollForStopUpdateResult();
  }

  void _pollForStopUpdateResult() {
    Future.delayed(const Duration(seconds: 8), () {
      if (isUpdatingStops.value && stopUpdateProgressStep.value == 2) {
        _fetchRideDetails();
        _pollForStopUpdateResult();
      }
    });
  }

  Future<void> cancelStopUpdate() async {
    if (ride.value == null) return;

    // Optimistic UI close
    isUpdatingStops.value = false;
    stopUpdateProgressStep.value = 0;

    final result = await rideRepository.cancelPendingStops(rideId);
    result.fold(
      (f) => debugPrint("Failed to cancel stop update: ${f.message}"),
      (_) {
        _clearIdempotencyKey();
        _fetchRideDetails();
      },
    );
  }

  void _handleStopUpdateProgress(bool updating) {
    if (updating) {
      Get.bottomSheet(
        const StopUpdateProgressModal(),
        isDismissible: false,
        enableDrag: false,
        backgroundColor: AppColors.transparent,
      );
    } else {
      if (Get.isBottomSheetOpen ?? false) {
        if (stopUpdateProgressStep.value == 3) {
          Future.delayed(const Duration(seconds: 3), () {
            if (Get.isBottomSheetOpen ?? false) Get.back();
            stopUpdateProgressStep.value = 0;
          });
        } else {
          Get.back();
          stopUpdateProgressStep.value = 0;
        }
      }
    }
  }

  String priceFormatter(int? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,###').format(amount);
  }
}
