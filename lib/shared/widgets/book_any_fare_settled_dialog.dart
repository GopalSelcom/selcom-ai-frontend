import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_primary_button.dart';

/// Book Any `ride:fare_settled` dialog — amounts styled like cancel-ride fee/refund highlights.
class BookAnyFareSettledDialog extends StatelessWidget {
  const BookAnyFareSettledDialog({
    super.key,
    required this.blockedText,
    required this.releasedText,
    required this.chargedText,
    this.vehicleName,
    this.onConfirm,
  });

  final String blockedText;
  final String releasedText;
  final String chargedText;
  final String? vehicleName;
  final VoidCallback? onConfirm;

  TextStyle get _bodyStyle => AppTextStyles.homeSubtitle.copyWith(
    color: AppColors.textSlate,
    fontWeight: FontWeight.w500,
    height: 1.45,
    fontSize: 15.sp,
  );

  TextStyle get _amountPrimaryStyle => AppTextStyles.price.copyWith(
    fontSize: 15.sp,
    height: 1.45,
    color: AppColors.primary,
    fontWeight: FontWeight.w700,
  );

  TextStyle get _amountSuccessStyle => AppTextStyles.price.copyWith(
    fontSize: 15.sp,
    height: 1.45,
    color: AppColors.success,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    final vehicle = vehicleName?.trim() ?? '';
    final middleText = vehicle.isNotEmpty
        ? AppStrings.bookAnyFareSettledMiddleWithVehicle.trParams({
            'vehicle': vehicle,
          })
        : AppStrings.bookAnyFareSettledMiddleNoVehicle.tr;

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 48.sp),
            SizedBox(height: 20.h),
            Text(
              AppStrings.bookAnyFareSettledTitle.tr,
              style: AppTextStyles.onboardingTitle.copyWith(fontSize: 20.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: _bodyStyle,
                children: [
                  TextSpan(text: AppStrings.bookAnyFareSettledBlockedLead.tr),
                  TextSpan(text: blockedText, style: _amountPrimaryStyle),
                  TextSpan(text: middleText),
                  TextSpan(text: releasedText, style: _amountSuccessStyle),
                  TextSpan(text: AppStrings.bookAnyFareSettledReleasedTrail.tr),
                  const TextSpan(text: '\n\n'),
                  TextSpan(text: AppStrings.bookAnyFareSettledFinalChargeLabel.tr),
                  TextSpan(text: chargedText, style: _amountPrimaryStyle),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            AppPrimaryButton(
              label: AppStrings.gotIt.tr,
              onPressed: onConfirm,
              height: 50.h,
              borderRadius: 12.r,
            ),
          ],
        ),
      ),
    );
  }
}
