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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
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
          SizedBox(height: 17.h),

          Text(
            AppStrings.verifyYourSelfie.tr,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
              height: 34 / 20,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 17.h),
          const Divider(color: AppColors.divider, thickness: 1),
          SizedBox(height: 42.h),

          // Face Scan Illustration
          Center(
            child: SvgPictureAsset(
              AppAssets.icFaceScan,
              height: 252.h,
              width: 202.13.w,
            ),
          ),
          SizedBox(height: 54.h),

          // Description
          Text(
            AppStrings
                .yourSelfieWillBeCapturedToHelpUsValidateYouAgainstYourIdPleaseHoldYour
                .tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textBody,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              height: 20 / 15,
            ),
          ),
          SizedBox(height: 32.h),

          // Take Selfie Button
          AppPrimaryButton(
            label: AppStrings.takeSelfie.tr,
            onPressed: controller.takeSelfie,
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
