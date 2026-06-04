import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/wallet_biometric_intro_controller.dart';

/// Fingerprint intro — parity with selcom_auth [BiometricIntroductionScreen].
class WalletBiometricIntroScreen extends GetView<WalletBiometricIntroController> {
  const WalletBiometricIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
              child: Row(
                children: [
                  AppBackButton(
                    color: AppColors.textHeading,
                    size: 22.w,
                    onPressed: Get.back,
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.walletLinkBiometricAuth.tr,
                      style: AppTextStyles.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Lottie.asset(
                    AppAssets.walletLinkBiometricScanLottie,
                    height: 0.28.sh,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      children: [
                        Text(
                          AppStrings.walletLinkBiometricIntroTitle.tr,
                          style: AppTextStyles.onboardingTitle.copyWith(
                            fontSize: 22.sp,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20.h),
                        _instruction(
                          AppStrings.walletLinkBiometricInstruction1.tr,
                        ),
                        SizedBox(height: 10.h),
                        _instruction(
                          AppStrings.walletLinkBiometricInstruction2.tr,
                        ),
                        SizedBox(height: 10.h),
                        _instruction(
                          AppStrings.walletLinkBiometricInstruction3.tr,
                        ),
                        SizedBox(height: 10.h),
                        _instruction(
                          AppStrings.walletLinkBiometricInstruction4.tr,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                    child: AppPrimaryButton(
                      label: AppStrings.proceed.tr,
                      width: double.infinity,
                      height: 52.h,
                      onPressed: controller.openHandSelection,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instruction(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.bodySecondary.copyWith(height: 1.3),
      ),
    );
  }
}
