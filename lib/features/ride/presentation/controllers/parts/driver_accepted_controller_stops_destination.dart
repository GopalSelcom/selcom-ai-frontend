part of '../driver_accepted_controller.dart';

/// Mid-ride stop edits and drop-location changes (preview, confirm, wallet hold).
///
/// Edit here for stop/destination update APIs and insufficient-wallet handling.
class DriverAcceptedStopsDestinationHelper {
  DriverAcceptedStopsDestinationHelper(this.c);

  /// Parent [DriverAcceptedController] — shared ride state and lifecycle.
  final DriverAcceptedController c;

  /// Opens the stop editor when no prior stop update is in flight.
  void onEditStops() {
    if (c.isUpdatingStops.value) {
      AppDialogs.showInfoDialog(
        title: AppStrings.updateInProgress.tr,
        message: AppStrings.aPreviousUpdateIsStillBeingProcessed.tr,
      );
      return;
    }
    c.stopUpdateIdempotencyKey.value = const Uuid().v4();
    Get.toNamed(AppRoutes.stopEditor, arguments: {'ride': c.ride.value});
  }

  /// Preview stop changes (`confirm: false`) and store fare delta preview.
  Future<void> previewStopsUpdate(List<RideStopModel> stops) async {
    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await c.rideRepository.updateStops(
      c.rideId,
      stops: stopsJson,
      confirm: false,
      idempotencyKey: c.stopUpdateIdempotencyKey.value,
    );

    result.fold(
      (f) {
        if (_handleInsufficientWalletFailure(f)) return;
        _showStopUpdateError(f.message);
      },
      (res) {
        if (res is StopUpdatePreviewModel) {
          c.stopUpdatePreview.value = res;
          // Generate key if not present and save it
          if (c.stopUpdateIdempotencyKey.value.isEmpty) {
            c.stopUpdateIdempotencyKey.value = const Uuid().v4();
          }
          c._saveIdempotencyKey(c.stopUpdateIdempotencyKey.value);
        }
      },
    );
  }

  /// Confirms stop changes (`confirm: true`) or resumes a pending payment hold.
  Future<bool> applyStopsUpdate(List<RideStopModel> stops) async {
    final pending = c.ride.value?.pendingStopsUpdate;
    if (pending != null &&
        pending.status == 'pending_payment' &&
        pending.validationId != null) {
      c._pendingStopPaymentValidationId = pending.validationId;
      c._pendingStopPaymentDirection = pending.direction;
      return true;
    }

    final stopsJson = _buildStopsPayloadForUpdate(stops);

    final result = await c.rideRepository.updateStops(
      c.rideId,
      stops: stopsJson,
      confirm: true,
      idempotencyKey: c.stopUpdateIdempotencyKey.value,
    );

    return result.fold(
      (f) {
        c._clearIdempotencyKey();
        c.stopUpdateProgressStep.value = 0;
        if (_handleInsufficientWalletFailure(f)) return false;
        _showStopUpdateError(f.message);
        return false;
      },
      (res) {
        if (res is StopUpdateAppliedModel) {
          c.stopUpdateApplied.value = res;
          c.stopUpdatePreview.value = null;
          c._pendingStopAppliedAfterConfirm = res;
          return true;
        }
        return false;
      },
    );
  }

  /// Called after [StopEditorScreen] pops on add-stops confirm success.
  Future<void> onStopEditorClosedAfterConfirm() async {
    final resumeValidationId = c._pendingStopPaymentValidationId;
    if (resumeValidationId != null) {
      final direction = c._pendingStopPaymentDirection ?? '';
      c._pendingStopPaymentValidationId = null;
      c._pendingStopPaymentDirection = null;
      c.isUpdatingStops.value = true;
      c.stopUpdateProgressStep.value = 1;
      c.mapHelper._clearRouteAwaitingTrackingUpdate();
      await _processPaymentHold(resumeValidationId, direction);
      return;
    }

    final applied = c._pendingStopAppliedAfterConfirm;
    if (applied == null) return;
    c._pendingStopAppliedAfterConfirm = null;
    await _finalizeStopsConfirm(applied);
  }

  /// After confirm: starts payment hold progress or refreshes SCR-11 immediately.
  Future<void> _finalizeStopsConfirm(StopUpdateAppliedModel applied) async {
    // Confirm sample has no validation_id; payment resume uses pendingStopsUpdate.
    if (applied.blockUpdateRequired == true) {
      c.isUpdatingStops.value = true;
      c.stopUpdateProgressStep.value = 1;
      c.mapHelper._clearRouteAwaitingTrackingUpdate();
      await c._fetchRideDetails();
      return;
    }

    // Instant success — mirror change-drop flow: refresh SCR-11, no progress sheet.
    c._clearIdempotencyKey();
    c.stopUpdateProgressStep.value = 0;
    c.isUpdatingStops.value = false;
    c.mapHelper._clearRouteAwaitingTrackingUpdate();
    await c.socketHelper._ensureRideRealtimeAfterLocationUpdate();
    await c._fetchRideDetails();
  }

  /// Shows a stop-update validation error and clears the stop preview.
  void _showStopUpdateError(String rawMessage) {
    _showLocationUpdateValidationError(rawMessage, clearStopPreview: true);
  }

  /// Insufficient-wallet dialog with top-up CTA for stop/destination updates.
  Future<void> _showInsufficientWalletDialog(
    InsufficientWalletBalanceDetails details,
  ) async {
    await AppDialogs.showInsufficientWalletBalanceDialog(
      details: details,
      onTopUp: _openWalletTopUp,
    );
  }

  /// Opens the add-money-to-wallet sheet.
  void _openWalletTopUp() {
    unawaited(AddMoneyToWalletBottomSheet.show());
  }

  /// Handles [InsufficientWalletBalanceFailure]; returns true when consumed.
  bool _handleInsufficientWalletFailure(Failure failure) {
    if (failure is InsufficientWalletBalanceFailure) {
      unawaited(_showInsufficientWalletDialog(failure.details));
      return true;
    }
    return false;
  }

  /// Shows a destination-update validation error and clears that preview.
  void _showDestinationUpdateError(String rawMessage) {
    _showLocationUpdateValidationError(
      rawMessage,
      clearDestinationPreview: true,
    );
  }

  /// Parses `code|message` validation errors into an error dialog.
  void _showLocationUpdateValidationError(
    String rawMessage, {
    bool clearStopPreview = false,
    bool clearDestinationPreview = false,
  }) {
    if (clearStopPreview) c.stopUpdatePreview.value = null;
    if (clearDestinationPreview) c.destinationUpdatePreview.value = null;

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

  /// Builds lat/lng/address maps for the update-stops API body.
  List<Map<String, dynamic>> _buildStopsPayloadForUpdate(
    List<RideStopModel> stops,
  ) {
    return stops
        .map(
          (stop) => {'lat': stop.lat, 'lng': stop.lng, 'address': stop.address},
        )
        .toList();
  }

  /// Joins payment room (up) or skips to route-update phase (down / none).
  Future<void> _processPaymentHold(
    String validationId,
    String direction,
  ) async {
    if (direction == 'up') {
      c.stopUpdateProgressStep.value = 1; // Show payment step
      try {
        await c._socketService.ensureConnected();
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      }
      c._socketService.joinPaymentRoom(validationId: validationId);
      c.socketHelper._joinRideRoomIfNeeded();
      if (AppConfig.ridePaymentBypass) {
        await c.rideRepository.walletDummyPaymentRequest(
          DummyPaymentRequest(
            result: 'SUCCESS',
            transId: 'TXN-${const Uuid().v4()}',
            validationId: validationId,
          ),
        );
      }
    } else if (direction == 'down') {
      c.stopUpdateProgressStep.value = 2; // Jump to route update (silent payment)
      unawaited(c.socketHelper._ensureRideRealtimeAfterLocationUpdate());
    } else {
      c.stopUpdateProgressStep.value = 2; // Jump to route update (no payment)
      unawaited(c.socketHelper._ensureRideRealtimeAfterLocationUpdate());
    }

    // The socket listeners will handle the rest of the flow
    _startStopUpdateTimeout();
  }

  /// 90s timeout + periodic poll while a stop update is in progress.
  void _startStopUpdateTimeout() {
    Future.delayed(const Duration(seconds: 90), () {
      if (c.isUpdatingStops.value) {
        c.isUpdatingStops.value = false;
        c.stopUpdateProgressStep.value = 0;
        AppDialogs.showInfoDialog(
          title: AppStrings.takingLongerThanExpected.tr,
          message:
              AppStrings.theUpdateIsTakingSomeTimePleaseCheckBackShortly.tr,
        );
        c._fetchRideDetails();
      }
    });

    // Periodic poll fallback for socket events
    _pollForStopUpdateResult();
  }

  /// Polls ride details every 8s while waiting on route-update phase.
  void _pollForStopUpdateResult() {
    Future.delayed(const Duration(seconds: 8), () {
      if (c.isUpdatingStops.value && c.stopUpdateProgressStep.value == 2) {
        c._fetchRideDetails();
        _pollForStopUpdateResult();
      }
    });
  }

  /// Opens the change-drop editor when no location update is already running.
  Future<void> onChangeDropLocation() async {
    if (c.rideId.isEmpty) return;
    if (c.isUpdatingStops.value || c.isUpdatingDestination.value) {
      AppDialogs.showInfoDialog(
        title: AppStrings.updateInProgress.tr,
        message: AppStrings.aPreviousUpdateIsStillBeingProcessed.tr,
      );
      return;
    }
    if (c.statusLabelsHelper.isNearDestination()) return;
    if (c.ride.value?.pendingStopsUpdate != null) return;
    Get.toNamed(
      AppRoutes.changeDropLocationEditor,
      arguments: {'ride': c.ride.value, 'editorMode': 'destination'},
    );
  }

  /// Opens stop-style picker and returns one destination (lat/lng/address).
  ///
  /// Keeps destination selection UX consistent with add-stop selection.
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

  /// Preview destination change (`confirm: false`) and store fare preview.
  Future<void> previewDropLocationUpdate(
    Map<String, dynamic> destination,
  ) async {
    c.destinationUpdatePreview.value = null;
    final dest = _buildDestinationPayload(destination);
    if (dest == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.error.tr,
        message: AppStrings.addressMissing.tr,
      );
      return;
    }
    // Step 1: preview update-destination (confirm=false).
    final previewRes = await c.rideRepository.previewUpdateDestination(
      c.rideId,
      dest,
    );
    previewRes.fold(
      (f) {
        if (_handleInsufficientWalletFailure(f)) return;
        _showDestinationUpdateError(f.message);
      },
      (preview) {
        c.destinationUpdatePreview.value = preview;
      },
    );
  }

  /// Confirms destination change (`confirm: true`) after editor validation.
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

  /// Validates and normalizes a destination map for the update-destination API.
  Map<String, dynamic>? _buildDestinationPayload(Map<String, dynamic> result) {
    final lat = (result['lat'] as num?)?.toDouble();
    final lng = (result['lng'] as num?)?.toDouble();
    final address = result['address']?.toString().trim() ?? '';
    if (lat == null || lng == null || address.isEmpty) return null;
    return <String, dynamic>{'lat': lat, 'lng': lng, 'address': address};
  }

  /// Extracts lat/lng/address from saved-location picker result shapes.
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

  /// Calls confirm update-destination and stashes applied result for post-pop.
  Future<bool> _applyDestinationConfirm(Map<String, dynamic> dest) async {
    final lat = (dest['lat'] as num).toDouble();
    final lng = (dest['lng'] as num).toDouble();
    c._pendingDestinationTargetLat = lat;
    c._pendingDestinationTargetLng = lng;

    c.isDestinationUpdateFlow.value = true;
    c.mapHelper._clearRouteAwaitingTrackingUpdate();

    // Step 2: apply destination update (confirm=true).
    final result = await c.rideRepository.confirmUpdateDestination(c.rideId, dest);
    return result.fold(
      (f) {
        c.isDestinationUpdateFlow.value = false;
        c.stopUpdateProgressStep.value = 0;
        c._pendingDestinationTargetLat = null;
        c._pendingDestinationTargetLng = null;
        c._pendingDestinationAppliedAfterConfirm = null;
        if (_handleInsufficientWalletFailure(f)) return false;
        _showDestinationUpdateError(f.message);
        return false;
      },
      (DestinationUpdateAppliedModel applied) {
        c.destinationUpdatePreview.value = null;
        // Finalize after the editor screen pops so progress UI shows on SCR-11.
        c._pendingDestinationAppliedAfterConfirm = applied;
        return true;
      },
    );
  }

  /// Called after [StopEditorScreen] pops on confirm success.
  Future<void> onChangeDropLocationEditorClosedAfterConfirm() async {
    final applied = c._pendingDestinationAppliedAfterConfirm;
    if (applied == null) return;
    c._pendingDestinationAppliedAfterConfirm = null;
    await _finalizeDestinationConfirm(applied);
  }

  /// After drop confirm: rejoins realtime and refreshes ride details on SCR-11.
  Future<void> _finalizeDestinationConfirm(
    DestinationUpdateAppliedModel _,
  ) async {
    // Confirm payload is fare/distance/duration only — refresh ride state.
    c.isDestinationUpdateFlow.value = false;
    await c.socketHelper._ensureRideRealtimeAfterLocationUpdate();
    await c._fetchRideDetails();
    c.stopUpdateProgressStep.value = 0;
    c.isUpdatingDestination.value = false;
  }
}
