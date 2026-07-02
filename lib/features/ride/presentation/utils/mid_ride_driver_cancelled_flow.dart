import 'package:get/get.dart';

import '../../../../core/data/models/mid_ride_cancel_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/domain/entities/mid_ride_cancel_entity.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/mid_ride_driver_cancelled_controller.dart';
import '../widgets/mid_ride_driver_cancelled_dialog.dart';

/// Shows the mid-ride driver cancellation modal (charge summary + dispute).
abstract final class MidRideDriverCancelledFlow {
  MidRideDriverCancelledFlow._();

  static Future<void> show({
    required String rideId,
    required MidRideCancelEntity cancel,
    bool navigateHomeOnDismiss = true,
  }) async {
    final id = rideId.trim();
    if (id.isEmpty) return;

    final model = _toModel(cancel);
    final tag =
        'mid_ride_cancel_${id}_${DateTime.now().microsecondsSinceEpoch}';

    await LiveActivityManager().endActivity(id);

    Get.put(
      MidRideDriverCancelledController(
        rideRepository: di.sl<RideRepository>(),
        rideId: id,
        initialCancel: model,
      ),
      tag: tag,
    );

    try {
      await AppDialogs.showAnimatedDialog<void>(
        child: MidRideDriverCancelledDialog(
          controllerTag: tag,
          navigateHomeOnDismiss: navigateHomeOnDismiss,
        ),
        barrierDismissible: false,
        barrierColor: AppColors.overlayBlack12,
      );
    } finally {
      if (Get.isRegistered<MidRideDriverCancelledController>(tag: tag)) {
        await Get.delete<MidRideDriverCancelledController>(tag: tag);
      }
    }
  }

  static MidRideCancelModel _toModel(MidRideCancelEntity cancel) {
    if (cancel is MidRideCancelModel) return cancel;
    return MidRideCancelModel(
      reason: cancel.reason,
      reasonText: cancel.reasonText,
      message: cancel.message,
      distanceCoveredKm: cancel.distanceCoveredKm,
      partialFare: cancel.partialFare,
      capturedAmount: cancel.capturedAmount,
      netRefund: cancel.netRefund,
      releasedAmount: cancel.releasedAmount,
      captureAt: cancel.captureAt,
      disputeDeadline: cancel.disputeDeadline,
      canDispute: cancel.canDispute,
      captureStatus: cancel.captureStatus,
    );
  }
}
