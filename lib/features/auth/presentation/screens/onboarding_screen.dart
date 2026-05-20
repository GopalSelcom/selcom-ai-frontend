import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_primary_button.dart';
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
              child: Obx(() {
                final settled = controller.bannerFetchSettled.value;
                return PageView.builder(
                  onPageChanged: controller.onPageChanged,
                  itemCount: controller.slides.length,
                  itemBuilder: (context, index) {
                    final slide = controller.slides[index];
                    if (!settled) {
                      return const _OnboardingIllustrationShimmer();
                    }
                    return _OnboardingIllustration(slide: slide);
                  },
                );
              }),
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
                                  : AppColors.transparent,
                              border: Border.all(
                                color: controller.currentIndex.value != index
                                    ? AppColors.textBody
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
                      child: AppPrimaryButton(
                        label: AppStrings.getStarted.tr,
                        onPressed: controller.onGetStarted,
                        height: 54.h,
                        labelStyle: AppTextStyles.onboardingButton,
                        iconAsset: AppAssets.locationIcArrowRight,
                        iconColor: AppColors.white,
                        alignIconToTrailingEnd: true,
                        showBottomInnerShadow: true,
                      ),
                    ),

                    // Footer Text
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
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
          ],
        ),
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    if (slide.usesNetworkImage) {
      final raw = slide.networkImageUrl!.trim();
      final lower = raw.toLowerCase();
      if (lower.endsWith('.svg')) {
        return SvgPicture.network(
          raw,
          width: double.infinity,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => const _OnboardingIllustrationShimmer(),
        );
      }
      return CachedNetworkImage(
        imageUrl: raw,
        width: double.infinity,
        fit: BoxFit.contain,
        placeholder: (_, __) => const _OnboardingIllustrationShimmer(),
        errorWidget: (_, __, ___) => SvgPictureAsset(
          slide.image,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      );
    }

    return SvgPictureAsset(
      slide.image,
      width: double.infinity,
      fit: BoxFit.contain,
    );
  }
}

class _OnboardingIllustrationShimmer extends StatelessWidget {
  const _OnboardingIllustrationShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.skeletonBase,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
