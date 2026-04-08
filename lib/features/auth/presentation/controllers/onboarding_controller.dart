import 'package:get/get.dart';
import '../../../../core/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final currentIndex = 0.obs;

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      title: 'Making your drive best is our responsibility',
      subtitle: 'Lorem ipsum dolor sit amet, consectetur',
      image: 'assets/images/onboarding_1.svg',
    ),
    OnboardingSlide(
      title: 'Making your drive best is our responsibility',
      subtitle: 'Lorem ipsum dolor sit amet, consectetur',
      image: 'assets/images/onboarding_2.svg',
    ),
    OnboardingSlide(
      title: 'Making your drive best is our responsibility',
      subtitle: 'Lorem ipsum dolor sit amet, consectetur',
      image: 'assets/images/onboarding_3.svg',
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
