import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_cupertino_text_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_social_sign_in_button.dart';
import '../controllers/auth_controller.dart';

class SocialLoginScreen extends GetView<AuthController> {
  const SocialLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: SvgPictureAsset(AppAssets.splashScreenBg, fit: BoxFit.cover),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 24.h,
                      ),
                      child: _SocialLoginCard(controller: controller),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLoginCard extends StatelessWidget {
  const _SocialLoginCard({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(13.97.w, 26.71.h, 13.97.w, 26.71.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(27.13.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPictureAsset(
            AppAssets.selcomGoLogoPrimaryColor,
            height: 58.h,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 26.71.h),
          Text(
            AppStrings.welcomeToSelcomGo.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.onboardingTitle,
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.socialLoginSubtitle.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.onboardingSubtitle,
          ),
          SizedBox(height: 26.h),
          Obx(() {
            final isBusy = controller.isLoading.value;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.74.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.otpErrorBackground,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: AppColors.otpErrorBorder.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Text(
                          controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            height: 18 / 13,
                          ),
                        ),
                      ),
                    ),
                  AppSocialSignInButton(
                    provider: SocialSignInProvider.google,
                    onPressed: isBusy ? null : controller.signInWithGoogle,
                  ),
                  SizedBox(height: 13.36.h),
                  AppSocialSignInButton(
                    provider: SocialSignInProvider.facebook,
                    onPressed: isBusy ? null : controller.signInWithFacebook,
                  ),
                  if (Platform.isIOS) ...[
                    SizedBox(height: 13.36.h),
                    AppSocialSignInButton(
                      provider: SocialSignInProvider.apple,
                      onPressed: isBusy ? null : controller.signInWithApple,
                    ),
                  ],
                ],
              ),
            );
          }),
          SizedBox(height: 26.71.h),
          _ContactSupportFooter(
            onContactSupportTap: controller.openContactSupport,
          ),
        ],
      ),
    );
  }
}

class _ContactSupportFooter extends StatelessWidget {
  const _ContactSupportFooter({required this.onContactSupportTap});

  final VoidCallback onContactSupportTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.bodySecondary.copyWith(
      fontWeight: FontWeight.w500,
      color: AppColors.textBody,
      height: 20 / 14,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('${AppStrings.havingTroubleLoggingIn.tr} ', style: baseStyle),
        AppCupertinoTextButton.inlineBodyLink(
          label: AppStrings.contactSupport.tr,
          onPressed: onContactSupportTap,
          color: AppColors.iconHeartFilled,
          baseTextStyle: baseStyle,
        ),
      ],
    );
  }
}
