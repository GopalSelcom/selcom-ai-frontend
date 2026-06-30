import 'dart:async';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/models/mid_ride_cancel_model.dart';
import '../../../../core/domain/entities/mid_ride_cancel_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../wallet/presentation/utils/wallet_refresh.dart';
import '../../data/models/mid_ride_cancel_models.dart';
import '../../domain/repositories/ride_repository.dart';
import '../utils/mid_ride_cancel_copy.dart';

enum MidRideDialogStatusKind {
  scheduled,
  finalising,
  captured,
  underReview,
  noCharge,
}

class MidRideDriverCancelledController extends GetxController {
  MidRideDriverCancelledController({
    required this.rideRepository,
    required this.rideId,
    required MidRideCancelModel initialCancel,
  }) {
    midRideCancel.value = initialCancel;
  }

  final RideRepository rideRepository;
  final String rideId;
  final AppSocketService _socketService = AppSocketService();

  final midRideCancel = Rxn<MidRideCancelModel>();
  final now = DateTime.now().toUtc().obs;
  final isDisputing = false.obs;
  final disputeSubmitted = false.obs;

  StreamSubscription<RideChargeSettledPayload>? _chargeSettledSub;
  StreamSubscription<RideChargeDisputedPayload>? _chargeDisputedSub;
  Timer? _clockTimer;

  @override
  void onInit() {
    super.onInit();
    _startClock();
    _subscribeToChargeEvents();
    unawaited(_refreshFromRideDetails());
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now().toUtc();
    });
  }

  void _subscribeToChargeEvents() {
    _chargeSettledSub = _socketService.rideChargeSettledStream.listen((payload) {
      if (payload.rideId.trim() != rideId) return;
      _applyChargeSettled(payload);
    });
    _chargeDisputedSub = _socketService.rideChargeDisputedStream.listen((
      payload,
    ) {
      if (payload.rideId.trim() != rideId) return;
      _applyChargeDisputed(payload);
    });
  }

  Future<void> _refreshFromRideDetails() async {
    if (rideId.isEmpty) return;
    final result = await rideRepository.getRideDetails(rideId);
    result.fold((_) {}, (ride) {
      final block = ride.midRideCancel;
      if (block is MidRideCancelModel) {
        midRideCancel.value = block;
      } else if (block != null) {
        midRideCancel.value = MidRideCancelModel(
          reason: block.reason,
          reasonText: block.reasonText,
          distanceCoveredKm: block.distanceCoveredKm,
          partialFare: block.partialFare,
          capturedAmount: block.capturedAmount,
          netRefund: block.netRefund,
          releasedAmount: block.releasedAmount,
          captureAt: block.captureAt,
          disputeDeadline: block.disputeDeadline,
          canDispute: block.canDispute,
          captureStatus: block.captureStatus,
        );
      }
    });
  }

  void _applyChargeSettled(RideChargeSettledPayload payload) {
    final current = midRideCancel.value;
    if (current == null) return;
    midRideCancel.value = current.merge(
      capturedAmount: payload.capturedAmount,
      netRefund: payload.netRefund,
      captureStatus: MidRideCaptureStatus.captured,
      canDispute: false,
    );
    unawaited(WalletRefresh.afterBalanceChange());
  }

  void _applyChargeDisputed(RideChargeDisputedPayload payload) {
    final current = midRideCancel.value;
    if (current == null) return;
    disputeSubmitted.value = true;
    midRideCancel.value = current.merge(
      releasedAmount: payload.releasedAmount,
      captureStatus: MidRideCaptureStatus.disputed,
      canDispute: false,
    );
    unawaited(WalletRefresh.afterBalanceChange());
  }

  String get reasonLabel => midRideCancelReasonLabel(
    reason: midRideCancel.value?.reason,
    reasonText: midRideCancel.value?.reasonText,
  );

  String get partialFareLabel =>
      CurrencyFormatter.format(midRideCancel.value?.partialFare ?? 0);

  String get distanceLabel =>
      (midRideCancel.value?.distanceCoveredKm ?? 0).toStringAsFixed(1);

  String? get captureTimeLabel {
    final captureAt = midRideCancel.value?.captureAt;
    if (captureAt == null) return null;
    return DateFormat('HH:mm').format(captureAt.toLocal());
  }

  String get capturedAmountLabel =>
      CurrencyFormatter.format(midRideCancel.value?.capturedAmount ?? 0);

  String get refundAmountLabel =>
      CurrencyFormatter.format(midRideCancel.value?.netRefund ?? 0);

  MidRideDialogStatusKind? get statusKind {
    final block = midRideCancel.value;
    if (block == null) return null;

    if (disputeSubmitted.value ||
        block.captureStatus == MidRideCaptureStatus.disputed) {
      return MidRideDialogStatusKind.underReview;
    }

    switch (block.captureStatus) {
      case MidRideCaptureStatus.captured:
        return MidRideDialogStatusKind.captured;
      case MidRideCaptureStatus.released:
      case MidRideCaptureStatus.waived:
        return MidRideDialogStatusKind.noCharge;
      case MidRideCaptureStatus.scheduled:
      case null:
        final captureAt = block.captureAt;
        if (captureAt != null &&
            (now.value.isAfter(captureAt) ||
                now.value.isAtSameMomentAs(captureAt))) {
          return MidRideDialogStatusKind.finalising;
        }
        return MidRideDialogStatusKind.scheduled;
      case MidRideCaptureStatus.disputed:
        return MidRideDialogStatusKind.underReview;
    }
  }

  bool get showDisputeButton {
    final block = midRideCancel.value;
    if (block == null || disputeSubmitted.value || isDisputing.value) {
      return false;
    }
    if (block.captureStatus == MidRideCaptureStatus.captured ||
        block.captureStatus == MidRideCaptureStatus.released ||
        block.captureStatus == MidRideCaptureStatus.waived ||
        block.captureStatus == MidRideCaptureStatus.disputed) {
      return false;
    }
    return block.canDispute;
  }

  Future<void> disputeCharge() async {
    if (rideId.isEmpty || isDisputing.value) return;
    isDisputing.value = true;
    await Loader.run(() async {
      final result = await rideRepository.disputeCharge(rideId);
      result.fold(
        (failure) {
          if (failure.message.contains('dispute_window_closed')) {
            AppDialogs.showErrorDialog(
              title: AppStrings.midRideDisputeUnavailable.tr,
              message: AppStrings.midRideDisputeWindowClosed.tr,
              onConfirm: () => Get.toNamed(AppRoutes.contactUs),
            );
            return;
          }
          AppDialogs.showErrorDialog(
            title: AppStrings.midRideDisputeFailed.tr,
            message: AppStrings.pleaseTryAgain.tr,
          );
        },
        (data) async {
          disputeSubmitted.value = true;
          final current = midRideCancel.value;
          if (current != null) {
            midRideCancel.value = current.merge(
              releasedAmount: data.releasedAmount,
              captureStatus: MidRideCaptureStatus.disputed,
              canDispute: false,
            );
          }
          await WalletRefresh.afterBalanceChange();
          AppDialogs.showSuccessDialog(
            message: AppStrings.midRideDisputeSuccess.tr,
          );
        },
      );
    });
    isDisputing.value = false;
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _chargeSettledSub?.cancel();
    _chargeDisputedSub?.cancel();
    super.onClose();
  }
}
