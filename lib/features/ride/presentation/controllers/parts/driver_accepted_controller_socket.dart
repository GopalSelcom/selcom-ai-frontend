part of '../driver_accepted_controller.dart';

/// Ride-room realtime: join/leave, status / tracking / stop-update payloads.
///
/// Edit here for socket event handling and rematch / chain-broken navigation.
class DriverAcceptedSocketHelper {
  DriverAcceptedSocketHelper(this.c);

  /// Parent [DriverAcceptedController] — shared ride state and lifecycle.
  final DriverAcceptedController c;

  /// Restores pending stop-update payment / DA progress after resume or refresh.
  void _handleStopUpdateRecovery() {
    final pending = c.ride.value?.pendingStopsUpdate;
    if (pending == null) return;

    if (pending.status == 'pending_payment') {
      // Trust the backend: if it's in the response, it's not expired yet
      c.stopUpdatePreview.value = StopUpdatePreviewModel(
        fareChanged: true,
        oldFareEstimate: c.ride.value?.fareEstimate ?? 0,
        newFareEstimate: pending.newFare ?? 0,
        deltaAmount: pending.deltaAmount,
        direction: pending.direction,
        newDistanceKm: 0,
        newDurationMin: 0,
        waypointCharge: 0,
        legs: const [],
        stopsDiff: StopUpdateDiffModel(
          added: const [],
          removed: const [],
          reordered: false,
        ),
      );
      c.stopUpdateWorkingStops.assignAll(pending.stops);
      if (pending.idempotencyKey != null) {
        c.stopUpdateIdempotencyKey.value = pending.idempotencyKey!;
        c._saveIdempotencyKey(pending.idempotencyKey!);
      }
    } else if (pending.status == 'pending_da') {
      c.isUpdatingStops.value = true;
      c.stopUpdateProgressStep.value = 2; // Route update phase
      c.stopsDestinationHelper._startStopUpdateTimeout();
    }
  }

  /// On app resume: refresh details, reconnect socket, and rejoin the ride room.
  void _recoverRealtimeStateOnResume() {
    if (c._isHandlingAppResume || c.rideId.isEmpty) return;
    c._isHandlingAppResume = true;
    Future.microtask(() async {
      try {
        await c._fetchRideDetails();
        await c._socketService.connect();
        _joinRideRoomIfNeeded();
      } finally {
        c._isHandlingAppResume = false;
      }
    });
  }

  /// Applies navigation-seed status / driver / tracking payloads once on open.
  void _hydrateSocketSeedPayloads(Map<String, dynamic> args) {
    AppLogger.d(
      '💧 Hydrating socket seed payloads from args: $args',
      tag: 'ORDER_TRACKING',
    );
    final statusRaw = args['statusPayload'];
    if (statusRaw is Map) {
      final statusMap = Map<String, dynamic>.from(statusRaw);
      final payload = EventRiderStatusUpdateResponse.fromJson(statusMap);
      _applyStatusPayload(payload);
      final seededDeviation = rideRouteDeviationFromJson(
        statusMap['route_deviation'],
      );
      if (seededDeviation != null) {
        c.cancelSafetyHelper._applyRouteDeviation(seededDeviation);
      }
    }
    final driverRaw = args['driverLocationPayload'];
    if (driverRaw is Map) {
      final payload = DriverLocationSocketResponse.fromJson(
        Map<String, dynamic>.from(driverRaw),
      );
      final lat = payload.latitude;
      final lng = payload.longitude;
      if (lat != null && lng != null) {
        c.assignedDriverLocation.value = LatLng(lat, lng);
      }
    }
    final trackingRaw = args['trackingPayload'];
    if (trackingRaw is Map) {
      c._hasReceivedTrackingUpdate = true;
      final payload = TrackingUpdateSocketResponse.fromJson(
        Map<String, dynamic>.from(trackingRaw),
      );
      _applyTrackingPayload(payload);
    }
  }

  /// Subscribes to ride-room streams and joins the socket room for this ride.
  Future<void> _initRideRoomSocket() async {
    if (c.rideId.isEmpty) return;

    c._connectionSub?.cancel();
    c._rideStatusSub?.cancel();
    c._driverLocSub?.cancel();
    c._trackingSub?.cancel();
    c._chatSub?.cancel();
    c._rideStopsUpdatedSub?.cancel();
    c._rideStopsUpdateFailedSub?.cancel();
    c._paymentStatusSub?.cancel();
    c._fareSettledSub?.cancel();
    c._driverCancelledSub?.cancel();
    c._routeDeviationSub?.cancel();
    c._cancellationRequestUpdateSub?.cancel();

    c._connectionSub = c._socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _joinRideRoomIfNeeded();
    });

    // Primary realtime status feed — always normalize before comparing.
    c._rideStatusSub = c._socketService.rideStatusStream.listen((payload) async {
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      AppLogger.d(
        '📥 Socket Event: ride_status_stream - Status: ${payload.status} for ride $c.rideId | ${jsonEncode(payload.toJson())}',
        tag: 'ORDER_TRACKING',
      );
      final status = (payload.status ?? '').toString().trim();
      final normalized = normalizeRideStatusString(status);

      if (normalized == 'cancelled') {
        if (c._isUserInitiatedCancellation || c._navigatedAway) return;
        await c.commsLiveHelper._syncLiveActivityFromStatusPayload(payload);
        c.cancelSafetyHelper._stopNoShowCountdown(clearInfo: true);
        final cancelledBy = (payload.cancelledBy ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final message = (payload.message ?? '').trim();
        if (payload.isNoShowCancellation || cancelledBy == 'support') {
          c._navigatedAway = true;
          await LiveActivityManager().endActivity(c.rideId);
          c.cancelSafetyHelper._showCancelDialogThenGoHome(
            message.isNotEmpty ? message : AppStrings.rideCancelled.tr,
          );
          return;
        }
        await c.cancelSafetyHelper._maybeNavigateMidRideDriverCancelled();
        if (c._navigatedAway) return;
        c._navigatedAway = true;
        await LiveActivityManager().endActivity(c.rideId);
        c.cancelSafetyHelper._showCancelDialogThenGoHome(
          message.isNotEmpty ? message : AppStrings.rideCancelled.tr,
        );
        return;
      }
      if (normalized == 'no_driver_found' || normalized == 'no_drivers_found') {
        if (c._navigatedAway) return;
        c._navigatedAway = true;
        await c.commsLiveHelper._syncLiveActivityFromStatusPayload(payload);
        await LiveActivityManager().endActivity(c.rideId);
        c.cancelSafetyHelper._showCancelDialogThenGoHome(
          AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr,
        );
        return;
      }

      if (normalized == 'searching') {
        if (c._navigatedAway) return;
        // On driver-accepted during pickup (including chained assignment),
        // searching means the chain broke / rematch started — always return to
        // the finding-driver searching sheet.
        if (c.rideBottomSheetState.value == RideBottomSheetState.rideStarted) {
          return;
        }
        _navigateBackToFindingDriverAfterChainBroken();
        return;
      }

      if (c._navigatedAway) return;
      // _applyStatusPayload already applies status; avoid duplicate completion triggers.
      _applyStatusPayload(payload);
      await c.commsLiveHelper._syncLiveActivityFromStatusPayload(payload);
    });

    c._rideStopSub = c._socketService.rideStopUpdateStream.listen((payload) {
      if (c._navigatedAway) return;
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      // Intermediate-stop progress only — never treat stop "completed" as ride end.
      _applyStopProgressPayload(payload);
    });

    c._driverLocSub = c._socketService.rideDriverLocationStream.listen((payload) {
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
      c.assignedDriverLocation.value = rawPos;
      if (c.mapHelper._shouldHideDriverSpeedFor(
        status: c.currentRideStatus.value,
        driverPosition: rawPos,
        speedMps: speed,
      )) {
        c.assignedDriverSpeed.value = 0;
      } else {
        c.assignedDriverSpeed.value = speed;
      }

      // 2. High-Fidelity Interpolation:
      // We calculate duration based on REAL speed for a butter-smooth glide.
      Duration animDuration = const Duration(milliseconds: 3500);

      if (speed > 0.5) {
        final currentPos =
            c.mapWidgetKey.currentState?.currentAnimatedPosition ??
            c.assignedDriverLocation.value!;
        final distance = c.mapHelper._calculateDistanceInMeters(currentPos, rawPos);

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
          c._lastDriverRotationSamplePosition ??
          c.mapWidgetKey.currentState?.currentAnimatedPosition;

      c.assignedDriverHeading.value = c.mapHelper._resolveAssignedDriverHeading(
        currentPosition: rawPos,
        previousPosition: rotationFrom,
        headingDegrees: parsedHeading,
        previousRotation: c.assignedDriverHeading.value,
        speedMps: speed,
      );

      if (!c.isDriverFinishingNearby.value) {
        if (rotationFrom != null) {
          final moved = c.mapHelper._calculateDistanceInMeters(rotationFrom, rawPos);
          if (moved >= MapVehicleMarkerUtils.minMovementMetersForBearing) {
            c._lastDriverRotationSamplePosition = rawPos;
          }
        } else {
          c._lastDriverRotationSamplePosition = rawPos;
        }
      }

      c.mapWidgetKey.currentState?.updateRiderPosition(
        rawPos,
        rotation: c.assignedDriverHeading.value,
        duration: animDuration,
      );
    });

    c._trackingSub = c._socketService.trackingUpdateStatusStream.listen((
      payload,
    ) async {
      if (payload != null) {
        if (c._navigatedAway) return;
        if (!_isSocketEventForThisRide(payload.rideId)) return;
        c._hasReceivedTrackingUpdate = true;
        AppLogger.d(
          '📥 Socket Event: tracking_update_socket - Target: ${payload.routeTarget} for ride $c.rideId | ${jsonEncode(payload.toJson())}',
          tag: 'ORDER_TRACKING',
        );
        _applyTrackingPayload(payload);
      }
    });

    c._fareSettledSub = c._socketService.rideFareSettledStream.listen((payload) {
      BookAnyFareSettledUi.maybeShow(payload: payload, rideId: c.rideId);
    });

    c._driverCancelledSub = c._socketService.rideDriverCancelledStream.listen((
      payload,
    ) async {
      if (payload.rideId.trim() != c.rideId) return;
      if (c._navigatedAway) return;
      await c.cancelSafetyHelper._maybeNavigateMidRideDriverCancelled(
        payload.toMidRideCancelModel(),
      );
    });

    c._routeDeviationSub = c._socketService.rideRouteDeviationStream.listen((
      payload,
    ) {
      if (c._navigatedAway) return;
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      c.cancelSafetyHelper._applyRouteDeviationFromSocket(payload);
    });

    c._cancellationRequestUpdateSub = c._socketService
        .rideCancellationRequestUpdateStream
        .listen((payload) {
          if (c._navigatedAway) return;
          if (!_isSocketEventForThisRide(payload.rideId)) return;
          c.cancelSafetyHelper._applyCancellationRequestUpdate(payload);
        });

    // Ensure socket is connected for the active-ride entry path too.
    await c._socketService.connect();
    if (c._socketService.isConnected) {
      _joinRideRoomIfNeeded();
    }

    c._chatSub = c._socketService.chatStream.listen((data) {
      final payloadRideId =
          (data['ride_id'] ?? data['rideId'])?.toString().trim() ?? '';

      if (payloadRideId != c.rideId) return;

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
        c.unreadCount.value++;

        final msg = data['message'] ?? data['text'] ?? AppStrings.newMessage.tr;

        NotificationService().showLocalNotification(
          title: AppStrings.newMessage.tr,
          body: msg.toString(),
          payload: jsonEncode(data),
        );
      }
    });

    c._rideStopsUpdatedSub = c._socketService.rideStopsUpdatedStream.listen((res) {
      if (res.rideId != c.rideId) return;
      c._clearIdempotencyKey();
      c.isUpdatingStops.value = false;
      c.stopUpdateProgressStep.value = 0;
      c.mapHelper._clearRouteAwaitingTrackingUpdate();
      unawaited(_ensureRideRealtimeAfterLocationUpdate());
      c._fetchRideDetails();
    });

    c._rideStopsUpdateFailedSub = c._socketService.rideStopsUpdateFailedStream
        .listen((res) {
          if (res.rideId != c.rideId) return;
          c._clearIdempotencyKey();
          c.isUpdatingStops.value = false;
          c.stopUpdateProgressStep.value = 0;

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

    c._paymentStatusSub = c._socketService.paymentStatusStream.listen(
      _handlePaymentBlockStatus,
    );
  }

  /// Ignores socket ticks from other active rides when Home joined multiple rooms.
  bool _isSocketEventForThisRide(String? payloadRideId) {
    return socketPayloadIsForRide(
      activeRideId: c.rideId,
      payloadRideId: payloadRideId,
      joinedRideRoomId: c._socketService.joinedRideRoomId,
    );
  }

  /// Reconnects and rejoins the ride room after a stop/destination location update.
  Future<void> _ensureRideRealtimeAfterLocationUpdate() async {
    if (c.rideId.isEmpty) return;
    try {
      await c._socketService.ensureConnected();
      _joinRideRoomIfNeeded();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.w(
        'Ride socket rejoin after location update failed',
        tag: 'DriverAcceptedController',
      );
    }
  }

  /// Maps payment-block status to success (`true`), failure (`false`), or ignore.
  bool? _paymentBlockOutcome(PaymentStatusUpdateResponse event) {
    final phase = (event.phase ?? '').toString().toLowerCase();
    final status = (event.status ?? '').toString().toLowerCase();

    if (phase.isNotEmpty && phase != 'block') return null;

    if (status == 'confirmed' || status == 'completed') {
      return true;
    }
    if (status == 'failed') {
      return false;
    }
    return null;
  }

  /// Advances stop/destination update progress when a wallet block settles.
  void _handlePaymentBlockStatus(PaymentStatusUpdateResponse event) {
    final outcome = _paymentBlockOutcome(event);
    if (outcome == null) return;

    if (c.isUpdatingStops.value && c.stopUpdateProgressStep.value == 1) {
      if (outcome) {
        c.stopUpdateProgressStep.value = 2;
        unawaited(_ensureRideRealtimeAfterLocationUpdate());
      } else {
        c.isUpdatingStops.value = false;
        c.stopUpdateProgressStep.value = 0;
        c.stopsDestinationHelper._showStopUpdateError(
          AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr,
        );
      }
      return;
    }

    if (c.isUpdatingDestination.value && c.stopUpdateProgressStep.value == 1) {
      if (outcome) {
        c.stopUpdateProgressStep.value = 2;
        unawaited(_ensureRideRealtimeAfterLocationUpdate());
      } else {
        c.isUpdatingDestination.value = false;
        c.isDestinationUpdateFlow.value = false;
        c.stopUpdateProgressStep.value = 0;
        c._pendingDestinationTargetLat = null;
        c._pendingDestinationTargetLng = null;
        c.stopsDestinationHelper._showDestinationUpdateError(
          AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr,
        );
      }
    }
  }

  /// Switches the socket into this ride's room when connected.
  void _joinRideRoomIfNeeded() {
    if (!c._socketService.isConnected || c.rideId.isEmpty) {
      return;
    }
    c._socketService.switchRideRoom(rideId: c.rideId);
  }

  /// Ride chaining broke: assigned driver no longer available — resume driver search.
  ///
  /// Replaces SCR-11 (driver accepted) with SCR-10 (finding driver) using the
  /// same searching labels as a normal match. Sets [_navigatedAway] so in-flight
  /// [getRideDetails] responses do not paint the "unable to open ride details"
  /// error sheet after we leave.
  void _navigateBackToFindingDriverAfterChainBroken() {
    if (c._navigatedAway) return;
    c._navigatedAway = true;
    c._skipRideRoomLeaveOnClose = true;
    c.isDriverFinishingNearby.value = false;

    AppLogger.d(
      'Chain broken → navigating to finding-driver (searching) for ride $c.rideId',
      tag: 'ORDER_TRACKING',
    );

    final currentRide = c.ride.value;
    if (currentRide != null) {
      navigateToFindingDriverForRide(
        currentRide.copyWith(status: RideStatus.searching),
        replace: true,
        chainBroken: true,
      );
      return;
    }

    final destinations = c.routeDestinations.isNotEmpty
        ? c.routeDestinations
              .map((e) => {'lat': e.lat, 'lng': e.lng, 'address': e.address})
              .toList()
        : [
            {
              'lat': c.destinationLatLng.latitude,
              'lng': c.destinationLatLng.longitude,
              'address': c.destinationAddress,
            },
          ];

    Get.offNamed(
      AppRoutes.findingDriver,
      arguments: {
        'rideId': c.rideId,
        'pickupLat': c.pickupLatLng.latitude,
        'pickupLng': c.pickupLatLng.longitude,
        'pickupAddress': c.pickupAddress,
        'destinationLat': c.destinationLatLng.latitude,
        'destinationLng': c.destinationLatLng.longitude,
        'destinationAddress': c.destinationAddress,
        'destinations': destinations,
        if (c._seedFareBreakdown != null) 'fareBreakdown': c._seedFareBreakdown,
        kFindingDriverChainBrokenArg: true,
      },
    );
  }

  /// `ride:stop_update` — stop-level progress (index / next-leg route).
  ///
  /// Backend may send `status: completed` for a finished **intermediate stop**.
  /// That must not open the ride-completed details screen while the trip
  /// continues (`ride:status_update` still reports `ride_in_progress`).
  void _applyStopProgressPayload(EventRiderStatusUpdateResponse payload) {
    final normalized = normalizeRideStatusString(payload.status);
    final isStopCompletedSignal =
        normalized == 'completed' ||
        normalized == 'ride_completed' ||
        normalized == 'stop_completed' ||
        normalized.contains('stop_complete');

    if (isStopCompletedSignal) {
      if (payload.currentStopIndex != null) {
        final currentRide = c.ride.value;
        if (currentRide != null) {
          c.ride.value = currentRide.copyWith(
            currentStopIndex: payload.currentStopIndex,
          );
        }
      }

      final target = c.mapHelper._normalizeRouteTarget(payload.routeTarget);
      if (target.isNotEmpty || payload.routeGeometry?.coordinates != null) {
        c.mapHelper._applyRouteGeometryFromPayload(
          nextRouteTarget: target.isNotEmpty ? target : 'drop_off',
          coordinates: payload.routeGeometry?.coordinates,
          fitCameraOnChange: true,
        );
      }

      // Keep in-trip sheet; do not call completion navigation.
      if (c.rideBottomSheetState.value != RideBottomSheetState.rideStarted) {
        c.statusLabelsHelper._applyBottomSheetStateForStatus('ride_in_progress');
      } else {
        final current = normalizeRideStatusString(c.currentRideStatus.value);
        if (current != 'ride_in_progress' &&
            current != 'ride_started' &&
            current != 'near_destination') {
          c.currentRideStatus.value = 'ride_in_progress';
        }
      }

      unawaited(c._fetchRideDetails());
      return;
    }

    _applyStatusPayload(payload);
  }

  /// Applies driver/vehicle/PIN/route data from a status payload (socket or navigation seed).
  void _applyStatusPayload(EventRiderStatusUpdateResponse payload) {
    final status = (payload.status ?? '').toString().trim();
    if (status.isNotEmpty) {
      c.statusLabelsHelper._applyBottomSheetStateForStatus(status);
      c.statusLabelsHelper._applyRouteFallbackForStatus(status);
    }

    final d = payload.driverSnapshot;
    final v = payload.vehicleSnapshot;
    String plateForVehicleLine = '';
    c.statusLabelsHelper._syncBottomSheetVehicleImage(d?.vehicleType);
    if ((d?.vehicleType ?? '').isNotEmpty) {
      c.mapHelper.loadDriverIcon(vehicleType: d?.vehicleType);
    }

    if (payload.pinRequired != null) {
      c.isPinRequired.value = payload.pinRequired == true;
    }

    if (d != null) {
      if ((d.name ?? '').trim().isNotEmpty) c.driverName.value = d.name!.trim();
      if ((d.phone ?? '').trim().isNotEmpty) {
        c.driverPhone.value = d.phone!.trim();
      }
      final avatar = (d.avatarUrl ?? '').trim();
      if (avatar.isNotEmpty) {
        c.driverAvatarUrl.value = avatar;
      }
      if ((d.lat) != null && (d.lng) != null) {
        c.assignedDriverLocation.value = LatLng(d.lat!, d.lng!);
      }
      if (c.isPinRequired.value) {
        final pin = (payload.pinCode ?? '').trim();
        final vCode = (payload.driverSnapshot?.verificationCode ?? '').trim();
        final otp = (pin.isNotEmpty ? pin : vCode).replaceAll(
          RegExp(r'\s'),
          '',
        );

        if (otp.isNotEmpty) {
          c.otpDigits.assignAll(otp.split('').take(4).toList());
        } else if (c.otpDigits.isEmpty) {
          c.otpDigits.assignAll(['—', '—', '—', '—']);
        }
      } else {
        c.otpDigits.clear();
      }
      final vehicleModel = (d.vehicleModel ?? '').trim();
      final vehicleColor = (d.vehicleColor ?? '').trim();
      final plate = (d.vehicleRegistrationNumber ?? '').trim();
      plateForVehicleLine = plate;

      if (vehicleModel.isNotEmpty || vehicleColor.isNotEmpty) {
        final subtitle = '$vehicleModel, $vehicleColor'
            .replaceAll(RegExp(r'(^,\s*|\s*,\s*$)'), '')
            .trim();
        if (subtitle.isNotEmpty) c.vehicleSubtitle.value = subtitle;
      }
      if (plate.isNotEmpty) {
        c.plateDisplayFormatted.value =
            TanzaniaLicensePlateFormatter.formatDisplay(plate);
      } else {
        c.plateDisplayFormatted.value = '';
      }
    }

    c.statusLabelsHelper._applyUnifiedDriverVehicleLine(
      modelName: (d?.vehicleModel ?? '').trim(),
      plate: plateForVehicleLine,
      fallbackModel: (v?.vehicleName ?? '').trim(),
    );

    c.statusLabelsHelper._applyDriverRatingFromStatusPayload(payload, d);

    if (!c.isPinRequired.value) {
      c.otpDigits.clear();
    }

    final oldStatus = c.currentRideStatus.value;
    final oldTarget = c.routeTarget.value;

    final target = c.mapHelper._normalizeRouteTarget(payload.routeTarget);
    final routeTargetChanged = target.isNotEmpty && target != oldTarget;
    c.mapHelper._applyRouteGeometryFromPayload(
      nextRouteTarget: target,
      coordinates: payload.routeGeometry?.coordinates,
      fitCameraOnChange: status != oldStatus || routeTargetChanged,
    );
    if (target.isEmpty && status.isNotEmpty) {
      // Active-c.ride entry can provide status without routeTarget.
      c.statusLabelsHelper._applyRouteFallbackForStatus(status);
      if (status != oldStatus || c.routeTarget.value != oldTarget) {
        c.mapHelper._fitRouteBounds();
      }
    }

    if (payload.currentStopIndex != null) {
      final currentRide = c.ride.value;
      if (currentRide != null) {
        c.ride.value = currentRide.copyWith(
          currentStopIndex: payload.currentStopIndex,
        );
      }
    }

    if (payload.fareBreakdown != null) {
      final currentRide = c.ride.value;
      if (currentRide != null) {
        c.ride.value = currentRide.copyWith(fareBreakdown: payload.fareBreakdown);
      }
    }

    final rootEta = payload.etaSeconds;
    // Apply finishing flag first so ETA labels restore correctly when it becomes false.
    c.statusLabelsHelper._setDriverFinishingNearby(payload.driverFinishingNearby);
    if (rootEta != null && rootEta.toDouble() > 0) {
      c.statusLabelsHelper._applySocketEtaSecondsToLabels(rootEta.toDouble(), skipIfArrived: true);
    }

    c.cancelSafetyHelper._syncCancelAndNoShowFromStatusPayload(payload);
  }

  /// Applies ETA, finishing-nearby, geometry, and cancel signals from tracking.
  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    c.statusLabelsHelper._setDriverFinishingNearby(payload.driverFinishingNearby);

    final trackingStatus = (payload.status ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final normalizedTracking = normalizeRideStatusString(trackingStatus);

    // Chain break can also arrive on tracking before/without a status event.
    if (normalizedTracking == 'searching') {
      if (c._navigatedAway) return;
      if (c.rideBottomSheetState.value == RideBottomSheetState.rideStarted) {
        return;
      }
      _navigateBackToFindingDriverAfterChainBroken();
      return;
    }

    if (normalizedTracking.isNotEmpty) {
      // Only major transitions — exact statuses (avoid substring "complete"
      // matching stop_completed and opening the ride-completed screen).
      const majorTrackingStatuses = {
        'ride_started',
        'ride_in_progress',
        'near_destination',
        'completed',
        'ride_completed',
        'driver_arrived',
        'driver_arriving',
      };
      if (majorTrackingStatuses.contains(normalizedTracking)) {
        c.statusLabelsHelper._applyBottomSheetStateForStatus(normalizedTracking);
      }
    }

    if (trackingStatus == 'cancelled') {
      if (c._isUserInitiatedCancellation || c._navigatedAway) return;
      unawaited(c.cancelSafetyHelper._handleRideCancelledFromTracking());
      return;
    }
    if (trackingStatus == 'no_driver_found' ||
        trackingStatus == 'no_drivers_found') {
      if (c._navigatedAway) return;
      c._navigatedAway = true;
      c.cancelSafetyHelper._showCancelDialogThenGoHome(
        AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr,
      );
      return;
    }

    final isPickupArrived = c.statusLabelsHelper._isDriverArrivedAtPickupStatus(trackingStatus);
    if (isPickupArrived) {
      c.statusLabelsHelper._setDriverFinishingNearby(false);
      c.statusLabelsHelper._syncDriverArrivedPickupMessages();
    }

    final eta = payload.eta;
    if (eta != null) {
      final etaSecs = eta.toDouble();
      if (!isPickupArrived && etaSecs > 0) {
        c.statusLabelsHelper._applySocketEtaSecondsToLabels(etaSecs, skipIfArrived: false);
      } else if (!isPickupArrived && etaSecs <= 0) {
        final statusForEta = (payload.status ?? c.currentRideStatus.value)
            .toLowerCase();
        final inRide =
            statusForEta.contains('progress') ||
            statusForEta.contains('started');
        if (!c.isDriverFinishingNearby.value) {
          c.etaLabel.value = inRide
              ? AppStrings.nearby.tr
              : AppStrings.arriving.tr;
          c.arrivalLabel.value = inRide
              ? AppStrings.youAreAlmostThere.tr
              : AppStrings.driverIsArriving.tr;
        }
      }
    }

    var target = c.mapHelper._normalizeRouteTarget(payload.routeTarget);
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

    c.mapHelper._applyRouteGeometryFromPayload(
      nextRouteTarget: target,
      coordinates: coords,
      fitCameraOnChange: true,
    );

    // Hybrid: refresh Live Activity ETA/location from tracking (1.5s throttle
    // in LiveActivityManager). APNs can still deliver the same updates later.
    unawaited(c.commsLiveHelper._syncLiveActivityFromTrackingPayload(payload));
  }
}
