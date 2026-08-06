import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/localization/app_strings.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/web_view_screen.dart';
import '../../domain/repositories/auth_repository.dart';

class OnboardingController extends GetxController {
  OnboardingController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  final currentIndex = 0.obs;

  late final PageController pageController;
  late final PageController textPageController;

  /// When `false`, illustration area shows a shimmer instead of local assets so we
  /// never flash static images right before switching to API `background_image_url`.
  final bannerFetchSettled = false.obs;

  /// Always three slides; title, subtitle, and illustration may come from the banner API
  /// with per-field fallback to [_staticSlides].
  final RxList<OnboardingSlide> slides = <OnboardingSlide>[].obs;

  List<OnboardingSlide> _staticSlides() => [
    OnboardingSlide(
      title: AppStrings.makingYourDriveBestIsOurResponsibility.tr,
      subtitle: AppStrings.loremIpsumDolorSitAmetConsectetur.tr,
      image: AppAssets.onboarding1,
    ),
    OnboardingSlide(
      title: AppStrings.thisIsSecondSlide.tr,
      subtitle: AppStrings.loremIpsumDolorSitAmetConsectetur.tr,
      image: AppAssets.onboarding2,
    ),
    OnboardingSlide(
      title: AppStrings.thisIsThirdSlide.tr,
      subtitle: AppStrings.loremIpsumDolorSitAmetConsectetur.tr,
      image: AppAssets.onboarding3,
    ),
  ];

  static String? _trimUrl(String? raw) {
    final t = (raw ?? '').trim();
    return t.isEmpty ? null : t;
  }

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    textPageController = PageController();
    pageController.addListener(_syncTextPageScroll);
    slides.assignAll(_staticSlides());
    _loadOnboardingBannersFromApi();
  }

  @override
  void onClose() {
    pageController.removeListener(_syncTextPageScroll);
    pageController.dispose();
    textPageController.dispose();
    super.onClose();
  }

  /// Keeps copy in sync with illustration swipe (avoids text blink on page change).
  void _syncTextPageScroll() {
    final page = pageController.page;
    if (page == null || !textPageController.hasClients) return;
    final viewport = textPageController.position.viewportDimension;
    if (viewport <= 0) return;
    final maxPage = (slides.length - 1).toDouble();
    final clampedPage = page.clamp(0.0, maxPage < 0 ? 0.0 : maxPage);
    textPageController.jumpTo(clampedPage * viewport);
  }

  /// Merges API `title`, `subtitle`, and `background_image_url` per slide; on error or
  /// empty response, [slides] stays [_staticSlides].
  Future<void> _loadOnboardingBannersFromApi() async {
    final result = await _authRepository.getOnboardingBanners();
    result.fold(
      (_) {
        bannerFetchSettled.value = true;
      },
      (items) {
        if (items.isNotEmpty) {
          final base = _staticSlides();
          final merged = List<OnboardingSlide>.generate(3, (i) {
            final b = base[i];
            final api = items.length == 1
                ? items.first
                : (i < items.length ? items[i] : null);
            final title = (api != null && api.title.isNotEmpty)
                ? api.title
                : b.title;
            final subtitle = (api != null && api.subtitle.isNotEmpty)
                ? api.subtitle
                : b.subtitle;
            final url = api != null ? _trimUrl(api.backgroundImageUrl) : null;
            return OnboardingSlide(
              title: title,
              subtitle: subtitle,
              image: b.image,
              networkImageUrl: url,
            );
          });
          slides.assignAll(merged);
        }
        bannerFetchSettled.value = true;
      },
    );
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  void onGetStarted() {
    Get.offAllNamed(AppRoutes.login);
  }

  void onSkip() {
    Get.offAllNamed(AppRoutes.login);
  }

  /// Opens the same legal WebView as Profile → Privacy Policy.
  void openPrivacyPolicy() {
    unawaited(
      WebViewScreen.open(
        title: AppStrings.privacyPolicy.tr,
        url: AppConfig.versionedApiUrl(URLS.common.privacy),
      ),
    );
  }

  /// Opens the same legal WebView as Profile → Terms and Conditions.
  void openTermsAndConditions() {
    unawaited(
      WebViewScreen.open(
        title: AppStrings.termsAndConditions.tr,
        url: AppConfig.versionedApiUrl(URLS.common.termsAndConditions),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String subtitle;

  /// Local SVG fallback when [networkImageUrl] is missing or fails to load in UI.
  final String image;

  /// Illustration from API (`background_image_url`) when set; otherwise [image] is used.
  final String? networkImageUrl;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.image,
    this.networkImageUrl,
  });

  bool get usesNetworkImage => (networkImageUrl ?? '').trim().isNotEmpty;
}
