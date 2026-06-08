import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/ride_stops_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../../../../core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../../../../core/data/models/responses/payment_status_response/payment_status_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_map_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/address_display_utils.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/utils/map_vehicle_marker_utils.dart';
import '../../../../shared/utils/ride_active_navigation.dart';
import '../../../../shared/utils/ride_pickup_status_labels.dart';
import '../../../../shared/utils/ride_status_normalizer.dart';
import '../../../../shared/utils/tanzania_license_plate_formatter.dart';
import '../../../../shared/utils/tracking_route_geometry_utils.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../../shared/widgets/app_google_map.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/models/destination_update_models.dart';
import '../../data/models/emergency_contacts_response.dart';
import '../../data/models/stop_update_models.dart';
import '../../domain/repositories/ride_repository.dart';
import '../screens/ride_details_screen.dart';
import '../widgets/cancel_ride_dialogs.dart';
import '../widgets/ride_driver_call_options_sheet.dart';
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
  late LatLng destinationLatLng;
  late final String pickupAddress;
  late String destinationAddress;
  final summaryIntermediateStops = <String>[].obs;
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

  /// Formatted for UI, e.g. `T 123 ABC` (see [TanzaniaLicensePlateFormatter]).
  final plateDisplayFormatted = ''.obs;
  final vehicleSubtitle = ''.obs;
  final otpDigits = <String>[].obs;
  final isPinRequired = true.obs;
  final etaLabel = AppStrings.minutesShortCount.trParams({'count': '10'}).obs;
  final currentEtaSeconds = 0.0.obs;
  final arrivalLabel = AppStrings.driverWillArrivingInMinutes.trParams({
    'minutes': '1',
  }).obs;
  final unreadCount = 0.obs;
  final rideBottomSheetState = RideBottomSheetState.driverAssigned.obs;

  // Normalized ride status from socket/API — use [normalizeRideStatusString] when writing.
  final currentRideStatus = 'driver_assigned'.obs;
  final isReasonProcessing = false.obs;
  final isCancelPayProcessing = false.obs;

  final Rxn<BitmapDescriptor> assignedDriverMarkerIcon =
      Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> pickupIcon = Rxn<BitmapDescriptor>();
  final Rxn<BitmapDescriptor> dropIcon = Rxn<BitmapDescriptor>();
  final stopIcons = <BitmapDescriptor>[].obs;
  final Rxn<Offset> assignedDriverEtaScreenPx = Rxn<Offset>();
  final assignedDriverHeading = 0.0.obs;
  final assignedDriverSpeed = 0.0.obs; // m/s
  final Rxn<LatLng> animatedRiderLocation = Rxn<LatLng>();
  final RxBool isInitialRouteLoaded = false.obs;

  VoidCallback? onRecenterPressed;

  GoogleMapController? mapController;
  LatLng? _lastDriverRotationSamplePosition;
  bool _navigatedAway = false;
  DateTime? _lastCameraUpdate;
  bool _openedCompletedRideDetails = false;
  bool _hasReceivedTrackingUpdate = false;

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
  bool _emergencyContactsLoadedOnce = false;

  /// API-driven rows for the safety sheet (label = title, primary `phone` for `tel:`).
  final emergencyContacts = <EmergencyContactModel>[].obs;

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

  final RxBool isUpdatingDestination = false.obs;
  final RxBool isDestinationUpdateFlow = false.obs;
  final Rxn<DestinationUpdatePreviewModel> destinationUpdatePreview =
      Rxn<DestinationUpdatePreviewModel>();
  DestinationUpdateAppliedModel? _pendingDestinationAppliedAfterConfirm;
  StopUpdateAppliedModel? _pendingStopAppliedAfterConfirm;
  String? _pendingStopPaymentValidationId;
  String? _pendingStopPaymentDirection;
  double? _pendingDestinationTargetLat;
  double? _pendingDestinationTargetLng;

  void updateSheetSize(double size) {
    sheetSize.value = size;
  }

  String get formattedSpeedLabel {
    final speedKmh = (assignedDriverSpeed.value * 3.6).round();
    return speedKmh > 1 ? '$speedKmh km/h' : '';
  }

  final DraggableScrollableController sheetController =
      DraggableScrollableController();
  final RxBool isTrackingRider = false.obs;
  final GlobalKey<AppGoogleMapState> mapWidgetKey =
      GlobalKey<AppGoogleMapState>();

  @override
  void onInit() {
    super.onInit();
    sheetController.addListener(() {
      updateSheetSize(sheetController.size);
    });
    WidgetsBinding.instance.addObserver(this);
    _parseArgs();
    _bootstrap();
    ever(animatedRiderLocation, (_) => scheduleAssignedEtaOverlayRefresh());
    ever(routePoints, (List<LatLng> points) {
      if (isInitialRouteLoaded.value) return;
      final kind = TrackingRouteGeometryUtils.classifyFromPoints(points);
      if (kind == TrackingRouteGeometryKind.path) {
        recenterMap();
        _markInitialRouteReady();
      } else if (kind == TrackingRouteGeometryKind.repeatedLocation) {
        _markInitialRouteReady();
      }
    });
    ever(currentRideStatus, (status) {
      if (sheetController.isAttached) {
        final double target;
        if (status == 'near_destination') {
          target = 0.35;
        } else if (status == 'ride_in_progress' || status == 'ride_started') {
          target = 0.40;
        } else {
          target = 0.3;
        }
        if ((sheetController.size - target).abs() > 0.01) {
          Future.microtask(() {
            if (sheetController.isAttached) {
              sheetController.animateTo(
                target,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
    _loadPersistedIdempotencyKey();
    arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
      'minutes': '1',
    });
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

  /// Called once from [DriverAcceptedScreen] after first frame.
  Future<void> loadEmergencyContactsOnceOnScreenOpen() async {
    if (_emergencyContactsLoadedOnce) return;
    _emergencyContactsLoadedOnce = true;
    final result = await rideRepository.getEmergencyContacts();
    result.fold(
      (f) => developer.log(
        'emergency_contacts request failed',
        name: 'EmergencyContacts',
        error: f.message,
      ),
      (EmergencyContactsResponse res) {
        emergencyContacts.assignAll(res.data.contacts);
      },
    );
  }

  IconData emergencyContactIconFor(String id) {
    switch (id) {
      case 'police':
        return Icons.local_police_outlined;
      case 'selcom_go_support':
        return Icons.support_agent_outlined;
      default:
        return Icons.phone_in_talk_outlined;
    }
  }

  Future<void> dialEmergencyContact(EmergencyContactModel contact) async {
    final primary = contact.phone.trim();
    final secondary = contact.secondaryPhone?.trim() ?? '';
    final phone = primary.isNotEmpty ? primary : secondary;
    if (phone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: contact.label.isEmpty ? AppStrings.call.tr : contact.label,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    await _launchSystemPhoneDialer(
      phone: phone,
      errorDialogTitle: contact.label.isEmpty
          ? AppStrings.call.tr
          : contact.label,
    );
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
    final List<dynamic>? ds = args['destinations'];
    if (ds != null && ds.isNotEmpty) {
      try {
        // Normalize destinations payload from navigation:
        // last item = final destination, previous items = intermediate stops.
        final List<LocationEntity> locs = ds
            .map((e) {
              if (e is LocationEntity) return e;
              if (e is Map<String, dynamic>) {
                return LocationEntity(
                  lat: (e['lat'] as num?)?.toDouble() ?? 0.0,
                  lng: (e['lng'] as num?)?.toDouble() ?? 0.0,
                  address: (e['address'] as String?)?.trim() ?? '',
                );
              }
              if (e is Map) {
                final m = Map<String, dynamic>.from(e);
                return LocationEntity(
                  lat: (m['lat'] as num?)?.toDouble() ?? 0.0,
                  lng: (m['lng'] as num?)?.toDouble() ?? 0.0,
                  address: (m['address'] as String?)?.trim() ?? '',
                );
              }
              return null;
            })
            .whereType<LocationEntity>()
            .toList();

        if (locs.isNotEmpty) {
          final finalDestination = locs.last;
          if (finalDestination.lat != 0 && finalDestination.lng != 0) {
            destinationLatLng = LatLng(
              finalDestination.lat,
              finalDestination.lng,
            );
          }
          if (finalDestination.address.trim().isNotEmpty) {
            destinationAddress = finalDestination.address.trim();
          }
          summaryIntermediateStops.assignAll(
            locs
                .take(locs.length - 1)
                .map((e) => e.address.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          );
        }
      } catch (_) {}
    }
    final rawFareBreakdown = args['fareBreakdown'];
    if (rawFareBreakdown is Map) {
      final fareBreakdown = Map<String, dynamic>.from(rawFareBreakdown);
      _seedRideCharge = (fareBreakdown['ride_charge'] as num?)?.toInt();
      _seedBookingFee = (fareBreakdown['booking_fee'] as num?)?.toInt();
      _seedTotalAmount = (fareBreakdown['total_amount'] as num?)?.toInt();
    }
    routePoints.clear();
    routeTarget.value = 'pick_up';
    _hydrateSocketSeedPayloads(args);
    _refreshMapRouteHeader();
  }

  void _setDropRouteFallback() {
    routeTarget.value = 'drop_off';
    routePoints.assignAll([pickupLatLng, destinationLatLng]);
  }

  void _setPickupRouteFallback() {
    routeTarget.value = 'pick_up';
    final driver = assignedDriverLocation.value;
    if (driver != null) {
      routePoints.assignAll([driver, pickupLatLng]);
      return;
    }
    routePoints.assignAll([pickupLatLng, destinationLatLng]);
  }

  void _markInitialRouteReady() {
    if (!isInitialRouteLoaded.value) {
      isInitialRouteLoaded.value = true;
    }
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
      _hasReceivedTrackingUpdate = true;
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

  void _syncDestinationFromRide(RideModel? r) {
    if (r == null) return;
    final d = r.destination;
    if (d.lat != 0 && d.lng != 0) {
      destinationLatLng = LatLng(d.lat, d.lng);
    }
    final addr = d.address.trim();
    if (addr.isNotEmpty && addr != destinationAddress) {
      destinationAddress = addr;
      _refreshMapRouteHeader();
    }
    final stops = r.stops;
    if (stops.isEmpty) {
      summaryIntermediateStops.clear();
      return;
    }
    final normalizedDestinationAddress = destinationAddress
        .trim()
        .toLowerCase();
    final last = stops.last;
    final lastMatchesDestinationByAddress =
        normalizedDestinationAddress.isNotEmpty &&
        last.address.trim().toLowerCase() == normalizedDestinationAddress;
    final lastMatchesDestinationByCoord =
        (last.lat - destinationLatLng.latitude).abs() < 0.000001 &&
        (last.lng - destinationLatLng.longitude).abs() < 0.000001;
    // If backend stops includes final destination, exclude it from
    // intermediate summary list to avoid duplicate rendering in header card.
    final lastIsDestination =
        lastMatchesDestinationByAddress || lastMatchesDestinationByCoord;

    final intermediates = lastIsDestination
        ? stops.take(stops.length - 1).toList()
        : stops;
    summaryIntermediateStops.assignAll(
      intermediates
          .map((s) => s.address.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

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
        _syncDestinationFromRide(r);
        // HTTP details can show completion before/without a matching socket tick;
        // keep bottom-sheet state and completion navigation in sync with the model.
        _applyBottomSheetStateForStatus(rideStatusToApiValue(r.status));
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
            stopUpdateProgressStep.value = 0;
            isUpdatingStops.value = false;
          } else if (stopUpdateWorkingStops.isNotEmpty &&
              r.stops.length == stopUpdateWorkingStops.length) {
            // Also succeed if the confirmed stops list now matches our target list count
            _clearIdempotencyKey();
            stopUpdateProgressStep.value = 0;
            isUpdatingStops.value = false;
          }
        }

        if (isUpdatingDestination.value && stopUpdateProgressStep.value == 2) {
          final dest = r.destination;
          final tLat = _pendingDestinationTargetLat;
          final tLng = _pendingDestinationTargetLng;
          if (tLat != null &&
              tLng != null &&
              (dest.lat - tLat).abs() < 0.00002 &&
              (dest.lng - tLng).abs() < 0.00002) {
            stopUpdateProgressStep.value = 0;
            isUpdatingDestination.value = false;
            isDestinationUpdateFlow.value = false;
            _pendingDestinationTargetLat = null;
            _pendingDestinationTargetLng = null;
            _setDropRouteFallback();
          }
        }
      },
    );
    isLoadingRide.value = false;
    // Removed automatic _fitRouteBounds here to prevent unwanted zoom-out during navigation.
  }

  void _applyMockContent() {
    driverName.value = 'John Doe';
    driverPhone.value = '';
    driverAvatarUrl.value = '';
    bottomSheetVehicleImageAsset.value = AppAssets.imgBoda;
    driverRating.value = '4';
    driverVehicleLine.value = 'Volkswagen';
    plateDisplayFormatted.value = TanzaniaLicensePlateFormatter.formatDisplay(
      'T772BBE',
    );
    vehicleSubtitle.value = 'Toyota corolla, White';
    otpDigits.assignAll(['2', '7', '5', '6']);
    arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
      'minutes': '1',
    });
    currentRideStatus.value = 'driver_assigned';
  }

  void _applyRide(RideModel r) {
    isPinRequired.value = r.pinRequired;
    final d = r.driverSnapshot as DriverSnapshotModel?;
    final v = r.vehicleSnapshot;
    String plateForVehicleLine = '';
    _syncBottomSheetVehicleImage(d?.vehicleType);
    if ((d?.vehicleType ?? '').isNotEmpty) {
      loadDriverIcon(vehicleType: d?.vehicleType);
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
        plateDisplayFormatted.value =
            TanzaniaLicensePlateFormatter.formatDisplay(plate);
      } else {
        plateDisplayFormatted.value = '';
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
      driverName.value = AppStrings.driver.tr;
      driverPhone.value = '';
      driverAvatarUrl.value = '';
      driverRating.value = '—';
      plateDisplayFormatted.value = '';
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

    // Primary realtime status feed — always normalize before comparing.
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
      final normalized = normalizeRideStatusString(status);
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

      // Strict city-region validation for Dar es Salaam
      if (payload.latitude! < -15 ||
          payload.latitude! > 0 ||
          payload.longitude! < 20 ||
          payload.longitude! > 50) {
        return;
      }

      final lat = payload.latitude;
      final lng = payload.longitude;
      final head = payload.heading;
      final speed = (payload.speed ?? 0.0).toDouble(); // m/s
      if (lat == null || lng == null) return;

      final rawPos = LatLng(lat, lng);

      // 1. Update the base location with RAW GPS
      assignedDriverLocation.value = rawPos;
      assignedDriverSpeed.value = speed;

      // 2. High-Fidelity Interpolation:
      // We calculate duration based on REAL speed for a butter-smooth glide.
      Duration animDuration = const Duration(milliseconds: 3500);

      if (speed > 0.5) {
        final currentPos =
            mapWidgetKey.currentState?.currentAnimatedPosition ??
            assignedDriverLocation.value!;
        final distance = _calculateDistanceInMeters(currentPos, rawPos);

        // 🏎️ High-Speed Optimization:
        // Use a tighter buffer (5% instead of 15%) to prevent lag accumulation.
        // Cap duration more aggressively at 5s to force catch-up.
        double secondsNeeded = (distance / speed) * 1.05;
        int millis = (secondsNeeded * 1000).toInt();

        millis = millis.clamp(1200, 5000);
        animDuration = Duration(milliseconds: millis);
      } else {
        // If slow or stopped, use a more conservative 4s glide to match
        // the typical 3-5s socket frequency.
        animDuration = const Duration(milliseconds: 4000);
      }

      final parsedHeading = MapVehicleMarkerUtils.parseHeadingDegrees(head);
      final rotationFrom =
          _lastDriverRotationSamplePosition ??
          mapWidgetKey.currentState?.currentAnimatedPosition;

      assignedDriverHeading.value = MapVehicleMarkerUtils.resolveMarkerRotation(
        previousPosition: rotationFrom,
        currentPosition: rawPos,
        headingDegrees: parsedHeading,
        previousRotation: assignedDriverHeading.value,
        speedMps: speed,
      );

      if (rotationFrom != null) {
        final moved = _calculateDistanceInMeters(rotationFrom, rawPos);
        if (moved >= MapVehicleMarkerUtils.minMovementMetersForBearing) {
          _lastDriverRotationSamplePosition = rawPos;
        }
      } else {
        _lastDriverRotationSamplePosition = rawPos;
      }

      mapWidgetKey.currentState?.updateRiderPosition(
        rawPos,
        rotation: assignedDriverHeading.value,
        duration: animDuration,
      );
    });

    _trackingSub = _socketService.trackingUpdateStatusStream.listen((
      payload,
    ) async {
      if (payload != null) {
        _hasReceivedTrackingUpdate = true;
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

        final msg = data['message'] ?? data['text'] ?? AppStrings.newMessage.tr;

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
      stopUpdateProgressStep.value = 0;
      _fetchRideDetails();
    });

    _rideStopsUpdateFailedSub = _socketService.rideStopsUpdateFailedStream
        .listen((res) {
          if (res.rideId != rideId) return;
          _clearIdempotencyKey();
          isUpdatingStops.value = false;
          stopUpdateProgressStep.value = 0;

          String userMessage = res.reason;
          if (res.reason == 'da_patch_rejected') {
            userMessage =
                AppStrings.driversAppCouldntBeUpdatedBillingAdjustedBack.tr;
          } else if (res.reason == 'payment_failed') {
            userMessage = AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr;
          }

          AppDialogs.showErrorDialog(
            title: AppStrings.updateFailed.tr,
            message: userMessage,
          );
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
      final assetPath = MapVehicleMarkerUtils.markerAssetForVehicleType(
        vehicleType,
      );
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        assetPath,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    } catch (e, stackTrace) {
      developer.log(
        "Error loading map marker icon ($vehicleType): $e",
        error: e,
        stackTrace: stackTrace,
      );
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        AppAssets.mapMarkerCab,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    }
  }

  void _showCancelDialogThenGoHome(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDialogs.showErrorDialog(
        title: AppStrings.rideCancelled.tr,
        message: message,
        onConfirm: () => Get.offAllNamed(AppRoutes.home),
      );
    });
  }

  void _syncBottomSheetVehicleImage(String? vehicleType) {
    final previousAsset = bottomSheetVehicleImageAsset.value;
    bottomSheetVehicleImageAsset
        .value = VehicleImageUtils.imageAssetForVehicleType(
      vehicleType,
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
    final pos = animatedRiderLocation.value ?? assignedDriverLocation.value;
    if (ctrl == null || pos == null) {
      assignedDriverEtaScreenPx.value = null;
      return;
    }
    final px = await AppMapService.screenOffsetFor(ctrl, pos);
    assignedDriverEtaScreenPx.value = px;
  }

  void recenterMap() {
    if (onRecenterPressed != null) {
      onRecenterPressed!();
    } else {
      _fitRouteBounds(force: true);
    }
  }

  Future<void> focusOnUserLocation() async {
    final ctrl = mapController;
    if (ctrl == null) return;

    try {
      // We rely on the Google Map internal "my location" feature to animate
      // but we can also manually trigger it if we have the coordinates.
      // For now, we'll trigger a fitBounds on the whole route as a fallback
      // but the UI button is now decoupled from Rider Tracking.
      _fitRouteBounds(force: true);
    } catch (e) {
      developer.log("Error focusing on user location: $e");
    }
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

    try {
      // Ensure the bounds have at least some area to prevent rendering glitches
      double latDelta = (maxLat - minLat).abs();
      double lngDelta = (maxLng - minLng).abs();
      if (latDelta < 0.001) {
        minLat -= 0.001;
        maxLat += 0.001;
      }
      if (lngDelta < 0.001) {
        minLng -= 0.001;
        maxLng += 0.001;
      }

      await ctrl.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          72, // Slightly more padding for comfort
        ),
      );
    } catch (e) {
      // Fallback if bounds animation fails
      if (points.isNotEmpty) {
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      }
    }
  }

  /// Applies driver/vehicle/PIN/route data from a status payload (socket or navigation seed).
  void _applyStatusPayload(EventRiderStatusUpdateResponse payload) {
    final status = (payload.status ?? '').toString().trim();
    if (status.isNotEmpty) {
      _applyBottomSheetStateForStatus(status);
      _applyRouteFallbackForStatus(status);
    }

    final d = payload.driverSnapshot;
    final v = payload.vehicleSnapshot;
    String plateForVehicleLine = '';
    _syncBottomSheetVehicleImage(d?.vehicleType);
    if ((d?.vehicleType ?? '').isNotEmpty) {
      loadDriverIcon(vehicleType: d?.vehicleType);
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
        plateDisplayFormatted.value =
            TanzaniaLicensePlateFormatter.formatDisplay(plate);
      } else {
        plateDisplayFormatted.value = '';
      }
    }

    _applyUnifiedDriverVehicleLine(
      modelName: (d?.vehicleModel ?? '').trim(),
      plate: plateForVehicleLine,
      fallbackModel: (v?.vehicleName ?? '').trim(),
    );

    _applyDriverRatingFromStatusPayload(payload, d);

    if (!isPinRequired.value) {
      otpDigits.clear();
    }

    final oldStatus = currentRideStatus.value;
    final oldTarget = routeTarget.value;

    final target = _normalizeRouteTarget(payload.routeTarget);
    final routeTargetChanged = target.isNotEmpty && target != oldTarget;
    _applyRouteGeometryFromPayload(
      routeTarget: target,
      coordinates: payload.routeGeometry?.coordinates,
      fitCameraOnChange: status != oldStatus || routeTargetChanged,
    );
    if (target.isEmpty && status.isNotEmpty) {
      // Active-ride entry can provide status without routeTarget.
      _applyRouteFallbackForStatus(status);
      if (status != oldStatus || routeTarget.value != oldTarget) {
        _fitRouteBounds();
      }
    }

    if (payload.currentStopIndex != null) {
      final currentRide = ride.value;
      if (currentRide != null) {
        ride.value = currentRide.copyWith(
          currentStopIndex: payload.currentStopIndex,
        );
      }
    }

    final rootEta = payload.etaSeconds;
    if (rootEta != null && rootEta.toDouble() > 0) {
      _applySocketEtaSecondsToLabels(rootEta.toDouble(), skipIfArrived: true);
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
    final rawRegistration = plate.trim();
    final registration = rawRegistration.isEmpty
        ? ''
        : TanzaniaLicensePlateFormatter.formatDisplay(rawRegistration);
    final line = [model, registration].where((e) => e.isNotEmpty).join(' - ');
    if (line.isNotEmpty) {
      driverVehicleLine.value = line;
    }
  }

  /// Prefer root `driver_avg_rating` from [ride:status_update], then snapshot `rating`.
  void _applyDriverRatingFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
    DriverSnapshot? d,
  ) {
    final fromRoot = _socketAverageRatingLabel(payload.driverAvgRating);
    if (fromRoot != null) {
      driverRating.value = fromRoot;
      return;
    }
    final snap = d?.rating;
    if (snap != null && snap > 0) {
      driverRating.value = snap.toStringAsFixed(1);
    }
  }

  String? _socketAverageRatingLabel(num? raw) {
    if (raw == null) return null;
    final v = raw.toDouble();
    if (v <= 0) return null;
    return v.toStringAsFixed(1);
  }

  /// Maps status → bottom sheet variant (pickup vs in-trip) and updates [currentRideStatus].
  void _applyBottomSheetStateForStatus(String rawStatus) {
    final normalizedStatus = normalizeRideStatusString(rawStatus);
    if (normalizedStatus.isEmpty) return;
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
    if (normalizedStatus == 'driver_arrived') {
      _syncDriverArrivedPickupMessages();
    }
    final isCompletedStatus =
        normalizedStatus == 'completed' || normalizedStatus == 'ride_completed';
    if (isCompletedStatus) {
      _openCompletedRideDetailsScreen();
    }
  }

  /// Driver name for localized ride-status copy; falls back to generic "Driver".
  String get localizedDriverNameForCopy {
    final name = driverName.value.trim();
    return name.isNotEmpty ? name : AppStrings.driver.tr;
  }

  /// Pickup sheet + map chip copy when the driver is at pickup ([driver_arrived]).
  void _syncDriverArrivedPickupMessages() {
    arrivalLabel.value = AppStrings.driverArrivedPickupPrimary.tr;
    etaLabel.value = AppStrings.driverArrivedMapBadge.tr;
  }

  /// Second line on the driver-assigned pickup sheet (below the ETA row).
  ///
  /// Pickup progression: assigned → arriving → arrived (see [RidePickupStatusLabels]).
  String get driverPickupPhaseHeadline {
    switch (currentRideStatus.value) {
      case 'driver_arrived':
        return AppStrings.yourDriverHasArrived.tr;
      case 'driver_arriving':
        return AppStrings.driverHeadingTowardsYou.tr;
      case 'driver_assigned':
      case 'accepted':
        return AppStrings.driverHasAcceptedYourRide.tr;
      default:
        return AppStrings.driverIsHeadingToYourLocation.tr;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.off(
        () => RideDetailsScreen(
          ride: completedRide,
          openedFromCompletionFlow: true,
        ),
        binding: BindingsBuilder(() {
          Get.put(
            RideDetailsController(
              ride: completedRide,
              openedFromCompletionFlow: true,
            ),
          );
        }),
      );
    });
  }

  void _applyRouteFallbackForStatus(String rawStatus) {
    if (!_hasReceivedTrackingUpdate) return;
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

  /// In-trip sheet headline. Pickup-phase titles use [RidePickupStatusLabels] in `default`.
  String get rideProgressTitle {
    switch (currentRideStatus.value) {
      case 'ride_completed':
      case 'completed':
        return AppStrings.youHaveArrived.tr;
      case 'near_destination':
        return AppStrings.youAreAlmostThere.tr;
      case 'ride_in_progress':
        return AppStrings.onYourWayWithDriver.trParams({
          'driverName': localizedDriverNameForCopy,
        });
      case 'ride_started':
        return AppStrings.driverStartedYourRide.trParams({
          'driverName': localizedDriverNameForCopy,
        });
      default:
        return RidePickupStatusLabels.titleFor(currentRideStatus.value);
    }
  }

  /// In-trip / pickup supporting line (ETA-aware where applicable).
  String get rideProgressSubtitle {
    final etaSeconds = currentEtaSeconds.value;
    final etaMinutes = etaSeconds > 0 ? (etaSeconds / 60).ceil() : 0;
    final hasEta = etaMinutes > 0;
    switch (currentRideStatus.value) {
      case 'near_destination':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.approachingYourDestination.tr;
      case 'ride_in_progress':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.headingToYourDestination.tr;
      case 'ride_started':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.tripHasStarted.tr;
      case 'driver_arrived':
        return AppStrings.driverArrivedPickupPrimary.tr;
      case 'driver_arriving':
        return AppStrings.driverHeadingTowardsYou.tr;
      case 'driver_assigned':
        return AppStrings.driverAssignedDescription.tr;
      case 'ride_completed':
      case 'completed':
        return arrivalDateLabel;
      default:
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.tripHasStarted.tr;
    }
  }

  int get rideEtaMinutes {
    final etaSeconds = currentEtaSeconds.value;
    if (etaSeconds <= 0) return 0;
    return (etaSeconds / 60).ceil();
  }

  /// Pickup-phase statuses: map chip + driver-assigned sheet use same rule.
  bool _isDriverHeadingToPickupForEta(String rideStatusRaw) {
    final s = normalizeRideStatusString(rideStatusRaw);
    if (s.isEmpty || s == 'driver_arrived') return false;
    return s == 'driver_assigned' ||
        s == 'driver_arriving' ||
        s == 'accepted' ||
        s == 'driver_en_route' ||
        s == 'en_route';
  }

  void _applySocketEtaSecondsToLabels(
    double etaSeconds, {
    required bool skipIfArrived,
  }) {
    if (skipIfArrived &&
        normalizeRideStatusString(currentRideStatus.value) ==
            'driver_arrived') {
      return;
    }
    if (etaSeconds <= 0) return;
    currentEtaSeconds.value = etaSeconds;
    final minutes = (etaSeconds / 60).ceil();
    etaLabel.value = AppStrings.minutesShortCount.trParams({
      'count': '$minutes',
    });
    final rideStatus = normalizeRideStatusString(currentRideStatus.value);
    if (_isDriverHeadingToPickupForEta(rideStatus)) {
      arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
    }
  }

  /// Driver-assigned sheet first line — matches map chip math on [currentEtaSeconds].
  String get driverAssignedSheetArrivalEtaLine {
    final st = normalizeRideStatusString(currentRideStatus.value);
    if (st == 'driver_arrived') {
      return arrivalLabel.value;
    }
    final secs = currentEtaSeconds.value;
    if (secs > 0 && _isDriverHeadingToPickupForEta(st)) {
      final minutes = (secs / 60).ceil();
      return AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
    }
    return arrivalLabel.value;
  }

  bool get shouldShowRideEtaBadge {
    final status = currentRideStatus.value;
    if (rideEtaMinutes <= 0) return false;
    return status == 'ride_started' ||
        status == 'ride_in_progress' ||
        status == 'near_destination';
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    final trackingStatus = (payload.status ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (trackingStatus.isNotEmpty) {
      // Only trigger state updates from tracking payloads if it's a major transition.
      // High-frequency tracking often contains stale 'assigned' statuses.
      if (trackingStatus.contains('started') ||
          trackingStatus.contains('progress') ||
          trackingStatus.contains('complete') ||
          trackingStatus.contains('arrived')) {
        _applyBottomSheetStateForStatus(trackingStatus);
      }
    }

    if (trackingStatus == 'cancelled' || trackingStatus == 'no_driver_found') {
      _navigatedAway = true;
      _showCancelDialogThenGoHome(
        trackingStatus == 'no_driver_found'
            ? AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr
            : AppStrings.rideCancelled.tr,
      );
      return;
    }

    final isPickupArrived = trackingStatus == 'driver_arrived';
    if (isPickupArrived) {
      _syncDriverArrivedPickupMessages();
    }

    final eta = payload.eta;
    if (eta != null) {
      final etaSecs = eta.toDouble();
      if (!isPickupArrived && etaSecs > 0) {
        _applySocketEtaSecondsToLabels(etaSecs, skipIfArrived: false);
      } else if (!isPickupArrived && etaSecs <= 0) {
        final statusForEta = (payload.status ?? currentRideStatus.value)
            .toLowerCase();
        final inRide =
            statusForEta.contains('progress') ||
            statusForEta.contains('started');
        etaLabel.value = inRide ? AppStrings.nearby.tr : AppStrings.arriving.tr;
        arrivalLabel.value = inRide
            ? AppStrings.youAreAlmostThere.tr
            : AppStrings.driverIsArriving.tr;
      }
    }

    var target = _normalizeRouteTarget(payload.routeTarget);
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

    _applyRouteGeometryFromPayload(
      routeTarget: target,
      coordinates: coords,
      fitCameraOnChange: true,
    );
  }

  /// Applies `route_geometry` from tracking/status payloads without re-fitting on duplicates.
  void _applyRouteGeometryFromPayload({
    required String routeTarget,
    required List<List<double>>? coordinates,
    required bool fitCameraOnChange,
  }) {
    if (routeTarget != 'pick_up' && routeTarget != 'drop_off') return;

    this.routeTarget.value = routeTarget;
    if (!_hasReceivedTrackingUpdate) return;

    final kind = TrackingRouteGeometryUtils.classify(coordinates);
    switch (kind) {
      case TrackingRouteGeometryKind.empty:
        _markInitialRouteReady();
        if (_hasReceivedTrackingUpdate) {
          if (routeTarget == 'pick_up') {
            _setPickupRouteFallback();
          } else {
            _setDropRouteFallback();
          }
          if (fitCameraOnChange) _fitRouteBounds();
        } else if (routePoints.isNotEmpty) {
          routePoints.clear();
        }
        return;
      case TrackingRouteGeometryKind.repeatedLocation:
      case TrackingRouteGeometryKind.path:
        final nextPoints = TrackingRouteGeometryUtils.pointsForMap(coordinates);
        _markInitialRouteReady();
        if (TrackingRouteGeometryUtils.routesEquivalent(
          routePoints,
          nextPoints,
        )) {
          return;
        }
        routePoints.assignAll(nextPoints);
        if (fitCameraOnChange &&
            kind == TrackingRouteGeometryKind.path &&
            nextPoints.length >= 2) {
          _fitRouteBounds();
        }
        return;
    }
  }

  /// Calculates the distance between two points in meters using Haversine formula.
  double _calculateDistanceInMeters(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final double dLng = _degreesToRadians(p2.longitude - p1.longitude);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(p1.latitude)) *
            math.cos(_degreesToRadians(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  String _normalizeRouteTarget(String? target) {
    final t = (target ?? '').trim().toLowerCase();
    if (t == 'pickup' || t == 'pick_up') return 'pick_up';
    if (t == 'dropoff' || t == 'drop_off' || t == 'destination') {
      return 'drop_off';
    }
    return '';
  }

  void openProfile() {
    Get.to(() => ProfileScreen());
  }

  /// Places an in-app voice call to the assigned driver using the Agora
  /// calling package. Falls back to the system phone dialer when the package
  /// flow isn't available (no Agora App ID, ride id missing, etc.).
  Future<void> callDriver() async {
    final id = rideId;
    if (id.isEmpty) {
      return;
    }
    RideDriverCallOptionsSheet.show(
      rideId: id,
      peerDisplayName: driverName.value,
      driverPhone: driverPhone.value,
      peerAvatarUrl: driverAvatarUrl.value.trim().isEmpty
          ? null
          : driverAvatarUrl.value,
    );
  }

  /// Opens the OS phone app with [phone] (`tel:`). [errorDialogTitle] uses API `label` for emergency rows.
  Future<void> _launchSystemPhoneDialer({
    required String phone,
    required String errorDialogTitle,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: errorDialogTitle,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      debugPrint("Error launching dialer: $e");
      AppDialogs.showErrorDialog(
        title: errorDialogTitle,
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
        'driverSubtitle': plateDisplayFormatted.value,
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

  static const String mapRouteHeaderId = 'map_route_header';

  String get mapRoutePickupLabel {
    if (pickupAddress.trim().isEmpty) {
      return AppStrings.currentLocation.tr;
    }
    final line = compactAddressLine(pickupAddress);
    return line.isEmpty ? AppStrings.currentLocation.tr : line;
  }

  String get mapRouteDestinationLabel {
    if (destinationAddress.trim().isEmpty) {
      return AppStrings.destination.tr;
    }
    final line = compactAddressLine(destinationAddress);
    return line.isEmpty ? AppStrings.destination.tr : line;
  }

  void _refreshMapRouteHeader() => update([mapRouteHeaderId]);

  String get pickupTitle => _firstAddressLine(pickupAddress);

  String get destinationTitle => _firstAddressLine(destinationAddress);

  String get rideVehicleLabel {
    final value = driverVehicleLine.value.trim();
    if (value.isNotEmpty) return value.split('-').first.trim();
    return AppStrings.boda.tr;
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
        return AppStrings.mobileMoney.tr;
      case 'selcomPesa':
        return AppStrings.selcomPesa.tr;
      case 'card':
        return AppStrings.card.tr;
      default:
        return AppStrings.wallet.tr;
    }
  }

  String _firstAddressLine(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return AppStrings.unknownLocation.tr;
    return trimmed.split(',').first.trim();
  }

  Future<void> confirmCancelRide() async {
    // 1. Initial Confirmation
    final dynamic confirmResult = await AppDialogs.showAnimatedDialog(
      child: const CancelConfirmationDialog(),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );

    if (confirmResult != true) return;

    // 2. Reason Selection + Charges Fetch (keep first dialog open while loading)
    String? selectedReason;
    dynamic cancellationData;
    String selectedPolicyLabel = '';

    await AppDialogs.showAnimatedDialog<void>(
      child: CancelReasonSelectionDialog(
        reasons: [
          AppStrings.cancelReasonDriverAskedCancel.tr,
          AppStrings.cancelReasonDriverPayOffline.tr,
          AppStrings.cancelReasonTakingTooLongArrive.tr,
          AppStrings.cancelReasonWrongPickupLocation.tr,
          AppStrings.cancelReasonBookedByMistake.tr,
          AppStrings.cancelReasonOthers.tr,
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
          await Loader.withFlag(isReasonProcessing, () async {
            final charges = await rideRepository.getCancellationCharges(rideId);
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
                      p.status.toLowerCase() ==
                      data.currentStatus.toLowerCase(),
                );
                selectedReason = reason;
                cancellationData = data;
                selectedPolicyLabel = selectedPolicy?.label ?? '';
                Get.back();
              },
            );
          });
        },
      ),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBlack12,
    );
    if (selectedReason == null || cancellationData == null) return;

    // 3. Charges dialog + Cancel API (loading on Cancel & Pay button)
    await AppDialogs.showAnimatedDialog<bool>(
      child: CancellationChargesDialog(
        canCancel: cancellationData.canCancel,
        cancellationFee: cancellationData.cancellationFee,
        netRefund: cancellationData.netRefund,
        policyLabel: selectedPolicyLabel,
        isProcessing: isCancelPayProcessing,
        onConfirmTap: () async {
          _navigatedAway = true;
          var cancelSucceeded = false;
          await Loader.withFlag(isCancelPayProcessing, () async {
            final result = await rideRepository.cancelRide(
              rideId,
              selectedReason!,
            );
            result.fold(
              (_) {
                _navigatedAway = false;
                AppDialogs.showErrorDialog(
                  title: AppStrings.cancelFailed.tr,
                  message: AppStrings.couldNotCancelTryAgain.tr,
                );
              },
              (success) {
                if (success) {
                  cancelSucceeded = true;
                } else {
                  _navigatedAway = false;
                  AppDialogs.showErrorDialog(
                    title: AppStrings.cancelFailed.tr,
                    message: AppStrings.pleaseTryAgain.tr,
                  );
                }
              },
            );
          });
          if (!cancelSucceeded) return;
          await AppDialogs.navigateHomeReplacingStack();
          unawaited(LiveActivityManager().endActivity(rideId));
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
      final status = (payload.status ?? '').toString().trim().toUpperCase();

      // Handle Terminal States
      if (status.contains('CANCELLED') || status.contains('NO_DRIVER_FOUND')) {
        await LiveActivityManager().endActivity(rideId);
        return;
      }

      // 📝 Only CREATE if not already tracking (iOS only).
      // For iOS, subsequent updates are handled by the backend via APNs push.
      // For Android, we must continue to push updates from Dart.
      if (Platform.isIOS && LiveActivityManager().isTracking(rideId)) return;

      // If completed, sync one last time as isCompleted: true (handled by the handoff model update logic if needed,
      // but here we just ensure we don't 'END' it).
      if (status.contains('COMPLETED')) {
        // We can call update if we want to ensure the final UI shows,
        // or just return and let APNs handle the final 'true' state.
        // To be safe and responsive, we sync the final state.
        await LiveActivityManager().startActivity(
          orderId: rideId,
          status: status,
          isCompleted: status.contains('COMPLETED'),
          etaSeconds: currentEtaSeconds.value,
          driverLatitude: assignedDriverLocation.value?.latitude,
          driverLongitude: assignedDriverLocation.value?.longitude,
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

  /// Prefer vehicle snapshot plate; else driver snapshot registration (same sources as UI).
  String _rawPlateStringFromRide(RideModel r) {
    final snap = r.vehicleSnapshot;
    if (snap != null) {
      final p = snap.plateNumber.trim();
      if (p.isNotEmpty) return snap.plateNumber;
    }
    final d = r.driverSnapshot;
    if (d is DriverSnapshotModel) {
      return (d.vehicleRegistrationNumber ?? '').trim();
    }
    return '';
  }

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

      final rawPlate = _rawPlateStringFromRide(r);

      await LiveActivityManager().startActivity(
        orderId: rideId,
        status: statusStr,
        driverName: r.driverSnapshot?.name ?? 'Driver Assigned',
        vehicleName:
            '${r.vehicleSnapshot?.vehicleType ?? ''} ${r.vehicleSnapshot?.vehicleModel ?? ''}'
                .trim(),
        driverAvatarUrl: r.driverSnapshot?.avatarUrl ?? '',
        plateNumber: TanzaniaLicensePlateFormatter.formatDisplay(rawPlate),
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
        title: AppStrings.updateInProgress.tr,
        message: AppStrings.aPreviousUpdateIsStillBeingProcessed.tr,
      );
      return;
    }
    stopUpdateIdempotencyKey.value = const Uuid().v4();
    Get.toNamed(AppRoutes.stopEditor, arguments: {'ride': ride.value});
  }

  Future<void> previewStopsUpdate(List<RideStopEntity> stops) async {
    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await rideRepository.updateStops(
      rideId,
      stops: stopsJson,
      confirm: false,
      idempotencyKey: stopUpdateIdempotencyKey.value,
    );

    result.fold(
      (f) {
        AppDialogs.showErrorDialog(
          title: AppStrings.error.tr,
          message: f.message,
        );
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
      },
    );
  }

  Future<bool> applyStopsUpdate(List<RideStopEntity> stops) async {
    final pending = ride.value?.pendingStopsUpdate;
    if (pending != null &&
        pending.status == 'pending_payment' &&
        pending.validationId != null) {
      _pendingStopPaymentValidationId = pending.validationId;
      _pendingStopPaymentDirection = pending.direction;
      return true;
    }

    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await rideRepository.updateStops(
      rideId,
      stops: stopsJson,
      confirm: true,
      idempotencyKey: stopUpdateIdempotencyKey.value,
    );

    return result.fold(
      (f) {
        _clearIdempotencyKey();
        stopUpdateProgressStep.value = 0;
        AppDialogs.showErrorDialog(
          title: AppStrings.error.tr,
          message: f.message,
        );
        return false;
      },
      (res) {
        if (res is StopUpdateAppliedModel) {
          stopUpdateApplied.value = res;
          stopUpdatePreview.value = null;
          _pendingStopAppliedAfterConfirm = res;
          return true;
        }
        return false;
      },
    );
  }

  /// Called after [StopEditorScreen] pops on add-stops confirm success.
  Future<void> onStopEditorClosedAfterConfirm() async {
    final resumeValidationId = _pendingStopPaymentValidationId;
    if (resumeValidationId != null) {
      final direction = _pendingStopPaymentDirection ?? '';
      _pendingStopPaymentValidationId = null;
      _pendingStopPaymentDirection = null;
      isUpdatingStops.value = true;
      stopUpdateProgressStep.value = 1;
      await _processPaymentHold(resumeValidationId, direction);
      return;
    }

    final applied = _pendingStopAppliedAfterConfirm;
    if (applied == null) return;
    _pendingStopAppliedAfterConfirm = null;
    await _finalizeStopsConfirm(applied);
  }

  Future<void> _finalizeStopsConfirm(StopUpdateAppliedModel applied) async {
    if (applied.blockUpdateRequired &&
        (applied.blockUpdateValidationId ?? '').isNotEmpty) {
      isUpdatingStops.value = true;
      stopUpdateProgressStep.value = 1;
      await _processPaymentHold(
        applied.blockUpdateValidationId!,
        applied.direction,
      );
      return;
    }

    // Instant success — mirror change-drop flow: refresh SCR-11, no progress sheet.
    _clearIdempotencyKey();
    stopUpdateProgressStep.value = 0;
    isUpdatingStops.value = false;
    await _fetchRideDetails();
  }

  List<Map<String, dynamic>> _buildStopsPayloadForUpdate(
    List<RideStopEntity> stops,
  ) {
    final destination = ride.value?.destination;
    final destinationLat = destination?.lat ?? destinationLatLng.latitude;
    final destinationLng = destination?.lng ?? destinationLatLng.longitude;
    final destinationAddr = (destination?.address ?? destinationAddress).trim();

    final payload = <Map<String, dynamic>>[];

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

    // requires destination to always be the last element.
    payload.add({
      'lat': destinationLat,
      'lng': destinationLng,
      'address': destinationAddr,
    });

    return payload;
  }

  Future<void> _processPaymentHold(
    String validationId,
    String direction,
  ) async {
    if (direction == 'up') {
      stopUpdateProgressStep.value = 1; // Show payment step
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }
      _socketService.joinPaymentRoom(validationId: validationId);
      if (AppConfig.ridePaymentBypass) {
        await rideRepository.walletDummyPaymentRequest(
          DummyPaymentRequest(
            result: 'SUCCESS',
            transId: 'TXN-${const Uuid().v4()}',
            validationId: validationId,
          ),
        );
      }
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
          title: AppStrings.takingLongerThanExpected.tr,
          message:
              AppStrings.theUpdateIsTakingSomeTimePleaseCheckBackShortly.tr,
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

  Future<void> onChangeDropLocation() async {
    if (rideId.isEmpty) return;
    if (isUpdatingStops.value || isUpdatingDestination.value) {
      AppDialogs.showInfoDialog(
        title: AppStrings.updateInProgress.tr,
        message: AppStrings.aPreviousUpdateIsStillBeingProcessed.tr,
      );
      return;
    }
    if (isNearDestination()) return;
    if (ride.value?.pendingStopsUpdate != null) return;
    Get.toNamed(
      AppRoutes.changeDropLocationEditor,
      arguments: {'ride': ride.value, 'editorMode': 'destination'},
    );
  }

  // Opens stop-style picker and returns one destination (lat/lng/address).
  // This keeps destination selection UX consistent with add-stop selection.
  Future<Map<String, dynamic>?> pickNewDropLocation() async {
    final dynamic raw = await Get.toNamed(
      AppRoutes.selectSavedLocation,
      arguments: {
        'isSelectingStop': true,
        'label': AppStrings.changeDropLocation.tr,
      },
    );
    if (raw == null || raw is! Map) return null;
    final mapped = _extractDestinationFromLocationSelectionResult(
      Map<String, dynamic>.from(raw),
    );
    if (mapped == null) return null;
    return mapped;
  }

  Future<void> previewDropLocationUpdate(
    Map<String, dynamic> destination,
  ) async {
    destinationUpdatePreview.value = null;
    final dest = _buildDestinationPayload(destination);
    if (dest == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.error.tr,
        message: AppStrings.addressMissing.tr,
      );
      return;
    }
    // Step 1: preview update-destination (confirm=false).
    final previewRes = await rideRepository.previewUpdateDestination(
      rideId,
      dest,
    );
    previewRes.fold(
      (f) => AppDialogs.showErrorDialog(
        title: AppStrings.error.tr,
        message: f.message,
      ),
      (preview) {
        destinationUpdatePreview.value = preview;
      },
    );
  }

  Future<bool> applyDropLocationUpdate(Map<String, dynamic> destination) async {
    final dest = _buildDestinationPayload(destination);
    if (dest == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.error.tr,
        message: AppStrings.addressMissing.tr,
      );
      return false;
    }
    // Step 2: apply update-destination (confirm=true).
    return _applyDestinationConfirm(dest);
  }

  Map<String, dynamic>? _buildDestinationPayload(Map<String, dynamic> result) {
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();
    final address = result['address']?.toString().trim() ?? '';
    if (lat == null || lng == null || address.isEmpty) return null;
    return <String, dynamic>{'lat': lat, 'lng': lng, 'address': address};
  }

  Map<String, dynamic>? _extractDestinationFromLocationSelectionResult(
    Map<String, dynamic> payload,
  ) {
    // Location selection edit mode returns:
    // { pickup, pickupLat, pickupLng, destinations: [{address, lat, lng}, ...] }
    // For this feature we only need the first destination.
    final destinations = payload['destinations'];
    if (destinations is List && destinations.isNotEmpty) {
      final first = destinations.first;
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        return {
          'lat': (map['lat'] as num?)?.toDouble(),
          'lng': (map['lng'] as num?)?.toDouble(),
          'address': map['address']?.toString().trim(),
        };
      }
    }

    // Backward compatibility if any picker returns direct lat/lng/address.
    return {
      'lat': (payload['lat'] as num?)?.toDouble(),
      'lng': (payload['lng'] as num?)?.toDouble(),
      'address': payload['address']?.toString().trim(),
    };
  }

  Future<bool> _applyDestinationConfirm(Map<String, dynamic> dest) async {
    final lat = (dest['lat'] as num).toDouble();
    final lng = (dest['lng'] as num).toDouble();
    _pendingDestinationTargetLat = lat;
    _pendingDestinationTargetLng = lng;

    isDestinationUpdateFlow.value = true;

    // Step 2: apply destination update (confirm=true).
    final result = await rideRepository.confirmUpdateDestination(rideId, dest);
    return result.fold(
      (f) {
        isDestinationUpdateFlow.value = false;
        stopUpdateProgressStep.value = 0;
        _pendingDestinationTargetLat = null;
        _pendingDestinationTargetLng = null;
        _pendingDestinationAppliedAfterConfirm = null;
        AppDialogs.showErrorDialog(
          title: AppStrings.error.tr,
          message: f.message,
        );
        return false;
      },
      (DestinationUpdateAppliedModel applied) {
        destinationUpdatePreview.value = null;
        // Finalize after the editor screen pops so progress UI shows on SCR-11.
        _pendingDestinationAppliedAfterConfirm = applied;
        return true;
      },
    );
  }

  /// Called after [StopEditorScreen] pops on confirm success.
  Future<void> onChangeDropLocationEditorClosedAfterConfirm() async {
    final applied = _pendingDestinationAppliedAfterConfirm;
    if (applied == null) return;
    _pendingDestinationAppliedAfterConfirm = null;
    await _finalizeDestinationConfirm(applied);
  }

  Future<void> _finalizeDestinationConfirm(
    DestinationUpdateAppliedModel applied,
  ) async {
    final priorFare = ride.value?.fareEstimate ?? _seedRideCharge ?? 0;
    // If backend requires payment block update, run payment-hold flow first.
    // Otherwise mark success and refresh ride immediately.
    if (applied.blockUpdateRequired &&
        (applied.blockUpdateValidationId ?? '').isNotEmpty) {
      final dir = applied.fareEstimate > priorFare
          ? 'up'
          : applied.fareEstimate < priorFare
          ? 'down'
          : '';
      await _processDestinationPaymentHold(
        applied.blockUpdateValidationId!,
        dir,
      );
    } else {
      isDestinationUpdateFlow.value = false;
      await _fetchRideDetails();
      _setDropRouteFallback();
      stopUpdateProgressStep.value = 0;
      isUpdatingDestination.value = false;
    }
  }

  Future<void> _processDestinationPaymentHold(
    String validationId,
    String direction,
  ) async {
    isUpdatingDestination.value = true;
    // Mirrors stop-update payment behavior:
    // - up: request payment authorization
    // - down/flat: skip to route sync step
    if (direction == 'up') {
      stopUpdateProgressStep.value = 1;
      if (!_socketService.isConnected) {
        await _socketService.connect();
      }
      _socketService.joinPaymentRoom(validationId: validationId);
      if (AppConfig.ridePaymentBypass) {
        await rideRepository.walletDummyPaymentRequest(
          DummyPaymentRequest(
            result: 'SUCCESS',
            transId: 'TXN-${const Uuid().v4()}',
            validationId: validationId,
          ),
        );
      }
    } else if (direction == 'down') {
      stopUpdateProgressStep.value = 2;
    } else {
      stopUpdateProgressStep.value = 2;
    }
    _startDestinationUpdateTimeout();
  }

  void _startDestinationUpdateTimeout() {
    // Safety timeout + polling fallback in case socket events are delayed/missed.
    Future.delayed(const Duration(seconds: 90), () {
      if (isUpdatingDestination.value) {
        isUpdatingDestination.value = false;
        stopUpdateProgressStep.value = 0;
        isDestinationUpdateFlow.value = false;
        _pendingDestinationTargetLat = null;
        _pendingDestinationTargetLng = null;
        AppDialogs.showInfoDialog(
          title: AppStrings.takingLongerThanExpected.tr,
          message:
              AppStrings.theUpdateIsTakingSomeTimePleaseCheckBackShortly.tr,
        );
        unawaited(_fetchRideDetails());
      }
    });
    _pollForDestinationUpdateResult();
  }

  void _pollForDestinationUpdateResult() {
    Future.delayed(const Duration(seconds: 8), () {
      if (!isUpdatingDestination.value || stopUpdateProgressStep.value != 2) {
        return;
      }
      unawaited(_fetchRideDetails());
      _pollForDestinationUpdateResult();
    });
  }

  String priceFormatter(int? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,###').format(amount);
  }
}
