import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/wallet_selfie_verification_controller.dart';

/// Selfie verification intro — parity with selcom_auth [LivelinessScreen].
class WalletSelfieVerificationScreen
    extends GetView<WalletSelfieVerificationController> {
  const WalletSelfieVerificationScreen({super.key});

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
                      AppStrings.verifyYourSelfie.tr,
                      style: AppTextStyles.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                AppStrings
                    .yourSelfieWillBeCapturedToHelpUsValidateYouAgainstYourIdPleaseHoldYour
                    .tr,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  AppAssets.walletLinkFaceScan,
                  height: 0.28.sh,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
              child: Obx(
                () => AppPrimaryButton(
                  label: AppStrings.takeSelfie.tr,
                  width: double.infinity,
                  height: 52.h,
                  isLoading: controller.isCapturing.value,
                  onPressed: controller.isCapturing.value
                      ? null
                      : controller.takeSelfie,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
