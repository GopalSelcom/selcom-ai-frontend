import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';

class WalletFingerScanInstructionSheet extends StatelessWidget {
  const WalletFingerScanInstructionSheet({
    super.key,
    required this.onContinue,
  });

  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.borderDefault,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  AppStrings.walletLinkHowToScanFingers.tr,
                  style: AppTextStyles.sectionTitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _scanExample(
                      AppAssets.walletLinkFingerScanCorrect,
                      AppStrings.walletLinkFingerScanCorrect.tr,
                      AppColors.secondary,
                    ),
                    _scanExample(
                      AppAssets.walletLinkFingerScanWrong,
                      AppStrings.walletLinkFingerScanWrong.tr,
                      AppColors.textError,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                AppPrimaryButton(
                  label: AppStrings.continueLabel.tr,
                  width: double.infinity,
                  height: 48.h,
                  onPressed: () async {
                    Get.back();
                    await onContinue();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scanExample(String asset, String label, Color labelColor) {
    return Column(
      children: [
        Image.asset(
          asset,
          height: 120.h,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
