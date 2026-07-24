import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
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

  /// Reserved height for title (2 lines) + gap + subtitle (2 lines) so dots stay fixed.
  static double get _copyBlockHeight {
    final titleLineHeight = 28.sp * (34 / 28);
    final subtitleLineHeight = 15.sp * (20 / 15);
    return titleLineHeight * 2 + 4.h + subtitleLineHeight * 2;
  }

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
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    overscroll: false,
                    physics: const ClampingScrollPhysics(
                      parent: PageScrollPhysics(),
                    ),
                  ),
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: controller.slides.length,
                    itemBuilder: (context, index) {
                      final slide = controller.slides[index];
                      if (!settled) {
                        return const _OnboardingIllustrationShimmer();
                      }
                      return _OnboardingIllustration(slide: slide);
                    },
                  ),
                );
              }),
            ),

            // Content Section
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 18.h),
                  SizedBox(
                    height: _copyBlockHeight,
                    child: PageView.builder(
                      controller: controller.textPageController,
                      physics: const NeverScrollableScrollPhysics(),
                      clipBehavior: Clip.hardEdge,
                      itemCount: controller.slides.length,
                      itemBuilder: (context, index) {
                        return Obx(() {
                          final slide = controller.slides[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slide.title,
                                    textAlign: TextAlign.start,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.onboardingTitle,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    slide.subtitle,
                                    textAlign: TextAlign.start,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.onboardingSubtitle,
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(
                                controller.slides.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                                  width: controller.currentIndex.value == index
                                      ? 32.w
                                      : 10.w,
                                  height: 10.w,
                                  decoration: BoxDecoration(
                                    color:
                                        controller.currentIndex.value == index
                                        ? AppColors.primary
                                        : AppColors.transparent,
                                    border: Border.all(
                                      color:
                                          controller.currentIndex.value != index
                                          ? AppColors.textBody
                                          : AppColors.primary,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(9.r),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
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
                            ),
                          ),
                          // One sentence; T&Cs and Privacy Policy open profile WebViews.
                          Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: _OnboardingLegalFooter(
                              onTermsTap: controller.openTermsAndConditions,
                              onPrivacyTap: controller.openPrivacyPolicy,
                            ),
                          ),
                        ],
                      ),
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
}

/// Footer copy as one centered sentence with inline tappable legal links.
///
/// Uses [Text.rich] so wrapping matches the original single-line text. Only
/// [AppStrings.onboardingFooterTermsLink] and [AppStrings.privacyPolicy] are
/// styled as links (semi-bold + underline).
class _OnboardingLegalFooter extends StatefulWidget {
  const _OnboardingLegalFooter({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_OnboardingLegalFooter> createState() => _OnboardingLegalFooterState();
}

class _OnboardingLegalFooterState extends State<_OnboardingLegalFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  TextStyle get _baseStyle => AppTextStyles.onboardingFooter;

  /// Semi-bold + underline on link phrases only; rest of sentence stays regular.
  TextStyle get _linkStyle => AppTextStyles.onboardingFooter.copyWith(
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.textBody,
    decorationThickness: 1.5,
  );

  @override
  void initState() {
    super.initState();
    // Recognizers must be created/disposed when using tappable TextSpans.
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: _baseStyle,
        children: [
          TextSpan(text: AppStrings.onboardingFooterLead.tr),
          TextSpan(
            text: AppStrings.onboardingFooterTermsLink.tr,
            style: _linkStyle,
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: AppStrings.onboardingFooterJoiner.tr),
          TextSpan(
            text: AppStrings.privacyPolicy.tr,
            style: _linkStyle,
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      // Prevent tight line height from clipping underlines (Metropolis footer).
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: true,
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
          fit: BoxFit.cover,
          placeholderBuilder: (_) => const _OnboardingIllustrationShimmer(),
        );
      }
      return CachedNetworkImage(
        imageUrl: raw,
        width: double.infinity,
        fit: BoxFit.fill,
        placeholder: (_, __) => const _OnboardingIllustrationShimmer(),
        errorWidget: (_, __, ___) => SvgPictureAsset(
          slide.image,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return SvgPictureAsset(
      slide.image,
      width: double.infinity,
      fit: BoxFit.cover,
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
