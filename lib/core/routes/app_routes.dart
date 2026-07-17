import 'package:agora_calling_package/agora_calling_package.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/phone_input_screen.dart';
import '../../features/auth/presentation/bindings/login_support_binding.dart';
import '../../features/auth/presentation/screens/login_support_screen.dart';
import '../../features/auth/presentation/screens/profile_loading_screen.dart';
import '../../features/auth/presentation/screens/social_login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/bindings/confirm_location_binding.dart';
import '../../features/home/presentation/bindings/home_binding.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/location_selection_screen.dart';
import '../../features/home/presentation/bindings/select_saved_location_binding.dart';
import '../../features/home/presentation/screens/select_saved_location_screen.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';
import '../../features/profile/presentation/bindings/contact_us_binding.dart';
import '../../features/profile/presentation/bindings/favorite_locations_binding.dart';
import '../../features/profile/presentation/bindings/profile_binding.dart';
import '../../features/profile/presentation/screens/contact_us_screen.dart';
import '../../features/profile/presentation/screens/favorite_locations_screen.dart';
import '../../features/profile/presentation/screens/payment_methods_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/payment/presentation/bindings/selcom_pesa_to_wallet_binding.dart';
import '../../features/payment/presentation/screens/selcom_pesa_to_wallet_screen.dart';
import '../../features/profile/presentation/settings/bindings/safety_binding.dart';
import '../../features/profile/presentation/settings/bindings/settings_binding.dart';
import '../../features/profile/presentation/settings/screens/safety_screen.dart';
import '../../features/profile/presentation/settings/screens/settings_screen.dart';
import '../../features/promotions/presentation/bindings/promo_code_binding.dart';
import '../../features/promotions/presentation/screens/promo_code_screen.dart';
import '../../features/ride/presentation/bindings/driver_accepted_binding.dart';
import '../../features/ride/presentation/bindings/finding_driver_binding.dart';
import '../../features/ride/presentation/bindings/my_rides_binding.dart';
import '../../features/ride/presentation/bindings/ride_message_binding.dart';
import '../../features/ride/presentation/bindings/vehicle_selection_binding.dart';
import '../../shared/widgets/confirm_location_screen.dart';
import '../../features/ride/presentation/screens/driver_accepted_screen.dart';
import '../../features/ride/presentation/screens/finding_driver_screen.dart';
import '../../features/ride/presentation/screens/my_rides_screen.dart';
import '../../features/ride/presentation/screens/ride_message_screen.dart';
import '../../features/ride/presentation/bindings/stop_editor_binding.dart';
import '../../features/ride/presentation/screens/stop_editor_screen.dart';
import '../../features/ride/presentation/screens/vehicle_selection_screen.dart';
import '../../features/wallet/presentation/bindings/wallet_binding.dart';
import '../../features/wallet/presentation/bindings/wallet_route_middleware.dart';
import '../../features/wallet/presentation/bindings/wallet_history_binding.dart';
import '../../features/wallet/presentation/screens/wallet_history_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String loginSupport = '/auth/login-support';
  static const String phone = '/auth/phone';
  static const String otp = '/auth/otp';
  static const String profileLoading = '/auth/profile-loading';
  static const String home = '/home';
  static const String locationSelection = '/location-selection';
  static const String booking = '/booking';
  static const String confirmPickup = '/confirm-pickup';
  static const String findingDriver = '/finding-driver';

  /// SCR-11 — driver accepted (heading to pickup).
  static const String driverAccepted = '/driver-accepted';
  static const String contactUs = '/contact-us';
  static const String promotions = '/promotions';
  static const String favoriteLocations = '/favorite-locations';
  static const String notifications = '/notifications';
  static const String rideMessage = '/ride/message';
  static const String paymentMethods = '/payment-methods';
  static const String profile = '/profile';
  static const String myRides = '/my-rides';
  static const String selcomPesaToWallet = '/selcom-pesa-to-wallet';
  static const String settings = '/settings';
  static const String safety = '/safety';
  static const String selectSavedLocation = '/select-saved-location';
  static const String checkPickupPoint = '/check-pickup-point';
  static const String stopEditor = '/stop-editor';
  static const String confirmStop = '/confirm-stop';
  static const String changeDropLocationEditor = '/change-drop-location-editor';
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';

  static List<GetPage> get pages => [
    ...AgoraCalling.routes(),
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(
      name: onboarding,
      page: () => const OnboardingScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: login,
      page: () => const SocialLoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: loginSupport,
      page: () => const LoginSupportScreen(),
      binding: LoginSupportBinding(),
    ),
    GetPage(
      name: phone,
      page: () => const PhoneInputScreen(),
      binding: AuthBinding(),
    ),
    GetPage(name: otp, page: () => const OtpScreen(), binding: AuthBinding()),
    GetPage(
      name: profileLoading,
      page: () => const ProfileLoadingScreen(),
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
      page: () => const ConfirmLocationScreen(),
      binding: ConfirmLocationBinding(),
    ),
    GetPage(
      name: findingDriver,
      page: () => const FindingDriverScreen(),
      binding: FindingDriverBinding(),
    ),
    GetPage(
      name: driverAccepted,
      page: () => const DriverAcceptedScreen(),
      binding: DriverAcceptedBinding(),
    ),
    GetPage(
      name: contactUs,
      page: () => const ContactUsScreen(),
      binding: ContactUsBinding(),
    ),
    GetPage(
      name: promotions,
      page: () => const PromoCodeScreen(),
      binding: PromoCodeBinding(),
    ),
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
      name: profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: myRides,
      page: () => const MyRidesScreen(),
      binding: MyRidesBinding(),
    ),
    GetPage(
      name: selcomPesaToWallet,
      page: () => const SelcomPesaToWalletScreen(),
      binding: SelcomPesaToWalletBinding(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: safety,
      page: () => const SafetyScreen(),
      binding: SafetyBinding(),
    ),
    GetPage(
      name: selectSavedLocation,
      page: () => const SelectSavedLocationScreen(),
      binding: SelectSavedLocationBinding(),
    ),
    GetPage(
      name: checkPickupPoint,
      page: () => const ConfirmLocationScreen(),
      binding: ConfirmLocationBinding(),
    ),
    GetPage(
      name: stopEditor,
      page: () => const StopEditorScreen(),
      binding: StopEditorBinding(),
    ),
    GetPage(
      name: changeDropLocationEditor,
      page: () => const StopEditorScreen(),
      binding: StopEditorBinding(),
    ),
    GetPage(
      name: confirmStop,
      page: () => const ConfirmLocationScreen(),
      binding: ConfirmLocationBinding(),
    ),
    GetPage(
      name: wallet,
      page: () => const WalletScreen(),
      binding: WalletBinding(),
      middlewares: [WalletRouteMiddleware()],
    ),
    GetPage(
      name: walletTransactions,
      page: () => const WalletHistoryScreen(),
      binding: WalletHistoryBinding(),
    ),
  ];
}
