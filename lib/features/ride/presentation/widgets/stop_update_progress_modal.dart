import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/driver_accepted_controller.dart';

class StopUpdateProgressModal extends GetView<DriverAcceptedController> {
  const StopUpdateProgressModal({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 24.h,
        bottom: 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final step = controller.stopUpdateProgressStep.value;
          final destFlow = controller.isDestinationUpdateFlow.value;

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
                _getTitle(step, destFlow),
                style: AppTextStyles.onboardingTitle.copyWith(fontSize: 20.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              SizedBox(height: 12.h),
              Text(
                _getMessage(step, destFlow),
                style: AppTextStyles.onboardingSubtitle.copyWith(fontSize: 14.sp),
                textAlign: TextAlign.center,
              ),
              if (step == 1 || step == 2) ...[
                SizedBox(height: 24.h),
                TextButton(
                  onPressed: () => controller.cancelRouteOrStopsUpdate(),
                  child: Text(
                    AppStrings.cancelUpdate.tr,
                    style: AppTextStyles.onboardingSubtitle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              SizedBox(height: bottomPadding > 0 ? 12.h : 24.h),
            ],
          );
        }),
      ),
    );
  }

  String _getTitle(int step, bool destinationFlow) {
    switch (step) {
      case 1:
        return AppStrings.updatingPayment.tr;
      case 2:
        return AppStrings.recalculatingRoute.tr;
      case 3:
        return destinationFlow
            ? AppStrings.dropOffUpdated.tr
            : AppStrings.routeUpdated.tr;
      default:
        return AppStrings.processing.tr;
    }
  }

  String _getMessage(int step, bool destinationFlow) {
    switch (step) {
      case 1:
        return AppStrings.adjustingPaymentHoldForNewRoute.tr;
      case 2:
        return AppStrings.syncingNewRouteWithDriver.tr;
      case 3:
        return destinationFlow
            ? AppStrings.driverReceivedNewDropOffLocation.tr
            : AppStrings.driverReceivedNewStops.tr;
      default:
        return AppStrings.pleaseWaitWhileWeProcessYourRequest.tr;
    }
  }
}
