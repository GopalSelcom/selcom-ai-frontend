import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class PaymentCardActionBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final String cardNumber;
  final String imageAssetPath;
  final String primaryButtonLabel;
  final VoidCallback? onPrimaryPressed;
  final bool isPrimaryLoading;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;
  final bool isSecondaryLoading;
  final String? iconAsset;

  final bool isSecondaryDanger;

  const PaymentCardActionBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.cardNumber,
    required this.imageAssetPath,
    required this.primaryButtonLabel,
    required this.onPrimaryPressed,
    this.isPrimaryLoading = false,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.isSecondaryLoading = false,
    this.iconAsset,
    this.isSecondaryDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS ? 0.0 : 8.h)
        : 16.h;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.only(
        left: 24.w,
        right: 24.w,
        top: 16.h,
        bottom: 0,
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 64.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: AppColors.dividerHandle,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textHeading,
                      fontSize: 20.h,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                SizedBox(
                  width: 86.w,
                  height: 86.w,
                  child: Image.asset(imageAssetPath, fit: BoxFit.contain),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: AppStrings.visa.tr,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.textBrandVisaPrimary,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      fontSize: 16.sp,
                    ),
                  ),
                  TextSpan(
                    text: ' $cardNumber',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHeading,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textBody,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            SizedBox(height: 28.h),
            if (secondaryButtonLabel == null) ...[
              AppPrimaryButton(
                label: primaryButtonLabel,
                iconAsset: AppAssets.locationIcArrowRight,
                isLoading: isPrimaryLoading,
                onPressed: onPrimaryPressed,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: secondaryButtonLabel!,
                      onPressed: isSecondaryLoading ? null : onSecondaryPressed,
                      isLoading: isSecondaryLoading,
                      height: 56.h,
                      borderRadius: 16.r,
                      outlined: true,
                      backgroundColor: AppColors.white,
                      textColor: isSecondaryDanger ? AppColors.error : AppColors.primary,
                      outlinedTextColor: isSecondaryDanger ? AppColors.error : AppColors.primary,
                      outlinedBorderColor: isSecondaryDanger ? AppColors.error : AppColors.primary,
                      outlinedBorderWidth: 1,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppPrimaryButton(
                      label: primaryButtonLabel,
                      isLoading: isPrimaryLoading,
                      onPressed: onPrimaryPressed,
                      iconAsset: iconAsset,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: computedBottomPadding),
          ],
        ),
      ),
    );
  }
}
