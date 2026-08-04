part of '../driver_accepted_controller.dart';

/// Cancel, no-show countdown, route deviation, and emergency / safety actions.
///
/// Edit here for rider cancel flows and safety banners without touching map/socket.
class DriverAcceptedCancelSafetyHelper {
  DriverAcceptedCancelSafetyHelper(this.c);

  /// Parent [DriverAcceptedController] — shared ride state and lifecycle.
  final DriverAcceptedController c;

  /// True when the in-trip map safety FAB should be visible.
  bool get shouldShowMapSafetyAction =>
      c.rideBottomSheetState.value == RideBottomSheetState.rideStarted;

  /// Hide cancel when backend says `can_cancel: false` (rider already in vehicle).
  bool get shouldShowRiderCancelButton {
    final info = c.cancelInfo.value;
    if (info == null) return true;
    return info.canCancel;
  }

  /// Whether the no-show countdown banner has armed info.
  bool get shouldShowNoShowBanner => c.noShowInfo.value != null;

  /// Primary no-show banner title from server copy.
  String get noShowBannerTitle => c.noShowInfo.value?.title ?? '';

  /// Secondary no-show banner subtitle from server copy.
  String get noShowBannerSubtitle => c.noShowInfo.value?.subtitle ?? '';

  /// Whether the off/on-route deviation banner should render.
  bool get shouldShowRouteDeviationBanner {
    final info = c.routeDeviationInfo.value;
    if (info == null || !info.flagged) return false;
    if (!info.isOffRoute && !info.isOnRoute) return false;
    final cancel = info.cancellationRequest;
    final hasOpenCancel =
        cancel != null && (cancel.isPending || cancel.isRejected);
    // Continue-to-trip / on-route close hides until a new transition re-arms.
    // Keep visible when a deviation-scoped cancel request is still open.
    if (c.routeDeviationBannerDismissed.value && !hasOpenCancel) return false;
    return true;
  }

  /// True while the latest deviation state is off-route.
  bool get isRouteDeviationOffRoute =>
      c.routeDeviationInfo.value?.isOffRoute ?? false;

  /// On-route banners may dismiss unless a cancel request is still pending.
  bool get canDismissRouteDeviationBanner =>
      c.routeDeviationInfo.value?.isOnRoute == true &&
      !(c.routeDeviationInfo.value?.cancellationRequest?.isPending ?? false);

  /// Off-route "Request to cancel" is allowed when no pending cancel exists.
  bool get canRequestCancellationFromDeviation =>
      c.routeDeviationInfo.value?.canRequestCancellation == true &&
      !(c.requestToCancelInfo.value?.isPending ?? false);

  /// Deviation-scoped cancellation request is awaiting support.
  bool get isDeviationCancellationPending =>
      c.routeDeviationInfo.value?.cancellationRequest?.isPending == true;

  /// Deviation-scoped cancellation request was declined by support.
  bool get isDeviationCancellationRejected =>
      c.routeDeviationInfo.value?.cancellationRequest?.isRejected == true;

  /// Deviation banner title (API copy, or "back on route" fallback).
  String get routeDeviationBannerTitle {
    final info = c.routeDeviationInfo.value;
    if (info == null) return '';
    if (info.title.isNotEmpty) return info.title;
    if (info.isOnRoute) return AppStrings.backOnRoute.tr;
    return '';
  }

  /// Deviation banner supporting subtitle from server.
  String get routeDeviationBannerSubtitle =>
      c.routeDeviationInfo.value?.subtitle ?? '';

  /// Human-readable off-route distance string for the banner.
  String get routeDeviationDistanceText =>
      c.routeDeviationInfo.value?.distanceText.trim() ?? '';

  /// Ticket number for a deviation-scoped cancel request.
  String get deviationCancellationTicketNumber =>
      c.routeDeviationInfo.value?.cancellationRequest?.ticketNumber ?? '';

  /// Optional support note on a deviation-scoped cancel request.
  String get deviationCancellationNote {
    final note = c.routeDeviationInfo.value?.cancellationRequest?.note?.trim();
    return note ?? '';
  }

  /// Standalone Request-to-cancel banner (pending or rejected).
  bool get shouldShowRequestToCancelBanner {
    final request = c.requestToCancelInfo.value;
    return request != null && (request.isPending || request.isRejected);
  }

  /// Standalone Request-to-cancel is awaiting support decision.
  bool get isRequestToCancelPending =>
      c.requestToCancelInfo.value?.isPending == true;

  /// Standalone Request-to-cancel was declined by support.
  bool get isRequestToCancelRejected =>
      c.requestToCancelInfo.value?.isRejected == true;

  /// Ticket number for the standalone Request-to-cancel lane.
  String get requestToCancelTicketNumber =>
      c.requestToCancelInfo.value?.ticketNumber ?? '';

  /// Optional support note on the standalone Request-to-cancel.
  String get requestToCancelNote {
    final note = c.requestToCancelInfo.value?.note?.trim();
    return note ?? '';
  }

  /// Rejected Request-to-cancel may open a new request sheet.
  bool get canRetryRequestToCancel => isRequestToCancelRejected;

  /// Called once from [DriverAcceptedScreen] after first frame.
  Future<void> loadEmergencyContactsOnceOnScreenOpen() async {
    if (c._emergencyContactsLoadedOnce) return;
    c._emergencyContactsLoadedOnce = true;
    final result = await c.rideRepository.getEmergencyContacts();
    result.fold(
      (f) => AppLogger.w(
        'emergency_contacts request failed: ${f.message}',
        tag: 'EmergencyContacts',
      ),
      (EmergencyContactsResponse res) {
        c.emergencyContacts.assignAll(res.data.contacts);
      },
    );
  }

  /// Icon for an emergency contact row by API contact `id`.
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

  /// Opens the system dialer for an emergency contact phone number.
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
    await c.commsLiveHelper._launchSystemPhoneDialer(
      phone: phone,
      errorDialogTitle: contact.label.isEmpty
          ? AppStrings.call.tr
          : contact.label,
    );
  }

  /// Shows ride-cancelled dialog then navigates home on confirm.
  void _showCancelDialogThenGoHome(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppDialogs.showErrorDialog(
        title: AppStrings.rideCancelled.tr,
        message: message,
        onConfirm: () => Get.offAllNamed(AppRoutes.home),
      );
    });
  }

  /// Handles cancel signal from tracking when status stream already left.
  Future<void> _handleRideCancelledFromTracking() async {
    await _maybeNavigateMidRideDriverCancelled();
    if (c._navigatedAway) return;
    c._navigatedAway = true;
    _showCancelDialogThenGoHome(AppStrings.rideCancelled.tr);
  }

  /// Mid-ride driver cancel → dedicated dialog when details include that block.
  Future<void> _maybeNavigateMidRideDriverCancelled([
    MidRideCancelModel? seed,
  ]) async {
    if (c._navigatedAway) return;
    final block = seed ?? await _loadMidRideCancelBlock();
    if (block == null) return;
    c._navigatedAway = true;
    c._skipRideRoomLeaveOnClose = true;
    await showMidRideDriverCancelledDialog(rideId: c.rideId, cancel: block);
  }

  /// Fetches ride details and returns mid-ride cancel payload when present.
  Future<MidRideCancelModel?> _loadMidRideCancelBlock() async {
    if (c.rideId.isEmpty) return null;
    final result = await c.rideRepository.getRideDetails(c.rideId);
    return result.fold((_) => null, (r) {
      if (!r.isMidRideDriverCancel) return null;
      return r.toRideModel().midRideCancel;
    });
  }

  /// Syncs cancel-info + no-show from a `ride:status_update` payload.
  void _syncCancelAndNoShowFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
  ) {
    if (payload.cancelInfoFieldPresent) {
      c.cancelInfo.value = payload.cancelInfo;
      final current = c.ride.value;
      if (current != null) {
        c.ride.value = current.copyWith(
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

  /// Syncs cancel-info + no-show from HTTP ride details.
  void _syncCancelAndNoShowFromRideModel(RideModel r) {
    if (r.cancelInfo != null) {
      c.cancelInfo.value = r.cancelInfo;
    }
    if (r.noShow != null) {
      // Prefer banner copy already armed from active/status payload.
      _armNoShowInfo(r.noShow!.mergingDisplayFrom(c.noShowInfo.value));
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

  /// Applies route deviation (or cancel-only shell) from ride details.
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

  /// Deduped socket handler for live route-deviation events.
  void _applyRouteDeviationFromSocket(RideRouteDeviationSocketPayload payload) {
    final detectedIso = payload.deviation.detectedAt?.toIso8601String() ?? '';
    final dedupeKey = '${payload.rideId ?? c.rideId}|$detectedIso';
    if (detectedIso.isNotEmpty && c._lastRouteDeviationDedupeKey == dedupeKey) {
      return;
    }
    if (detectedIso.isNotEmpty) {
      c._lastRouteDeviationDedupeKey = dedupeKey;
    }
    _applyRouteDeviation(
      payload.deviation.mergingFrom(c.routeDeviationInfo.value),
    );
  }

  /// Merges and stores route deviation; re-arms banner on off/on transitions.
  void _applyRouteDeviation(RideRouteDeviationModel info) {
    final previous = c.routeDeviationInfo.value;
    final merged = info.mergingFrom(previous);
    // New off-route event after a dismissed on-route banner should re-show.
    if (merged.isOffRoute && previous?.isOnRoute == true) {
      c.routeDeviationBannerDismissed.value = false;
    }
    if (merged.isOnRoute && previous?.isOffRoute == true) {
      c.routeDeviationBannerDismissed.value = false;
    }
    c.routeDeviationInfo.value = merged;
    _clearRequestToCancelIfSameTicket(merged.cancellationRequest);
    final current = c.ride.value;
    if (current != null) {
      c.ride.value = current.copyWith(routeDeviation: merged);
    }
  }

  /// Stores standalone Request-to-cancel and clears matching deviation ticket.
  void _applyRequestToCancelInfo(RideCancellationRequestModel request) {
    c.requestToCancelInfo.value = request;
    _clearDeviationCancellationIfSameTicket(request);
    // One pending request per ride — block deviation "Request to cancel".
    final deviation = c.routeDeviationInfo.value;
    if (deviation != null && request.isPending) {
      c.routeDeviationInfo.value = deviation.copyWith(
        canRequestCancellation: false,
      );
    }
  }

  /// Clears standalone Request-to-cancel when the same ticket moves to deviation.
  void _clearRequestToCancelIfSameTicket(
    RideCancellationRequestModel? request,
  ) {
    if (request == null) return;
    final existing = c.requestToCancelInfo.value;
    if (existing == null) return;
    if (_sameCancellationTicket(existing, request)) {
      c.requestToCancelInfo.value = null;
    }
  }

  /// Clears deviation cancel request when the same ticket is standalone.
  void _clearDeviationCancellationIfSameTicket(
    RideCancellationRequestModel request,
  ) {
    final deviation = c.routeDeviationInfo.value;
    final existing = deviation?.cancellationRequest;
    if (deviation == null || existing == null) return;
    if (!_sameCancellationTicket(existing, request)) return;
    c.routeDeviationInfo.value = deviation.copyWith(
      clearCancellationRequest: true,
      canRequestCancellation: request.isWithdrawn || request.isRejected,
    );
  }

  /// Matches cancel tickets by id, else by ticket number.
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

  /// Applies socket cancel-request status updates to either cancel lane.
  void _applyCancellationRequestUpdate(
    RideCancellationRequestUpdatePayload payload,
  ) {
    final updatedRequest = RideCancellationRequestModel(
      ticketId: payload.ticketId,
      ticketNumber: payload.ticketNumber,
      status: payload.status,
      note: payload.note,
    );

    final standalone = c.requestToCancelInfo.value;
    if (standalone != null &&
        (payload.ticketId.isEmpty ||
            _sameCancellationTicket(standalone, updatedRequest))) {
      c.requestToCancelInfo.value = RideCancellationRequestModel(
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
      final deviation = c.routeDeviationInfo.value;
      if (deviation != null &&
          (updatedRequest.isRejected || updatedRequest.isWithdrawn)) {
        c.routeDeviationInfo.value = deviation.copyWith(
          canRequestCancellation: true,
        );
      }
      return;
    }

    final current = c.routeDeviationInfo.value;
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

  /// Hides the deviation banner until a new off/on-route transition.
  void dismissRouteDeviationBanner() {
    c.routeDeviationBannerDismissed.value = true;
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
    final request = c.requestToCancelInfo.value ??
        c.routeDeviationInfo.value?.cancellationRequest;
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

  /// Runs [RequestCancellationFlow] and stores the resulting ticket.
  Future<void> _openCancellationRequestSheet({
    required bool forDeviation,
  }) async {
    if (forDeviation && !canRequestCancellationFromDeviation) return;
    final hasPendingRequestToCancel =
        c.requestToCancelInfo.value?.isPending ?? false;
    final hasPendingDeviation =
        c.routeDeviationInfo.value?.cancellationRequest?.isPending ?? false;
    if (!forDeviation &&
        (hasPendingRequestToCancel || hasPendingDeviation)) {
      _showExistingRequestToCancelStatus();
      return;
    }

    final data = await RequestCancellationFlow(
      rideRepository: c.rideRepository,
      rideId: c.rideId,
    ).run();
    if (data == null) return;

    final request = RideCancellationRequestModel(
      ticketId: data.ticketId,
      ticketNumber: data.ticketNumber,
      status: data.status.isNotEmpty ? data.status : 'pending',
      requestedAt: DateTime.now().toUtc(),
    );

    if (forDeviation) {
      final current = c.routeDeviationInfo.value;
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

  /// Withdraws a pending deviation-scoped cancellation request.
  Future<void> withdrawDeviationCancellationRequest() {
    return _withdrawCancellationRequest(fromDeviation: true);
  }

  /// Withdraws a pending standalone Request-to-cancel.
  Future<void> withdrawRequestToCancel() {
    return _withdrawCancellationRequest(fromDeviation: false);
  }

  /// Calls withdraw API and updates the matching cancel-request lane.
  Future<void> _withdrawCancellationRequest({
    required bool fromDeviation,
  }) async {
    final ticketId = fromDeviation
        ? (c.routeDeviationInfo.value?.cancellationRequest?.ticketId.trim() ?? '')
        : (c.requestToCancelInfo.value?.ticketId.trim() ?? '');
    if (ticketId.isEmpty) return;

    Failure? failure;
    await Loader.run(() async {
      final result = await c.rideRepository.withdrawCancellationRequest(ticketId);
      result.fold((f) => failure = f, (_) {});
    });

    if (failure is CancellationRequestAlreadyDecidedFailure) {
      AppDialogs.showErrorDialog(
        title: AppStrings.submitFailed.tr,
        message: failure!.message.isNotEmpty
            ? failure!.message
            : AppStrings.cancellationRequestAlreadyDecided.tr,
      );
      await c._fetchRideDetails();
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
      final current = c.routeDeviationInfo.value;
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

    final prior = c.requestToCancelInfo.value;
    c.requestToCancelInfo.value = prior?.copyWith(status: 'withdrawn');
    final deviation = c.routeDeviationInfo.value;
    if (deviation != null) {
      c.routeDeviationInfo.value = deviation.copyWith(
        canRequestCancellation: true,
      );
    }
  }

  /// Arms no-show banner + countdown from [fireAt] (idempotent per fire time).
  void _armNoShowInfo(RideNoShowInfoModel info) {
    // Keep title/subtitle from active/socket when a later details refresh
    // only sends fire_at / fee without banner copy.
    final merged = info.mergingDisplayFrom(c.noShowInfo.value);
    c.noShowInfo.value = merged;
    c.isNoShowExpiring.value = false;
    final fireIso = merged.fireAt.toIso8601String();
    if (c._armedNoShowFireAtIso == fireIso && c._noShowCountdown != null) {
      c.noShowCountdownLabel.value = merged.formatRemainingMmSs();
      final current = c.ride.value;
      if (current != null) {
        c.ride.value = current.copyWith(noShow: merged);
      }
      return;
    }
    c._armedNoShowFireAtIso = fireIso;
    c.noShowCountdownLabel.value = merged.formatRemainingMmSs();
    c._noShowCountdown?.stop();
    c._noShowCountdown = PaymentCountdownTimer(
      onTick: (remainingSeconds) {
        final mins = remainingSeconds ~/ 60;
        final secs = remainingSeconds % 60;
        c.noShowCountdownLabel.value =
            '${mins.toString().padLeft(2, '0')}:'
            '${secs.toString().padLeft(2, '0')}';
      },
      onExpired: () {
        // Display-only — server cancels; show brief waiting state.
        c.noShowCountdownLabel.value = '00:00';
        c.isNoShowExpiring.value = true;
      },
    )..startUntil(merged.fireAt);

    final current = c.ride.value;
    if (current != null) {
      c.ride.value = current.copyWith(noShow: merged);
    }
  }

  /// Clears no-show banner state and stops the countdown timer.
  void _clearNoShowInfo() {
    _stopNoShowCountdown(clearInfo: true);
  }

  /// Stops the no-show timer; optionally clears banner Rx fields.
  void _stopNoShowCountdown({bool clearInfo = false}) {
    c._noShowCountdown?.stop();
    c._noShowCountdown = null;
    c._armedNoShowFireAtIso = null;
    c.isNoShowExpiring.value = false;
    if (clearInfo) {
      c.noShowInfo.value = null;
      c.noShowCountdownLabel.value = '00:00';
      final current = c.ride.value;
      if (current != null && current.noShow != null) {
        c.ride.value = current.copyWith(clearNoShow: true);
      }
    }
  }

  /// Rider cancel from driver-details sheet via shared [CancelRideFlow].
  Future<void> confirmCancelRide() {
    // Driver-details bottom sheet — shared [CancelRideFlow] (canonical implementation).
    return CancelRideFlow(
      rideRepository: c.rideRepository,
      rideId: c.rideId,
      cancelInfo: c.cancelInfo.value,
      onCancelApiStarted: () {
        c._isUserInitiatedCancellation = true;
        c._navigatedAway = true;
      },
      onCancelApiFailed: () {
        c._isUserInitiatedCancellation = false;
        c._navigatedAway = false;
      },
      onRideAlreadyFinalized: () {
        // Race with server no-show finalize — stay on screen and await socket.
        c._isUserInitiatedCancellation = false;
        c._navigatedAway = false;
        c.isNoShowExpiring.value = true;
        unawaited(c._fetchRideDetails());
      },
    ).run();
  }
}
