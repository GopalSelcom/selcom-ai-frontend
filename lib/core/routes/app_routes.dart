import 'package:get/get.dart';
import 'package:selcom_rides_frontend/features/ride/presentation/screens/stop_editor_screen.dart';
import 'package:selcom_rides_frontend/features/ride/presentation/screens/confirm_stop_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_loading_screen.dart';
import '../../features/auth/presentation/screens/sign_up.dart';
import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/home/presentation/screens/location_selection_screen.dart';
import '../../features/home/presentation/screens/select_saved_location_screen.dart';
import '../../features/home/presentation/screens/check_pickup_point_screen.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';
import '../../features/ride/presentation/bindings/driver_accepted_binding.dart';
import '../../features/ride/presentation/bindings/finding_driver_binding.dart';
import '../../features/ride/presentation/bindings/vehicle_selection_binding.dart';
import '../../features/ride/presentation/bindings/confirm_pickup_binding.dart';
import '../../features/ride/presentation/screens/driver_accepted_screen.dart';
import '../../features/ride/presentation/screens/finding_driver_screen.dart';
import '../../features/ride/presentation/screens/vehicle_selection_screen.dart';
import '../../features/ride/presentation/screens/confirm_pickup_screen.dart';
import '../../features/profile/presentation/screens/contact_us_screen.dart';
import '../../features/profile/presentation/bindings/contact_us_binding.dart';
import '../../features/promotions/presentation/screens/promocode_screen.dart';
import '../../features/profile/presentation/screens/favorite_locations_screen.dart';
import '../../features/profile/presentation/bindings/favorite_locations_binding.dart';
import '../../features/ride/presentation/bindings/ride_message_binding.dart';
import '../../features/ride/presentation/screens/ride_message_screen.dart';
import '../../features/profile/presentation/screens/payment_methods_screen.dart';
import '../../features/profile/presentation/settings/bindings/settings_binding.dart';
import '../../features/profile/presentation/settings/screens/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String phone = '/auth/phone';
  static const String otp = '/auth/otp';
  static const String profileLoading = '/auth/profile-loading';
  static const String signUp = '/auth/sign-up';
  static const String home = '/home';
  static const String locationSelection = '/location-selection';
  static const String search = '/search';
  static const String booking = '/booking';
  static const String confirmPickup = '/confirm-pickup';
  static const String findingDriver = '/finding-driver';

  /// SCR-11 — driver accepted (heading to pickup).
  static const String driverAccepted = '/driver-accepted';
  static const String ride = '/ride';
  static const String feedback = '/feedback';
  static const String contactUs = '/contact-us';
  static const String promotions = '/promotions';
  static const String favoriteLocations = '/favorite-locations';
  static const String notifications = '/notifications';
  static const String rideMessage = '/ride/message';
  static const String paymentMethods = '/payment-methods';
  static const String settings = '/settings';
  static const String selectSavedLocation = '/select-saved-location';
  static const String checkPickupPoint = '/check-pickup-point';
  static const String stopEditor = '/stop-editor';
  static const String confirmStop = '/confirm-stop';

  static List<GetPage> get pages => [
    GetPage(name: splash, page: () => const SplashScreen()),
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
    GetPage(name: otp, page: () => const OtpScreen(), binding: AuthBinding()),
    GetPage(name: profileLoading, page: () => const ProfileLoadingScreen()),
    GetPage(
      name: signUp,
      page: () => const SignUpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(name: home, page: () => const HomeScreen(), binding: HomeBinding()),
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
      name: confirmPickup,
      page: () => const ConfirmPickupScreen(),
      binding: ConfirmPickupBinding(),
    ),
    GetPage(
      name: findingDriver,
      page: () => const FindingDriverScreen(),
      binding: FindingDriverBinding(),
    ),
    GetPage(
      name: driverAccepted,
      page: () => DriverAcceptedScreen(),
      binding: DriverAcceptedBinding(),
    ),
    GetPage(
      name: contactUs,
      page: () => const ContactUsScreen(),
      binding: ContactUsBinding(),
    ),
    GetPage(name: promotions, page: () => const PromocodeScreen()),
    GetPage(
      name: favoriteLocations,
      page: () => const FavoriteLocationsScreen(),
      binding: FavoriteLocationsBinding(),
    ),
    GetPage(name: notifications, page: () => const NotificationScreen()),
    GetPage(
      name: rideMessage,
      page: () => const RideMessageScreen(),
      binding: RideMessageBinding(),
    ),
    GetPage(name: paymentMethods, page: () => const PaymentMethodsScreen()),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: selectSavedLocation,
      page: () => const SelectSavedLocationScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: checkPickupPoint,
      page: () => const CheckPickupPointScreen(),
      binding: HomeBinding(),
    ),
    GetPage(name: stopEditor, page: () => const StopEditorScreen()),
    GetPage(
      name: confirmStop,
      page: () => const ConfirmStopScreen(),
      binding: HomeBinding(),
    ),
  ];
}
