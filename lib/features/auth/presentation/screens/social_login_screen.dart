import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_social_sign_in_button.dart';
import '../controllers/auth_controller.dart';

class SocialLoginScreen extends GetView<AuthController> {
  const SocialLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Stack(
        children: [
          const _SocialLoginBackdrop(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 24.h),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SocialLoginHero(),
                            SizedBox(height: 28.h),
                            _SocialLoginActionsCard(controller: controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
                    child: Text(
                      AppStrings
                          .byContinuingYouAgreeThatYouHaveReadAndAcceptOurTAndCsAndPrivacyPolicy
                          .tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.onboardingFooter.copyWith(
                        fontSize: 11.sp,
                        height: 16 / 11,
                        color: AppColors.textSlateSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLoginBackdrop extends StatelessWidget {
  const _SocialLoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight,
                AppColors.pageBackground,
                AppColors.bgMintLight,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -48.h,
          right: -36.w,
          child: _GlowOrb(
            size: 180.w,
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        Positioned(
          top: 120.h,
          left: -56.w,
          child: _GlowOrb(
            size: 140.w,
            color: AppColors.secondary.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: 180.h,
          right: -20.w,
          child: _GlowOrb(
            size: 96.w,
            color: AppColors.info.withValues(alpha: 0.14),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.45,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}

class _SocialLoginHero extends StatelessWidget {
  const _SocialLoginHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.textHeading, AppColors.secondary],
          ).createShader(bounds),
          child: Text(
            AppStrings.welcomeToSelcomGo.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.onboardingTitle.copyWith(
              letterSpacing: -0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialLoginActionsCard extends StatelessWidget {
  const _SocialLoginActionsCard({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(color: AppColors.white),
            boxShadow: [
              BoxShadow(
                color: AppColors.textHeading.withValues(alpha: 0.06),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.login.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 4.h),
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 18.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                ),
              ),
              Obx(() {
                final isBusy = controller.isLoading.value;

                return Column(
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
                    SizedBox(height: 12.h),
                    AppSocialSignInButton(
                      provider: SocialSignInProvider.facebook,
                      onPressed: isBusy ? null : controller.signInWithFacebook,
                    ),
                    if (Platform.isIOS) ...[
                      SizedBox(height: 12.h),
                      AppSocialSignInButton(
                        provider: SocialSignInProvider.apple,
                        onPressed: isBusy ? null : controller.signInWithApple,
                      ),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
