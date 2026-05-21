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

class SelcomPesaLinkedBottomSheet extends GetView<PaymentMethodsController> {
  const SelcomPesaLinkedBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS
            ? (bottomPadding - 12.h).clamp(
                10.h > bottomPadding ? bottomPadding : 10.h,
                bottomPadding,
              )
            : bottomPadding + 12.h)
        : 12.h;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 20.h,
        bottom: 0,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
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
            AppStrings.yourLinkedAccount.tr,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColors.divider, thickness: 1),
          SizedBox(height: 24.h),

          _buildReadOnlyField(label: AppStrings.fullName.tr, value: 'Chirag panchal'),
          SizedBox(height: 20.h),

          _buildReadOnlyField(
            label: AppStrings.phoneNumber.tr,
            value: '+255 711 410 410',
          ),
          SizedBox(height: 24.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPictureAsset(
                AppAssets.icAccountVerified,
                width: 24.w,
                height: 24.w,
              ),
              SizedBox(width: 12.w),
              Text(
                AppStrings.accountVerified.tr,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textVerified,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 48.h),

          // Remove Account Button
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: AppStrings.removeAccount.tr,
              onPressed: controller.unlinkAccount,
              height: 56.h,
              borderRadius: 16.r,
              outlined: true,
              backgroundColor: AppColors.white,
              textColor: AppColors.primary,
              outlinedTextColor: AppColors.primary,
              outlinedBorderColor: AppColors.primary,
              outlinedBorderWidth: 1,
            ),
          ),
          SizedBox(height: computedBottomPadding),
        ],
      ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textBody,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.borderWalletCard),
          ),
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
        ),
      ],
    );
  }
}
