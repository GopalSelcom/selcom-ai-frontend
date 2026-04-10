import 'package:get/get.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_loading_screen.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/home/presentation/screens/location_selection_screen.dart';
import '../../features/ride/presentation/bindings/vehicle_selection_binding.dart';
import '../../features/ride/presentation/screens/vehicle_selection_screen.dart';
import '../../features/profile/presentation/screens/contact_us_screen.dart';
import '../../features/profile/presentation/bindings/contact_us_binding.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String phone = '/auth/phone';
  static const String otp = '/auth/otp';
  static const String profileLoading = '/auth/profile-loading';
  static const String home = '/home';
  static const String locationSelection = '/location-selection';
  static const String search = '/search';
  static const String booking = '/booking';
  static const String ride = '/ride';
  static const String feedback = '/feedback';
  static const String contactUs = '/contact-us';

  static List<GetPage> get pages => [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: phone,
      page: () => const PhoneInputScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: otp,
      page: () => const OtpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: profileLoading,
      page: () => const ProfileLoadingScreen(),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: locationSelection,
      page: () => const LocationSelectionScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: booking,
      page: () => const VehicleSelectionScreen(),
      binding: VehicleSelectionBinding(),
    ),
    GetPage(
      name: contactUs,
      page: () => const ContactUsScreen(),
      binding: ContactUsBinding(),
    ),
  ];
}
