import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/auth_controller.dart';

class SocialLoginScreen extends GetView<AuthController> {
  const SocialLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 72.h),
              Text(
                AppStrings.welcomeToSelcomGo.tr,
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 28.sp,
                  height: 34 / 28,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.login.tr,
                style: AppTextStyles.homeSubtitle.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBody,
                  height: 20 / 15,
                ),
              ),
              const Spacer(),
              Obx(
                () => controller.errorMessage.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14.sp,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Obx(
                () => AppPrimaryButton(
                  label: AppStrings.continueWithGoogle.tr,
                  outlined: true,
                  isLoading: controller.isLoading.value,
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.signInWithGoogle,
                ),
              ),
              SizedBox(height: 12.h),
              Obx(
                () => AppPrimaryButton(
                  label: AppStrings.continueWithFacebook.tr,
                  outlined: true,
                  isLoading: controller.isLoading.value,
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.signInWithFacebook,
                ),
              ),
              if (Platform.isIOS) ...[
                SizedBox(height: 12.h),
                Obx(
                  () => AbsorbPointer(
                    absorbing: controller.isLoading.value,
                    child: Opacity(
                      opacity: controller.isLoading.value ? 0.6 : 1,
                      child: SignInWithAppleButton(
                        onPressed: controller.signInWithApple,
                        style: SignInWithAppleButtonStyle.black,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  AppStrings
                      .byContinuingYouAgreeThatYouHaveReadAndAcceptOurTAndCsAndPrivacyPolicy
                      .tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.onboardingFooter,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
