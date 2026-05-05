import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/payment_methods_controller.dart';

class SelcomPesaSelfieBottomSheet extends GetView<PaymentMethodsController> {
  const SelcomPesaSelfieBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 64.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.dividerHandle,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          Text(
            AppStrings.verifyYourSelfie.tr,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColors.divider, thickness: 1),
          SizedBox(height: 32.h),

          // Face Scan Illustration
          Center(
            child: SvgPictureAsset(
              AppAssets.icFaceScan,
              height: 200.h,
              width: 200.w,
            ),
          ),
          SizedBox(height: 32.h),

          // Description
          Text(
            AppStrings
                .yourSelfieWillBeCapturedToHelpUsValidateYouAgainstYourIdPleaseHoldYour
                .tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textBody,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),

          // Take Selfie Button
          AppPrimaryButton(
            label: 'Take Selfie',
            onPressed: controller.takeSelfie,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
