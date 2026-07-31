part of '../driver_accepted_controller.dart';

/// Mid-ride stop edits and drop-location changes (preview, confirm, wallet hold).
///
/// Edit here for stop/destination update APIs and insufficient-wallet handling.
extension DriverAcceptedStopsDestinationMethods on DriverAcceptedController {
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

  Future<void> previewStopsUpdate(List<RideStopModel> stops) async {
    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await rideRepository.updateStops(
      rideId,
      stops: stopsJson,
      confirm: false,
      idempotencyKey: stopUpdateIdempotencyKey.value,
    );

    result.fold(
      (f) {
        if (_handleInsufficientWalletFailure(f)) return;
        _showStopUpdateError(f.message);
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

  Future<bool> applyStopsUpdate(List<RideStopModel> stops) async {
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
        if (_handleInsufficientWalletFailure(f)) return false;
        _showStopUpdateError(f.message);
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
      _clearRouteAwaitingTrackingUpdate();
      await _processPaymentHold(resumeValidationId, direction);
      return;
    }

    final applied = _pendingStopAppliedAfterConfirm;
    if (applied == null) return;
    _pendingStopAppliedAfterConfirm = null;
    await _finalizeStopsConfirm(applied);
  }

  Future<void> _finalizeStopsConfirm(StopUpdateAppliedModel applied) async {
    // Confirm sample has no validation_id; payment resume uses pendingStopsUpdate.
    if (applied.blockUpdateRequired == true) {
      isUpdatingStops.value = true;
      stopUpdateProgressStep.value = 1;
      _clearRouteAwaitingTrackingUpdate();
      await _fetchRideDetails();
      return;
    }

    // Instant success — mirror change-drop flow: refresh SCR-11, no progress sheet.
    _clearIdempotencyKey();
    stopUpdateProgressStep.value = 0;
    isUpdatingStops.value = false;
    _clearRouteAwaitingTrackingUpdate();
    await _ensureRideRealtimeAfterLocationUpdate();
    await _fetchRideDetails();
  }

  void _showStopUpdateError(String rawMessage) {
    _showLocationUpdateValidationError(rawMessage, clearStopPreview: true);
  }

  Future<void> _showInsufficientWalletDialog(
    InsufficientWalletBalanceDetails details,
  ) async {
    await AppDialogs.showInsufficientWalletBalanceDialog(
      details: details,
      onTopUp: _openWalletTopUp,
    );
  }

  void _openWalletTopUp() {
    unawaited(AddMoneyToWalletBottomSheet.show());
  }

  bool _handleInsufficientWalletFailure(Failure failure) {
    if (failure is InsufficientWalletBalanceFailure) {
      unawaited(_showInsufficientWalletDialog(failure.details));
      return true;
    }
    return false;
  }

  void _showDestinationUpdateError(String rawMessage) {
    _showLocationUpdateValidationError(
      rawMessage,
      clearDestinationPreview: true,
    );
  }

  void _showLocationUpdateValidationError(
    String rawMessage, {
    bool clearStopPreview = false,
    bool clearDestinationPreview = false,
  }) {
    if (clearStopPreview) stopUpdatePreview.value = null;
    if (clearDestinationPreview) destinationUpdatePreview.value = null;

    final parts = rawMessage.split('|');
    final hasErrorCode = parts.length > 1;
    final errorCode = hasErrorCode ? parts.first.trim() : '';
    final message = hasErrorCode
        ? parts.sublist(1).join('|').trim()
        : rawMessage.trim();

    AppDialogs.showErrorDialog(
      title: errorCode == 'VALID_PICKUP_DROP_TOO_CLOSE'
          ? AppStrings.validation.tr
          : AppStrings.error.tr,
      message: message.isNotEmpty
          ? message
          : AppStrings.somethingWentWrongPleaseTryAgain.tr,
    );
  }

  List<Map<String, dynamic>> _buildStopsPayloadForUpdate(
    List<RideStopModel> stops,
  ) {
    return stops
        .map(
          (stop) => {'lat': stop.lat, 'lng': stop.lng, 'address': stop.address},
        )
        .toList();
  }

  Future<void> _processPaymentHold(
    String validationId,
    String direction,
  ) async {
    if (direction == 'up') {
      stopUpdateProgressStep.value = 1; // Show payment step
      try {
        await _socketService.ensureConnected();
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      }
      _socketService.joinPaymentRoom(validationId: validationId);
      _joinRideRoomIfNeeded();
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
      unawaited(_ensureRideRealtimeAfterLocationUpdate());
    } else {
      stopUpdateProgressStep.value = 2; // Jump to route update (no payment)
      unawaited(_ensureRideRealtimeAfterLocationUpdate());
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
        'isSelectingDestination': true,
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
      (f) {
        if (_handleInsufficientWalletFailure(f)) return;
        _showDestinationUpdateError(f.message);
      },
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
    _clearRouteAwaitingTrackingUpdate();

    // Step 2: apply destination update (confirm=true).
    final result = await rideRepository.confirmUpdateDestination(rideId, dest);
    return result.fold(
      (f) {
        isDestinationUpdateFlow.value = false;
        stopUpdateProgressStep.value = 0;
        _pendingDestinationTargetLat = null;
        _pendingDestinationTargetLng = null;
        _pendingDestinationAppliedAfterConfirm = null;
        if (_handleInsufficientWalletFailure(f)) return false;
        _showDestinationUpdateError(f.message);
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
    DestinationUpdateAppliedModel _,
  ) async {
    // Confirm payload is fare/distance/duration only — refresh ride state.
    isDestinationUpdateFlow.value = false;
    await _ensureRideRealtimeAfterLocationUpdate();
    await _fetchRideDetails();
    stopUpdateProgressStep.value = 0;
    isUpdatingDestination.value = false;
  }
}
