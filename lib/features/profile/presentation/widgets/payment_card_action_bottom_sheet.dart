import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 28.h),
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
                  text: 'VISA',
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
              iconAsset: AppAssets.icArrowRight,
              isLoading: isPrimaryLoading,
              onPressed: onPrimaryPressed,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56.h,
                    child: OutlinedButton(
                      onPressed: isSecondaryLoading ? null : onSecondaryPressed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: isSecondaryLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              secondaryButtonLabel!,
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                    ),
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
        ],
      ),
    );
  }
}
