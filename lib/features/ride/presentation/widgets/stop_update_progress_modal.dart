import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/driver_accepted_controller.dart';

class StopUpdateProgressModal extends GetView<DriverAcceptedController> {
  const StopUpdateProgressModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Obx(() {
        final step = controller.stopUpdateProgressStep.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (step < 3) ...[
              const CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 24.h),
            ] else ...[
              Icon(Icons.check_circle, color: AppColors.success, size: 64.sp),
              SizedBox(height: 16.h),
            ],
            Text(
              _getTitle(step),
              style: AppTextStyles.onboardingTitle.copyWith(fontSize: 20.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            SizedBox(height: 12.h),
            Text(
              _getMessage(step),
              style: AppTextStyles.onboardingSubtitle.copyWith(fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            if (step == 1 || step == 2) ...[
              SizedBox(height: 24.h),
              TextButton(
                onPressed: () => controller.cancelStopUpdate(),
                child: Text(
                  'Cancel Update',
                  style: AppTextStyles.onboardingSubtitle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        );
      }),
    );
  }

  String _getTitle(int step) {
    switch (step) {
      case 1:
        return 'Updating Payment';
      case 2:
        return 'Recalculating Route';
      case 3:
        return 'Route Updated!';
      default:
        return 'Processing...';
    }
  }

  String _getMessage(int step) {
    switch (step) {
      case 1:
        return 'We\'re adjusting your payment hold for the new route.';
      case 2:
        return 'Syncing the new destination with your driver.';
      case 3:
        return 'Your driver has received the new stops.';
      default:
        return 'Please wait while we process your request.';
    }
  }
}
