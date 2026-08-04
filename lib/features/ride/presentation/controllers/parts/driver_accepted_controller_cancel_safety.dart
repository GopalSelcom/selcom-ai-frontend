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
    if (!info.isOffRoute && !info.isOnRoute) return false;
    final cancel = info.cancellationRequest;
    final hasOpenCancel =
        cancel != null && (cancel.isPending || cancel.isRejected);
    // Continue-to-trip / on-route close hides until a new transition re-arms.
    // Keep visible when a deviation-scoped cancel request is still open.
    if (routeDeviationBannerDismissed.value && !hasOpenCancel) return false;
    return true;
  }

  bool get isRouteDeviationOffRoute =>
      routeDeviationInfo.value?.isOffRoute ?? false;

  bool get canDismissRouteDeviationBanner =>
      routeDeviationInfo.value?.isOnRoute == true &&
      !(routeDeviationInfo.value?.cancellationRequest?.isPending ?? false);

  bool get canRequestCancellationFromDeviation =>
      routeDeviationInfo.value?.canRequestCancellation == true &&
      !(requestToCancelInfo.value?.isPending ?? false);

  bool get isDeviationCancellationPending =>
      routeDeviationInfo.value?.cancellationRequest?.isPending == true;

  bool get isDeviationCancellationRejected =>
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

  String get deviationCancellationTicketNumber =>
      routeDeviationInfo.value?.cancellationRequest?.ticketNumber ?? '';

  String get deviationCancellationNote {
    final note = routeDeviationInfo.value?.cancellationRequest?.note?.trim();
    return note ?? '';
  }

  bool get shouldShowRequestToCancelBanner {
    final request = requestToCancelInfo.value;
    return request != null && (request.isPending || request.isRejected);
  }

  bool get isRequestToCancelPending =>
      requestToCancelInfo.value?.isPending == true;

  bool get isRequestToCancelRejected =>
      requestToCancelInfo.value?.isRejected == true;

  String get requestToCancelTicketNumber =>
      requestToCancelInfo.value?.ticketNumber ?? '';

  String get requestToCancelNote {
    final note = requestToCancelInfo.value?.note?.trim();
    return note ?? '';
  }

  bool get canRetryRequestToCancel => isRequestToCancelRejected;

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
    final deviation = r.routeDeviation;
    if (deviation == null) return;
    if (deviation.isOffRoute || deviation.isOnRoute) {
      _applyRouteDeviation(deviation);
      return;
    }
    // REST cancel-only shell (no off/on-route) belongs to Request-to-cancel lane.
    final request = deviation.cancellationRequest;
    if (request != null) {
      _applyRequestToCancelInfo(request);
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
    _clearRequestToCancelIfSameTicket(merged.cancellationRequest);
    final current = ride.value;
    if (current != null) {
      ride.value = current.copyWith(routeDeviation: merged);
    }
  }

  void _applyRequestToCancelInfo(RideCancellationRequestModel request) {
    requestToCancelInfo.value = request;
    _clearDeviationCancellationIfSameTicket(request);
    // One pending request per ride — block deviation "Request to cancel".
    final deviation = routeDeviationInfo.value;
    if (deviation != null && request.isPending) {
      routeDeviationInfo.value = deviation.copyWith(
        canRequestCancellation: false,
      );
    }
  }

  void _clearRequestToCancelIfSameTicket(
    RideCancellationRequestModel? request,
  ) {
    if (request == null) return;
    final existing = requestToCancelInfo.value;
    if (existing == null) return;
    if (_sameCancellationTicket(existing, request)) {
      requestToCancelInfo.value = null;
    }
  }

  void _clearDeviationCancellationIfSameTicket(
    RideCancellationRequestModel request,
  ) {
    final deviation = routeDeviationInfo.value;
    final existing = deviation?.cancellationRequest;
    if (deviation == null || existing == null) return;
    if (!_sameCancellationTicket(existing, request)) return;
    routeDeviationInfo.value = deviation.copyWith(
      clearCancellationRequest: true,
      canRequestCancellation: request.isWithdrawn || request.isRejected,
    );
  }

  bool _sameCancellationTicket(
    RideCancellationRequestModel a,
    RideCancellationRequestModel b,
  ) {
    final aId = a.ticketId.trim();
    final bId = b.ticketId.trim();
    if (aId.isNotEmpty && bId.isNotEmpty && aId == bId) return true;
    final aNum = a.ticketNumber.trim();
    final bNum = b.ticketNumber.trim();
    return aNum.isNotEmpty && bNum.isNotEmpty && aNum == bNum;
  }

  void _applyCancellationRequestUpdate(
    RideCancellationRequestUpdatePayload payload,
  ) {
    final updatedRequest = RideCancellationRequestModel(
      ticketId: payload.ticketId,
      ticketNumber: payload.ticketNumber,
      status: payload.status,
      note: payload.note,
    );

    final standalone = requestToCancelInfo.value;
    if (standalone != null &&
        (payload.ticketId.isEmpty ||
            _sameCancellationTicket(standalone, updatedRequest))) {
      requestToCancelInfo.value = RideCancellationRequestModel(
        ticketId: payload.ticketId.isNotEmpty
            ? payload.ticketId
            : standalone.ticketId,
        ticketNumber: payload.ticketNumber.isNotEmpty
            ? payload.ticketNumber
            : standalone.ticketNumber,
        status: payload.status,
        requestedAt: standalone.requestedAt,
        note: payload.note,
      );
      final deviation = routeDeviationInfo.value;
      if (deviation != null &&
          (updatedRequest.isRejected || updatedRequest.isWithdrawn)) {
        routeDeviationInfo.value = deviation.copyWith(
          canRequestCancellation: true,
        );
      }
      return;
    }

    final current = routeDeviationInfo.value;
    if (current == null) {
      if (updatedRequest.isPending || updatedRequest.isRejected) {
        _applyRequestToCancelInfo(
          RideCancellationRequestModel(
            ticketId: payload.ticketId,
            ticketNumber: payload.ticketNumber,
            status: payload.status,
            note: payload.note,
          ),
        );
      }
      return;
    }

    final existing = current.cancellationRequest;
    _applyRouteDeviation(
      current.copyWith(
        cancellationRequest: RideCancellationRequestModel(
          ticketId: payload.ticketId.isNotEmpty
              ? payload.ticketId
              : (existing?.ticketId ?? ''),
          ticketNumber: payload.ticketNumber.isNotEmpty
              ? payload.ticketNumber
              : (existing?.ticketNumber ?? ''),
          status: payload.status,
          requestedAt: existing?.requestedAt,
          note: payload.note,
        ),
        canRequestCancellation:
            updatedRequest.isRejected || updatedRequest.isWithdrawn,
      ),
    );
  }

  void dismissRouteDeviationBanner() {
    routeDeviationBannerDismissed.value = true;
  }

  /// Off-route "Continue to trip" — dismiss banner only; no info dialog.
  void continueToTripFromDeviation() {
    dismissRouteDeviationBanner();
  }

  /// Safety options / ride sheet "Request to cancel" — standalone cancel-request lane.
  ///
  /// [forceRetry] skips the rejected-status info gate (banner "Request to cancel"
  /// after support declined).
  Future<void> openRequestToCancelSheet({
    bool forceRetry = false,
  }) async {
    if (_showExistingRequestToCancelStatus(
      allowRejectedRetry: forceRetry,
    )) {
      return;
    }
    await _openCancellationRequestSheet(forDeviation: false);
  }

  /// Safety options sheet entry — close the sheet, then open the request flow.
  Future<void> openRequestToCancelFromSafetySheet() async {
    AppDialogs.closeActiveDialog();
    await openRequestToCancelSheet();
  }

  /// Off-route banner "Request to cancel" — deviation-scoped cancel lane.
  Future<void> openRequestCancellationSheet() {
    return _openCancellationRequestSheet(forDeviation: true);
  }

  /// Returns true when Request to cancel should not open a new request sheet.
  bool _showExistingRequestToCancelStatus({
    bool allowRejectedRetry = false,
  }) {
    final request = requestToCancelInfo.value ??
        routeDeviationInfo.value?.cancellationRequest;
    if (request == null) return false;

    final ticket = request.ticketNumber.trim();
    final note = request.note?.trim() ?? '';

    if (request.isPending) {
      AppDialogs.showInfoDialog(
        title: AppStrings.requestToCancel.tr,
        message: AppStrings.cancellationRequestAlreadyPending.trParams({
          'ticket': ticket.isNotEmpty ? ticket : '—',
        }),
      );
      return true;
    }

    if (request.isRejected) {
      if (allowRejectedRetry) return false;
      final message = note.isNotEmpty
          ? '${AppStrings.supportDeclinedCancellation.tr}\n\n$note'
          : AppStrings.supportDeclinedCancellation.tr;
      AppDialogs.showInfoDialog(
        title: AppStrings.requestToCancel.tr,
        message: message,
      );
      return true;
    }

    if (request.isApproved) {
      AppDialogs.showInfoDialog(
        title: AppStrings.requestToCancel.tr,
        message: AppStrings.cancellationRequestAlreadyDecided.tr,
      );
      return true;
    }

    // Withdrawn — allow submitting a new request without blocking.
    return false;
  }

  Future<void> _openCancellationRequestSheet({
    required bool forDeviation,
  }) async {
    if (forDeviation && !canRequestCancellationFromDeviation) return;
    final hasPendingRequestToCancel =
        requestToCancelInfo.value?.isPending ?? false;
    final hasPendingDeviation =
        routeDeviationInfo.value?.cancellationRequest?.isPending ?? false;
    if (!forDeviation &&
        (hasPendingRequestToCancel || hasPendingDeviation)) {
      _showExistingRequestToCancelStatus();
      return;
    }

    final data = await RequestCancellationFlow(
      rideRepository: rideRepository,
      rideId: rideId,
    ).run();
    if (data == null) return;

    final request = RideCancellationRequestModel(
      ticketId: data.ticketId,
      ticketNumber: data.ticketNumber,
      status: data.status.isNotEmpty ? data.status : 'pending',
      requestedAt: DateTime.now().toUtc(),
    );

    if (forDeviation) {
      final current = routeDeviationInfo.value;
      if (current == null) return;
      _applyRouteDeviation(
        current.copyWith(
          cancellationRequest: request,
          canRequestCancellation: false,
        ),
      );
      return;
    }

    _applyRequestToCancelInfo(request);
  }

  Future<void> withdrawDeviationCancellationRequest() {
    return _withdrawCancellationRequest(fromDeviation: true);
  }

  Future<void> withdrawRequestToCancel() {
    return _withdrawCancellationRequest(fromDeviation: false);
  }

  Future<void> _withdrawCancellationRequest({
    required bool fromDeviation,
  }) async {
    final ticketId = fromDeviation
        ? (routeDeviationInfo.value?.cancellationRequest?.ticketId.trim() ?? '')
        : (requestToCancelInfo.value?.ticketId.trim() ?? '');
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

    if (fromDeviation) {
      final current = routeDeviationInfo.value;
      if (current == null) return;
      final prior = current.cancellationRequest;
      _applyRouteDeviation(
        current.copyWith(
          cancellationRequest: prior?.copyWith(status: 'withdrawn'),
          canRequestCancellation: true,
        ),
      );
      return;
    }

    final prior = requestToCancelInfo.value;
    requestToCancelInfo.value = prior?.copyWith(status: 'withdrawn');
    final deviation = routeDeviationInfo.value;
    if (deviation != null) {
      routeDeviationInfo.value = deviation.copyWith(
        canRequestCancellation: true,
      );
    }
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
