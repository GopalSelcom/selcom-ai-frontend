import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        top: false,
        // Illustration should overlap with status bar if needed, but we keep it simple
        child: Column(
          children: [
            // Illustration Section
            Expanded(
              flex: 5,
              child: PageView.builder(
                onPageChanged: controller.onPageChanged,
                itemCount: controller.slides.length,
                itemBuilder: (context, index) {
                  final slide = controller.slides[index];
                  return SvgPicture.asset(
                    slide.image,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),

            // Content Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dot Indicators
                    SizedBox(height: 10.h),

                    // Title
                    Obx(
                      () => Text(
                        controller.slides[controller.currentIndex.value].title,
                        textAlign: TextAlign.start,
                        style: AppTextStyles.onboardingTitle,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Subtitle
                    Obx(
                      () => Text(
                        controller
                            .slides[controller.currentIndex.value]
                            .subtitle,
                        textAlign: TextAlign.start,
                        style: AppTextStyles.onboardingSubtitle,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(
                          controller.slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            width: controller.currentIndex.value == index
                                ? 24.w
                                : 8.w,
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: controller.currentIndex.value == index
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: controller.currentIndex.value != index
                                    ? AppColors.textGrey
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Action Button
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: InkWell(
                        onTap: controller.onGetStarted,
                        child: Container(
                          height: 54.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: AppTextStyles.onboardingButton,
                              ),
                              SizedBox(width: 12.w),
                              SvgPicture.asset(
                                AppAssets.icArrowRight,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                                height: 24.h,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Footer Text
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Text(
                        'By continuing, you agree that you have read and accept our T&Cs and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingFooter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
