import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';

class PaymentCardActionBottomSheet extends StatelessWidget {
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

  static Future<void> show({
    required String title,
    required String description,
    required String cardNumber,
    required String imageAssetPath,
    required String primaryButtonLabel,
    required VoidCallback? onPrimaryPressed,
    bool isPrimaryLoading = false,
    String? secondaryButtonLabel,
    VoidCallback? onSecondaryPressed,
    bool isSecondaryLoading = false,
    String? iconAsset,
    bool isSecondaryDanger = false,
    bool barrierDismissible = true,
  }) {
    return AppDialogs.showStandardBottomSheet<void>(
      barrierDismissible: barrierDismissible,
      showHeaderDivider: false,
      sheet: PaymentCardActionBottomSheet(
        title: title,
        description: description,
        cardNumber: cardNumber,
        imageAssetPath: imageAssetPath,
        primaryButtonLabel: primaryButtonLabel,
        onPrimaryPressed: onPrimaryPressed,
        isPrimaryLoading: isPrimaryLoading,
        secondaryButtonLabel: secondaryButtonLabel,
        onSecondaryPressed: onSecondaryPressed,
        isSecondaryLoading: isSecondaryLoading,
        iconAsset: iconAsset,
        isSecondaryDanger: isSecondaryDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppStandardBottomSheet(
      showHeaderDivider: false,
      contentPadding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
      footer: secondaryButtonLabel == null
          ? AppPrimaryButton(
              label: primaryButtonLabel,
              iconAsset: iconAsset ?? AppAssets.locationIcArrowRight,
              isLoading: isPrimaryLoading,
              onPressed: onPrimaryPressed,
            )
          : Row(
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
                    textColor: isSecondaryDanger
                        ? AppColors.error
                        : AppColors.primaryButton,
                    outlinedTextColor: isSecondaryDanger
                        ? AppColors.error
                        : AppColors.primaryButton,
                    outlinedBorderColor: isSecondaryDanger
                        ? AppColors.error
                        : AppColors.primaryButton,
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
    );
  }
}
