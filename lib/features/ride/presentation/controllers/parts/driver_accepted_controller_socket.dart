part of '../driver_accepted_controller.dart';

/// Ride-room realtime: join/leave, status / tracking / stop-update payloads.
///
/// Edit here for socket event handling and rematch / chain-broken navigation.
extension DriverAcceptedSocketMethods on DriverAcceptedController {
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
        legs: const [],
        stopsDiff: StopUpdateDiffModel(
          added: const [],
          removed: const [],
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

  void _recoverRealtimeStateOnResume() {
    if (_isHandlingAppResume || rideId.isEmpty) return;
    _isHandlingAppResume = true;
    Future.microtask(() async {
      try {
        await _fetchRideDetails();
        await _socketService.connect();
        _joinRideRoomIfNeeded();
      } finally {
        _isHandlingAppResume = false;
      }
    });
  }

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
        _applyRouteDeviation(seededDeviation);
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
    _fareSettledSub?.cancel();
    _driverCancelledSub?.cancel();
    _routeDeviationSub?.cancel();
    _cancellationRequestUpdateSub?.cancel();

    _connectionSub = _socketService.connectionStream.listen((connected) {
      if (!connected) return;
      _joinRideRoomIfNeeded();
    });

    // Primary realtime status feed — always normalize before comparing.
    _rideStatusSub = _socketService.rideStatusStream.listen((payload) async {
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      AppLogger.d(
        '📥 Socket Event: ride_status_stream - Status: ${payload.status} for ride $rideId | ${jsonEncode(payload.toJson())}',
        tag: 'ORDER_TRACKING',
      );
      final status = (payload.status ?? '').toString().trim();
      final normalized = normalizeRideStatusString(status);

      if (normalized == 'cancelled') {
        if (_isUserInitiatedCancellation || _navigatedAway) return;
        await _syncLiveActivityFromStatusPayload(payload);
        _stopNoShowCountdown(clearInfo: true);
        final cancelledBy = (payload.cancelledBy ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final message = (payload.message ?? '').trim();
        if (payload.isNoShowCancellation || cancelledBy == 'support') {
          _navigatedAway = true;
          await LiveActivityManager().endActivity(rideId);
          _showCancelDialogThenGoHome(
            message.isNotEmpty ? message : AppStrings.rideCancelled.tr,
          );
          return;
        }
        await _maybeNavigateMidRideDriverCancelled();
        if (_navigatedAway) return;
        _navigatedAway = true;
        await LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(
          message.isNotEmpty ? message : AppStrings.rideCancelled.tr,
        );
        return;
      }
      if (normalized == 'no_driver_found' || normalized == 'no_drivers_found') {
        if (_navigatedAway) return;
        _navigatedAway = true;
        await _syncLiveActivityFromStatusPayload(payload);
        await LiveActivityManager().endActivity(rideId);
        _showCancelDialogThenGoHome(
          AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr,
        );
        return;
      }

      if (normalized == 'searching') {
        if (_navigatedAway) return;
        // On driver-accepted during pickup (including chained assignment),
        // searching means the chain broke / rematch started — always return to
        // the finding-driver searching sheet.
        if (rideBottomSheetState.value == RideBottomSheetState.rideStarted) {
          return;
        }
        _navigateBackToFindingDriverAfterChainBroken();
        return;
      }

      if (_navigatedAway) return;
      // _applyStatusPayload already applies status; avoid duplicate completion triggers.
      _applyStatusPayload(payload);
      await _syncLiveActivityFromStatusPayload(payload);
    });

    _rideStopSub = _socketService.rideStopUpdateStream.listen((payload) {
      if (_navigatedAway) return;
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      // Intermediate-stop progress only — never treat stop "completed" as ride end.
      _applyStopProgressPayload(payload);
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
      if (_shouldHideDriverSpeedFor(
        status: currentRideStatus.value,
        driverPosition: rawPos,
        speedMps: speed,
      )) {
        assignedDriverSpeed.value = 0;
      } else {
        assignedDriverSpeed.value = speed;
      }

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

      assignedDriverHeading.value = _resolveAssignedDriverHeading(
        currentPosition: rawPos,
        previousPosition: rotationFrom,
        headingDegrees: parsedHeading,
        previousRotation: assignedDriverHeading.value,
        speedMps: speed,
      );

      if (!isDriverFinishingNearby.value) {
        if (rotationFrom != null) {
          final moved = _calculateDistanceInMeters(rotationFrom, rawPos);
          if (moved >= MapVehicleMarkerUtils.minMovementMetersForBearing) {
            _lastDriverRotationSamplePosition = rawPos;
          }
        } else {
          _lastDriverRotationSamplePosition = rawPos;
        }
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
        if (_navigatedAway) return;
        if (!_isSocketEventForThisRide(payload.rideId)) return;
        _hasReceivedTrackingUpdate = true;
        AppLogger.d(
          '📥 Socket Event: tracking_update_socket - Target: ${payload.routeTarget} for ride $rideId | ${jsonEncode(payload.toJson())}',
          tag: 'ORDER_TRACKING',
        );
        _applyTrackingPayload(payload);
      }
    });

    _fareSettledSub = _socketService.rideFareSettledStream.listen((payload) {
      BookAnyFareSettledUi.maybeShow(payload: payload, rideId: rideId);
    });

    _driverCancelledSub = _socketService.rideDriverCancelledStream.listen((
      payload,
    ) async {
      if (payload.rideId.trim() != rideId) return;
      if (_navigatedAway) return;
      await _maybeNavigateMidRideDriverCancelled(
        payload.toMidRideCancelModel(),
      );
    });

    _routeDeviationSub = _socketService.rideRouteDeviationStream.listen((
      payload,
    ) {
      if (_navigatedAway) return;
      if (!_isSocketEventForThisRide(payload.rideId)) return;
      _applyRouteDeviationFromSocket(payload);
    });

    _cancellationRequestUpdateSub = _socketService
        .rideCancellationRequestUpdateStream
        .listen((payload) {
          if (_navigatedAway) return;
          if (!_isSocketEventForThisRide(payload.rideId)) return;
          _applyCancellationRequestUpdate(payload);
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
      _clearRouteAwaitingTrackingUpdate();
      unawaited(_ensureRideRealtimeAfterLocationUpdate());
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

    _paymentStatusSub = _socketService.paymentStatusStream.listen(
      _handlePaymentBlockStatus,
    );
  }

  /// Ignores socket ticks from other active rides when Home joined multiple rooms.
  bool _isSocketEventForThisRide(String? payloadRideId) {
    return socketPayloadIsForRide(
      activeRideId: rideId,
      payloadRideId: payloadRideId,
      joinedRideRoomId: _socketService.joinedRideRoomId,
    );
  }

  Future<void> _ensureRideRealtimeAfterLocationUpdate() async {
    if (rideId.isEmpty) return;
    try {
      await _socketService.ensureConnected();
      _joinRideRoomIfNeeded();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.w(
        'Ride socket rejoin after location update failed',
        tag: 'DriverAcceptedController',
      );
    }
  }

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

  void _handlePaymentBlockStatus(PaymentStatusUpdateResponse event) {
    final outcome = _paymentBlockOutcome(event);
    if (outcome == null) return;

    if (isUpdatingStops.value && stopUpdateProgressStep.value == 1) {
      if (outcome) {
        stopUpdateProgressStep.value = 2;
        unawaited(_ensureRideRealtimeAfterLocationUpdate());
      } else {
        isUpdatingStops.value = false;
        stopUpdateProgressStep.value = 0;
        _showStopUpdateError(
          AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr,
        );
      }
      return;
    }

    if (isUpdatingDestination.value && stopUpdateProgressStep.value == 1) {
      if (outcome) {
        stopUpdateProgressStep.value = 2;
        unawaited(_ensureRideRealtimeAfterLocationUpdate());
      } else {
        isUpdatingDestination.value = false;
        isDestinationUpdateFlow.value = false;
        stopUpdateProgressStep.value = 0;
        _pendingDestinationTargetLat = null;
        _pendingDestinationTargetLng = null;
        _showDestinationUpdateError(
          AppStrings.paymentHoldUpdateFailedNoChargesApplied.tr,
        );
      }
    }
  }

  void _joinRideRoomIfNeeded() {
    if (!_socketService.isConnected || rideId.isEmpty) {
      return;
    }
    _socketService.switchRideRoom(rideId: rideId);
  }

  /// Ride chaining broke: assigned driver no longer available — resume driver search.
  ///
  /// Replaces SCR-11 (driver accepted) with SCR-10 (finding driver) using the
  /// same searching labels as a normal match. Sets [_navigatedAway] so in-flight
  /// [getRideDetails] responses do not paint the "unable to open ride details"
  /// error sheet after we leave.
  void _navigateBackToFindingDriverAfterChainBroken() {
    if (_navigatedAway) return;
    _navigatedAway = true;
    _skipRideRoomLeaveOnClose = true;
    isDriverFinishingNearby.value = false;

    AppLogger.d(
      'Chain broken → navigating to finding-driver (searching) for ride $rideId',
      tag: 'ORDER_TRACKING',
    );

    final currentRide = ride.value;
    if (currentRide != null) {
      navigateToFindingDriverForRide(
        currentRide.copyWith(status: RideStatus.searching),
        replace: true,
        chainBroken: true,
      );
      return;
    }

    final destinations = routeDestinations.isNotEmpty
        ? routeDestinations
              .map((e) => {'lat': e.lat, 'lng': e.lng, 'address': e.address})
              .toList()
        : [
            {
              'lat': destinationLatLng.latitude,
              'lng': destinationLatLng.longitude,
              'address': destinationAddress,
            },
          ];

    Get.offNamed(
      AppRoutes.findingDriver,
      arguments: {
        'rideId': rideId,
        'pickupLat': pickupLatLng.latitude,
        'pickupLng': pickupLatLng.longitude,
        'pickupAddress': pickupAddress,
        'destinationLat': destinationLatLng.latitude,
        'destinationLng': destinationLatLng.longitude,
        'destinationAddress': destinationAddress,
        'destinations': destinations,
        if (_seedFareBreakdown != null) 'fareBreakdown': _seedFareBreakdown,
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
        final currentRide = ride.value;
        if (currentRide != null) {
          ride.value = currentRide.copyWith(
            currentStopIndex: payload.currentStopIndex,
          );
        }
      }

      final target = _normalizeRouteTarget(payload.routeTarget);
      if (target.isNotEmpty || payload.routeGeometry?.coordinates != null) {
        _applyRouteGeometryFromPayload(
          routeTarget: target.isNotEmpty ? target : 'drop_off',
          coordinates: payload.routeGeometry?.coordinates,
          fitCameraOnChange: true,
        );
      }

      // Keep in-trip sheet; do not call completion navigation.
      if (rideBottomSheetState.value != RideBottomSheetState.rideStarted) {
        _applyBottomSheetStateForStatus('ride_in_progress');
      } else {
        final current = normalizeRideStatusString(currentRideStatus.value);
        if (current != 'ride_in_progress' &&
            current != 'ride_started' &&
            current != 'near_destination') {
          currentRideStatus.value = 'ride_in_progress';
        }
      }

      unawaited(_fetchRideDetails());
      return;
    }

    _applyStatusPayload(payload);
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

    if (payload.fareBreakdown != null) {
      final currentRide = ride.value;
      if (currentRide != null) {
        ride.value = currentRide.copyWith(fareBreakdown: payload.fareBreakdown);
      }
    }

    final rootEta = payload.etaSeconds;
    // Apply finishing flag first so ETA labels restore correctly when it becomes false.
    _setDriverFinishingNearby(payload.driverFinishingNearby);
    if (rootEta != null && rootEta.toDouble() > 0) {
      _applySocketEtaSecondsToLabels(rootEta.toDouble(), skipIfArrived: true);
    }

    _syncCancelAndNoShowFromStatusPayload(payload);
  }

  void _applyTrackingPayload(TrackingUpdateSocketResponse payload) {
    _setDriverFinishingNearby(payload.driverFinishingNearby);

    final trackingStatus = (payload.status ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final normalizedTracking = normalizeRideStatusString(trackingStatus);

    // Chain break can also arrive on tracking before/without a status event.
    if (normalizedTracking == 'searching') {
      if (_navigatedAway) return;
      if (rideBottomSheetState.value == RideBottomSheetState.rideStarted) {
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
        _applyBottomSheetStateForStatus(normalizedTracking);
      }
    }

    if (trackingStatus == 'cancelled') {
      if (_isUserInitiatedCancellation || _navigatedAway) return;
      unawaited(_handleRideCancelledFromTracking());
      return;
    }
    if (trackingStatus == 'no_driver_found' ||
        trackingStatus == 'no_drivers_found') {
      if (_navigatedAway) return;
      _navigatedAway = true;
      _showCancelDialogThenGoHome(
        AppStrings.noDriverFoundForYourRequestPleaseTryAgain.tr,
      );
      return;
    }

    final isPickupArrived = _isDriverArrivedAtPickupStatus(trackingStatus);
    if (isPickupArrived) {
      _setDriverFinishingNearby(false);
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
        if (!isDriverFinishingNearby.value) {
          etaLabel.value = inRide
              ? AppStrings.nearby.tr
              : AppStrings.arriving.tr;
          arrivalLabel.value = inRide
              ? AppStrings.youAreAlmostThere.tr
              : AppStrings.driverIsArriving.tr;
        }
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

    // Hybrid: refresh Live Activity ETA/location from tracking (1.5s throttle
    // in LiveActivityManager). APNs can still deliver the same updates later.
    unawaited(_syncLiveActivityFromTrackingPayload(payload));
  }
}
