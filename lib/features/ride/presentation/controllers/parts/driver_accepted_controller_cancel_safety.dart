part of '../driver_accepted_controller.dart';

/// Cancel, no-show countdown, route deviation, and emergency / safety actions.
///
/// Edit here for rider cancel flows and safety banners without touching map/socket.
extension DriverAcceptedCancelSafetyMethods on DriverAcceptedController {
  bool get shouldShowMapSafetyAction =>
      rideBottomSheetState.value == RideBottomSheetState.rideStarted;

  /// Hide cancel when backend says `can_cancel: false` (rider already in vehicle).
  bool get shouldShowRiderCancelButton {
    final info = cancelInfo.value;
    if (info == null) return true;
    return info.canCancel;
  }

  bool get shouldShowNoShowBanner => noShowInfo.value != null;

  String get noShowBannerTitle => noShowInfo.value?.title ?? '';

  String get noShowBannerSubtitle => noShowInfo.value?.subtitle ?? '';

  bool get shouldShowRouteDeviationBanner {
    final info = routeDeviationInfo.value;
    if (info == null || !info.flagged) return false;
    if (routeDeviationBannerDismissed.value && info.isOnRoute) return false;
    // Need a real off/on-route state (or an open cancellation request).
    return info.isOffRoute ||
        info.isOnRoute ||
        info.cancellationRequest != null;
  }

  bool get isRouteDeviationOffRoute =>
      routeDeviationInfo.value?.isOffRoute ?? false;

  bool get canDismissRouteDeviationBanner =>
      routeDeviationInfo.value?.isOnRoute == true &&
      !(routeDeviationInfo.value?.cancellationRequest?.isPending ?? false);

  bool get canRequestCancellationFromDeviation =>
      routeDeviationInfo.value?.canRequestCancellation == true;

  bool get isCancellationRequestPending =>
      routeDeviationInfo.value?.cancellationRequest?.isPending == true;

  bool get isCancellationRequestRejected =>
      routeDeviationInfo.value?.cancellationRequest?.isRejected == true;

  String get routeDeviationBannerTitle {
    final info = routeDeviationInfo.value;
    if (info == null) return '';
    if (info.title.isNotEmpty) return info.title;
    if (info.isOnRoute) return AppStrings.backOnRoute.tr;
    return '';
  }

  String get routeDeviationBannerSubtitle =>
      routeDeviationInfo.value?.subtitle ?? '';

  String get routeDeviationDistanceText =>
      routeDeviationInfo.value?.distanceText.trim() ?? '';

  String get cancellationRequestTicketNumber =>
      routeDeviationInfo.value?.cancellationRequest?.ticketNumber ?? '';

  String get cancellationRequestNote {
    final note = routeDeviationInfo.value?.cancellationRequest?.note?.trim();
    return note ?? '';
  }

  /// Called once from [DriverAcceptedScreen] after first frame.
  Future<void> loadEmergencyContactsOnceOnScreenOpen() async {
    if (_emergencyContactsLoadedOnce) return;
    _emergencyContactsLoadedOnce = true;
    final result = await rideRepository.getEmergencyContacts();
    result.fold(
      (f) => AppLogger.w(
        'emergency_contacts request failed: ${f.message}',
        tag: 'EmergencyContacts',
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

  void _showCancelDialogThenGoHome(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDialogs.showErrorDialog(
        title: AppStrings.rideCancelled.tr,
        message: message,
        onConfirm: () => Get.offAllNamed(AppRoutes.home),
      );
    });
  }

  Future<void> _handleRideCancelledFromTracking() async {
    await _maybeNavigateMidRideDriverCancelled();
    if (_navigatedAway) return;
    _navigatedAway = true;
    _showCancelDialogThenGoHome(AppStrings.rideCancelled.tr);
  }

  Future<void> _maybeNavigateMidRideDriverCancelled([
    MidRideCancelModel? seed,
  ]) async {
    if (_navigatedAway) return;
    final block = seed ?? await _loadMidRideCancelBlock();
    if (block == null) return;
    _navigatedAway = true;
    _skipRideRoomLeaveOnClose = true;
    await showMidRideDriverCancelledDialog(rideId: rideId, cancel: block);
  }

  Future<MidRideCancelModel?> _loadMidRideCancelBlock() async {
    if (rideId.isEmpty) return null;
    final result = await rideRepository.getRideDetails(rideId);
    return result.fold((_) => null, (r) {
      if (!r.isMidRideDriverCancel) return null;
      return r.toRideModel().midRideCancel;
    });
  }

  void _syncCancelAndNoShowFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
  ) {
    if (payload.cancelInfoFieldPresent) {
      cancelInfo.value = payload.cancelInfo;
      final current = ride.value;
      if (current != null) {
        ride.value = current.copyWith(
          cancelInfo: payload.cancelInfo,
          clearCancelInfo: payload.cancelInfo == null,
        );
      }
    }

    if (payload.noShowFieldPresent) {
      if (payload.isNoShowCancellation || payload.noShow == null) {
        _clearNoShowInfo();
      } else {
        _armNoShowInfo(payload.noShow!);
      }
    }
  }

  void _syncCancelAndNoShowFromRideModel(RideModel r) {
    if (r.cancelInfo != null) {
      cancelInfo.value = r.cancelInfo;
    }
    if (r.noShow != null) {
      // Prefer banner copy already armed from active/status payload.
      _armNoShowInfo(r.noShow!.mergingDisplayFrom(noShowInfo.value));
      return;
    }
    final normalized = normalizeRideStatusString(
      rideStatusToApiValue(r.status),
    );
    if (normalized == 'ride_started' ||
        normalized == 'ride_in_progress' ||
        normalized == 'near_destination' ||
        normalized == 'completed' ||
        normalized == 'ride_completed' ||
        normalized == 'cancelled') {
      _clearNoShowInfo();
    }
  }

  void _syncRouteDeviationFromRideModel(RideModel r) {
    if (r.routeDeviation != null) {
      _applyRouteDeviation(r.routeDeviation!);
    }
  }

  void _applyRouteDeviationFromSocket(RideRouteDeviationSocketPayload payload) {
    final detectedIso = payload.deviation.detectedAt?.toIso8601String() ?? '';
    final dedupeKey = '${payload.rideId ?? rideId}|$detectedIso';
    if (detectedIso.isNotEmpty && _lastRouteDeviationDedupeKey == dedupeKey) {
      return;
    }
    if (detectedIso.isNotEmpty) {
      _lastRouteDeviationDedupeKey = dedupeKey;
    }
    _applyRouteDeviation(
      payload.deviation.mergingFrom(routeDeviationInfo.value),
    );
  }

  void _applyRouteDeviation(RideRouteDeviationModel info) {
    final previous = routeDeviationInfo.value;
    final merged = info.mergingFrom(previous);
    // New off-route event after a dismissed on-route banner should re-show.
    if (merged.isOffRoute && previous?.isOnRoute == true) {
      routeDeviationBannerDismissed.value = false;
    }
    if (merged.isOnRoute && previous?.isOffRoute == true) {
      routeDeviationBannerDismissed.value = false;
    }
    routeDeviationInfo.value = merged;
    final current = ride.value;
    if (current != null) {
      ride.value = current.copyWith(routeDeviation: merged);
    }
  }

  void _applyCancellationRequestUpdate(
    RideCancellationRequestUpdatePayload payload,
  ) {
    final current = routeDeviationInfo.value;
    if (current == null) return;
    final updatedRequest = RideCancellationRequestModel(
      ticketId: payload.ticketId.isNotEmpty
          ? payload.ticketId
          : (current.cancellationRequest?.ticketId ?? ''),
      ticketNumber: payload.ticketNumber.isNotEmpty
          ? payload.ticketNumber
          : (current.cancellationRequest?.ticketNumber ?? ''),
      status: payload.status,
      requestedAt: current.cancellationRequest?.requestedAt,
      note: payload.note,
    );
    _applyRouteDeviation(
      current.copyWith(
        cancellationRequest: updatedRequest,
        canRequestCancellation:
            updatedRequest.isRejected || updatedRequest.isWithdrawn,
      ),
    );
  }

  void dismissRouteDeviationBanner() {
    routeDeviationBannerDismissed.value = true;
  }

  /// Ride-started / safety sheet "Having trouble?" — same cancellation-request sheet.
  Future<void> openHavingTroubleCancellationSheet() {
    return openRequestCancellationSheet(force: true);
  }

  /// Safety options sheet entry — close the sheet, then open the request flow.
  Future<void> openHavingTroubleFromSafetySheet() async {
    AppDialogs.closeActiveDialog();
    await openHavingTroubleCancellationSheet();
  }

  Future<void> openRequestCancellationSheet({bool force = false}) async {
    if (!force && !canRequestCancellationFromDeviation) return;
    final data = await RequestCancellationFlow(
      rideRepository: rideRepository,
      rideId: rideId,
    ).run();
    if (data == null) return;

    final current = routeDeviationInfo.value;
    final request = RideCancellationRequestModel(
      ticketId: data.ticketId,
      ticketNumber: data.ticketNumber,
      status: data.status.isNotEmpty ? data.status : 'pending',
      requestedAt: DateTime.now().toUtc(),
    );
    if (current != null) {
      _applyRouteDeviation(
        current.copyWith(
          cancellationRequest: request,
          canRequestCancellation: false,
        ),
      );
    } else {
      _applyRouteDeviation(
        RideRouteDeviationModel(
          flagged: true,
          state: 'off_route',
          deviationMeters: 0,
          distanceText: '',
          alertCount: 0,
          maxDeviationMeters: 0,
          title: '',
          subtitle: '',
          canContactSupport: true,
          canRequestCancellation: false,
          cancellationRequest: request,
        ),
      );
    }

    AppDialogs.showSuccessDialog(
      title: AppStrings.requestToCancel.tr,
      message: AppStrings.cancellationRequestSentWithTicket.trParams({
        'ticket': data.ticketNumber,
      }),
    );
  }

  Future<void> withdrawCancellationRequest() async {
    final ticketId =
        routeDeviationInfo.value?.cancellationRequest?.ticketId.trim() ?? '';
    if (ticketId.isEmpty) return;

    Failure? failure;
    await Loader.run(() async {
      final result = await rideRepository.withdrawCancellationRequest(ticketId);
      result.fold((f) => failure = f, (_) {});
    });

    if (failure is CancellationRequestAlreadyDecidedFailure) {
      AppDialogs.showErrorDialog(
        title: AppStrings.submitFailed.tr,
        message: failure!.message.isNotEmpty
            ? failure!.message
            : AppStrings.cancellationRequestAlreadyDecided.tr,
      );
      await _fetchRideDetails();
      return;
    }

    if (failure != null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.submitFailed.tr,
        message: failure!.message.isNotEmpty
            ? failure!.message
            : AppStrings.couldNotWithdrawCancellationRequest.tr,
      );
      return;
    }

    final current = routeDeviationInfo.value;
    if (current == null) return;
    final prior = current.cancellationRequest;
    _applyRouteDeviation(
      current.copyWith(
        cancellationRequest: prior?.copyWith(status: 'withdrawn'),
        canRequestCancellation: true,
      ),
    );
  }

  void _armNoShowInfo(RideNoShowInfoModel info) {
    // Keep title/subtitle from active/socket when a later details refresh
    // only sends fire_at / fee without banner copy.
    final merged = info.mergingDisplayFrom(noShowInfo.value);
    noShowInfo.value = merged;
    isNoShowExpiring.value = false;
    final fireIso = merged.fireAt.toIso8601String();
    if (_armedNoShowFireAtIso == fireIso && _noShowCountdown != null) {
      noShowCountdownLabel.value = merged.formatRemainingMmSs();
      final current = ride.value;
      if (current != null) {
        ride.value = current.copyWith(noShow: merged);
      }
      return;
    }
    _armedNoShowFireAtIso = fireIso;
    noShowCountdownLabel.value = merged.formatRemainingMmSs();
    _noShowCountdown?.stop();
    _noShowCountdown = PaymentCountdownTimer(
      onTick: (remainingSeconds) {
        final mins = remainingSeconds ~/ 60;
        final secs = remainingSeconds % 60;
        noShowCountdownLabel.value =
            '${mins.toString().padLeft(2, '0')}:'
            '${secs.toString().padLeft(2, '0')}';
      },
      onExpired: () {
        // Display-only — server cancels; show brief waiting state.
        noShowCountdownLabel.value = '00:00';
        isNoShowExpiring.value = true;
      },
    )..startUntil(merged.fireAt);

    final current = ride.value;
    if (current != null) {
      ride.value = current.copyWith(noShow: merged);
    }
  }

  void _clearNoShowInfo() {
    _stopNoShowCountdown(clearInfo: true);
  }

  void _stopNoShowCountdown({bool clearInfo = false}) {
    _noShowCountdown?.stop();
    _noShowCountdown = null;
    _armedNoShowFireAtIso = null;
    isNoShowExpiring.value = false;
    if (clearInfo) {
      noShowInfo.value = null;
      noShowCountdownLabel.value = '00:00';
      final current = ride.value;
      if (current != null && current.noShow != null) {
        ride.value = current.copyWith(clearNoShow: true);
      }
    }
  }

  Future<void> confirmCancelRide() {
    // Driver-details bottom sheet — shared [CancelRideFlow] (canonical implementation).
    return CancelRideFlow(
      rideRepository: rideRepository,
      rideId: rideId,
      cancelInfo: cancelInfo.value,
      onCancelApiStarted: () {
        _isUserInitiatedCancellation = true;
        _navigatedAway = true;
      },
      onCancelApiFailed: () {
        _isUserInitiatedCancellation = false;
        _navigatedAway = false;
      },
      onRideAlreadyFinalized: () {
        // Race with server no-show finalize — stay on screen and await socket.
        _isUserInitiatedCancellation = false;
        _navigatedAway = false;
        isNoShowExpiring.value = true;
        unawaited(_fetchRideDetails());
      },
    ).run();
  }
}
