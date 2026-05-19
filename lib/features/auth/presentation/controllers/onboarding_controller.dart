import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';

class OnboardingController extends GetxController {
  final currentIndex = 0.obs;

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
    slides.assignAll(_staticSlides());
    _loadOnboardingBannersFromApi();
  }

  /// Merges API `title`, `subtitle`, and `background_image_url` per slide; on error or
  /// empty response, [slides] stays [_staticSlides].
  Future<void> _loadOnboardingBannersFromApi() async {
    final result = await Get.find<AuthRepository>().getOnboardingBanners();
    result.fold((_) {
      bannerFetchSettled.value = true;
    }, (items) {
      if (items.isNotEmpty) {
        final base = _staticSlides();
        final merged = List<OnboardingSlide>.generate(3, (i) {
          final b = base[i];
          final api = items.length == 1
              ? items.first
              : (i < items.length ? items[i] : null);
          final title =
              (api != null && api.title.isNotEmpty) ? api.title : b.title;
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
    });
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
  }

  void onGetStarted() {
    Get.offAllNamed(AppRoutes.phone);
  }

  void onSkip() {
    Get.offAllNamed(AppRoutes.phone);
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
