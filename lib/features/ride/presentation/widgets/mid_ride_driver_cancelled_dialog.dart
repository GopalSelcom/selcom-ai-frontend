import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_cancel_flow_dialog.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/mid_ride_driver_cancelled_controller.dart';

/// Mid-ride driver cancellation modal — themed like cancel-ride charge dialogs.
class MidRideDriverCancelledDialog extends StatelessWidget {
  const MidRideDriverCancelledDialog({
    super.key,
    required this.controllerTag,
    required this.navigateHomeOnDismiss,
  });

  final String controllerTag;
  final bool navigateHomeOnDismiss;

  MidRideDriverCancelledController get _controller =>
      Get.find<MidRideDriverCancelledController>(tag: controllerTag);

  TextStyle get _bodyStyle => AppTextStyles.homeSubtitle.copyWith(
    color: AppColors.textSlate,
    fontWeight: FontWeight.w500,
    height: 1.45,
    fontSize: 15.sp,
  );

  TextStyle get _amountPrimaryStyle => AppTextStyles.price.copyWith(
    fontSize: 15.sp,
    height: 1.45,
    color: AppColors.textHeading,
    fontWeight: FontWeight.w700,
  );

  TextStyle get _amountSuccessStyle => AppTextStyles.price.copyWith(
    fontSize: 15.sp,
    height: 1.45,
    color: AppColors.success,
    fontWeight: FontWeight.w700,
  );

  TextStyle get _reasonHighlightStyle => AppTextStyles.homeSubtitle.copyWith(
    color: AppColors.textHeading,
    fontWeight: FontWeight.w700,
    height: 1.45,
    fontSize: 15.sp,
  );

  Future<void> _onDismiss() async {
    Get.back<void>();
    if (navigateHomeOnDismiss) {
      await AppDialogs.navigateHomeReplacingStack();
    }
  }

  Widget _buildReasonLine(MidRideDriverCancelledController c) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: _bodyStyle,
        children: [
          TextSpan(text: AppStrings.midRideReasonLead.tr),
          TextSpan(text: c.reasonLabel, style: _reasonHighlightStyle),
        ],
      ),
    );
  }

  Widget _buildChargeSummary(MidRideDriverCancelledController c) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: _bodyStyle,
        children: [
          TextSpan(text: AppStrings.midRideChargeSummaryLead.tr),
          TextSpan(text: c.partialFareLabel, style: _amountPrimaryStyle),
          TextSpan(text: AppStrings.midRideChargeSummaryFor.tr),
          TextSpan(text: c.distanceLabel, style: _amountPrimaryStyle),
          TextSpan(text: AppStrings.midRideChargeSummaryTrail.tr),
        ],
      ),
    );
  }

  Widget? _buildStatusLine(MidRideDriverCancelledController c) {
    switch (c.statusKind) {
      case MidRideDialogStatusKind.scheduled:
        final time = c.captureTimeLabel;
        if (time == null) return null;
        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: _bodyStyle,
            children: [
              TextSpan(text: AppStrings.midRideChargeScheduledLead.tr),
              TextSpan(text: time, style: _amountPrimaryStyle),
              TextSpan(text: AppStrings.midRideChargeScheduledTrail.tr),
            ],
          ),
        );
      case MidRideDialogStatusKind.finalising:
        return Text(
          AppStrings.midRideChargeFinalising.tr,
          textAlign: TextAlign.center,
          style: _bodyStyle.copyWith(fontStyle: FontStyle.italic),
        );
      case MidRideDialogStatusKind.captured:
        return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: _bodyStyle,
            children: [
              TextSpan(text: AppStrings.midRideChargeCapturedLead.tr),
              TextSpan(text: c.capturedAmountLabel, style: _amountPrimaryStyle),
              TextSpan(text: AppStrings.midRideChargeCapturedMiddle.tr),
              TextSpan(text: c.refundAmountLabel, style: _amountSuccessStyle),
              TextSpan(text: AppStrings.midRideChargeCapturedRefundTrail.tr),
            ],
          ),
        );
      case MidRideDialogStatusKind.underReview:
        return Text(
          AppStrings.midRideUnderReview.tr,
          textAlign: TextAlign.center,
          style: _bodyStyle.copyWith(color: AppColors.info),
        );
      case MidRideDialogStatusKind.noCharge:
        return Text(
          AppStrings.midRideNoCharge.tr,
          textAlign: TextAlign.center,
          style: _bodyStyle.copyWith(color: AppColors.success),
        );
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Obx(() {
      c.midRideCancel.value;
      c.disputeSubmitted.value;
      c.isDisputing.value;
      c.now.value;

      final statusLine = _buildStatusLine(c);

      return AppCancelFlowDialog(
        canPop: false,
        title: AppStrings.tripEndedByDriver.tr,
        subtitle: AppStrings.midRideSorrySubtitle.tr,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReasonLine(c),
            SizedBox(height: 16.h),
            _buildChargeSummary(c),
            if (statusLine != null) ...[
              SizedBox(height: 16.h),
              Divider(height: 1.h, color: AppColors.bgSoftCircle),
              SizedBox(height: 16.h),
              statusLine,
            ],
            SizedBox(height: 20.h),
            if (c.showDisputeButton) ...[
              AppPrimaryButton(
                label: AppStrings.midRideDisputeCharge.tr,
                isLoading: c.isDisputing.value,
                onPressed: c.disputeCharge,
                outlined: true,
                outlinedBorderColor: AppColors.textNeutralButton,
                outlinedTextColor: AppColors.textNeutralButton,
                height: 50.h,
                borderRadius: 12.r,
              ),
              SizedBox(height: 10.h),
            ],
            AppPrimaryButton(
              label: navigateHomeOnDismiss
                  ? AppStrings.backToHome.tr
                  : AppStrings.done.tr,
              onPressed: _onDismiss,
              height: 50.h,
              borderRadius: 12.r,
            ),
          ],
        ),
      );
    });
  }
}
