import '../../features/auth/data/models/login_pin_models.dart';
import '../../features/auth/domain/repositories/login_pin_repository.dart';
import '../routes/app_routes.dart';
import 'biometric_service.dart';
import 'storage_service.dart';

/// Cold-start and post-OTP routing for **app login PIN** / biometric.
///
/// Not ride PIN (`ride-pin-preference`). After splash with session:
/// locked → [AppRoutes.pinLogin]; biometric+hardware → [AppRoutes.biometricUnlock];
/// else `pin_set` → pin-login; else home/phone. After OTP: `pin_set == false` → pin-setup.
class LoginPinGateService {
  LoginPinGateService({
    required this.loginPinRepository,
    required this.biometricService,
  });

  final LoginPinRepository loginPinRepository;
  final BiometricService biometricService;

  Future<bool> hasStoredSession() async {
    final refresh = await StorageService().read(StorageKeys.refreshToken);
    if (refresh != null && refresh.isNotEmpty) return true;
    final auth = await StorageService().read(StorageKeys.authorizationToken);
    return auth != null && auth.isNotEmpty;
  }

  Future<void> saveLoginIdentity({
    required String mobileNumber,
    required String countryCode,
  }) async {
    final digits = mobileNumber.replaceAll(RegExp(r'\D'), '');
    final dial = countryCode.startsWith('+') ? countryCode : '+$countryCode';
    await StorageService().write(StorageKeys.loginMobileNumber, digits);
    await StorageService().write(StorageKeys.loginCountryCode, dial);
  }

  Future<LoginPinStatusModel?> fetchPinStatus() async {
    final result = await loginPinRepository.getPinStatus();
    return result.fold((_) => null, (status) {
      StorageService().write(
        StorageKeys.biometricLoginEnabled,
        status.biometricEnabled.toString(),
      );
      return status;
    });
  }

  /// Returns the next [AppRoutes] name after splash when a session exists.
  ///
  /// Order: locked PIN → biometric (if enabled + hardware) → PIN login → home/phone.
  Future<String> resolveColdStartRoute() async {
    if (!await hasStoredSession()) {
      return AppRoutes.onboarding;
    }

    var status = await fetchPinStatus();
    if (status == null) {
      final refreshed = await loginPinRepository.refreshSessionTokens();
      if (!refreshed) return AppRoutes.phone;
      status = await fetchPinStatus();
    }

    if (status == null) {
      return _routeAfterAuthenticatedWithoutPinGate();
    }

    if (status.lockedUntil != null &&
        status.lockedUntil!.isAfter(DateTime.now()) &&
        status.pinSet) {
      return AppRoutes.pinLogin;
    }

    if (status.biometricEnabled && await biometricService.isAvailable()) {
      return AppRoutes.biometricUnlock;
    }

    if (status.pinSet) {
      return AppRoutes.pinLogin;
    }

    return _routeAfterAuthenticatedWithoutPinGate();
  }

  Future<String> _routeAfterAuthenticatedWithoutPinGate() async {
    final signupCompleted =
        await StorageService().read(StorageKeys.signupCompleted);
    if (signupCompleted == 'false') {
      return AppRoutes.phone;
    }
    return AppRoutes.home;
  }

  /// After OTP / signup when user is authenticated but may need login PIN setup.
  ///
  /// Returns [AppRoutes.pinSetup] when `pin_set == false`, else [defaultRoute].
  Future<String> resolvePostAuthRoute({required String defaultRoute}) async {
    final status = await fetchPinStatus();
    if (status != null && !status.pinSet) {
      return AppRoutes.pinSetup;
    }
    return defaultRoute;
  }
}
