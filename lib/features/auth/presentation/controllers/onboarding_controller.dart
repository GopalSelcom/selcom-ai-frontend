import 'package:get/get.dart';
import '../../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final currentIndex = 0.obs;

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      title: 'Making your drive best is our responsibility',
      subtitle: 'Lorem ipsum dolor sit amet, consectetur',
      image: AppAssets.onboarding1,
    ),
    OnboardingSlide(
      title: 'This is Second Slide',
      subtitle: 'Lorem ipsum dolor sit amet, consectetur',
      image: AppAssets.onboarding2,
    ),
    OnboardingSlide(
      title: 'This is third Slide',
      subtitle: 'Lorem ipsum dolor sit amet, consectetur',
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
