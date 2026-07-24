import 'package:get/get.dart';

import '../../../../core/data/models/mid_ride_cancel_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/mid_ride_driver_cancelled_controller.dart';
import '../widgets/mid_ride_driver_cancelled_dialog.dart';

/// Shows the mid-ride driver cancellation modal (charge summary).
abstract final class MidRideDriverCancelledFlow {
  MidRideDriverCancelledFlow._();

  static Future<void> show({
    required String rideId,
    required MidRideCancelModel cancel,
    bool navigateHomeOnDismiss = true,
  }) async {
    final id = rideId.trim();
    if (id.isEmpty) return;

    final tag =
        'mid_ride_cancel_${id}_${DateTime.now().microsecondsSinceEpoch}';

    await LiveActivityManager().endActivity(id);

    Get.put(
      MidRideDriverCancelledController(
        rideRepository: di.sl<RideRepository>(),
        rideId: id,
        initialCancel: cancel,
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
}
