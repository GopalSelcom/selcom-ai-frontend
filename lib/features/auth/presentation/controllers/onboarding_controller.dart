import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final currentIndex = 0.obs;

  final List<OnboardingSlide> slides = [
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
  final String image;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}
