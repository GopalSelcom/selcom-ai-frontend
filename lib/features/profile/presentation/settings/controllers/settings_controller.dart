import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/errors/login_pin_failure.dart';
import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/localization/localization.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/services/analytics_service.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../../../shared/utils/app_dialogs.dart';
import '../../../../../features/auth/domain/usecases/login_pin_usecases.dart';
import '../../../../../features/settings/domain/usecases/settings_usecase.dart';

/// Profile **Settings** screen logic.
///
/// **Login PIN / biometric** (this file + [SettingsScreen]):
/// - [shouldShowBiometricLoginSetting] — hide Login & security block if no device biometrics.
/// - [loginPinSet] from `GET /auth/pin/status` — gates Change PIN menu item.
/// - [onToggleBiometricLogin] — local auth then `POST /auth/biometric`.
///
/// **Ride PIN** ([shouldShowRidePinSetting]) uses `ride-pin-preference` — separate API.
class SettingsController extends GetxController {
  final SettingsUseCase settingsUseCase;
  final AppSettingsService appSettingsService;
  final GetLoginPinStatusUseCase getLoginPinStatusUseCase;
  final SetLoginBiometricUseCase setLoginBiometricUseCase;
  final BiometricService biometricService;
  final AnalyticsService analyticsService;

  SettingsController({
    required this.settingsUseCase,
    required this.appSettingsService,
    required this.getLoginPinStatusUseCase,
    required this.setLoginBiometricUseCase,
    required this.biometricService,
    required this.analyticsService,
  });

  final isLoading = false.obs;
  final isSaving = false.obs;
  final features = <String, bool>{}.obs;
  final userEnabledRidePin = false.obs;
  final adminRequiredRidePin = false.obs;
  final effectiveRequiredRidePin = false.obs;

  /// App login PIN / biometric — not [ride-pin-preference].
  final loginPinSet = false.obs;
  final biometricLoginEnabled = false.obs;
  final isSavingBiometric = false.obs;

  /// False when the device has no Face ID / fingerprint hardware.
  final biometricHardwareAvailable = false.obs;

  bool get canToggleRidePin => !adminRequiredRidePin.value;
  bool get canToggleBiometricLogin => loginPinSet.value;

  /// Hide biometric row when the device has no Face ID / fingerprint hardware.
  bool get shouldShowBiometricLoginSetting =>
      biometricHardwareAvailable.value;

  /// From `/go/settings`: when `ride_pin_admin_required` is **true**, admin owns
  /// ride PIN — hide the row. When **false**, the user may manage PIN preference here.
  bool get shouldShowRidePinSetting =>
      !appSettingsService.featureEnabled('ride_pin_admin_required');
  bool get ridePinSwitchValue =>
      adminRequiredRidePin.value
          ? effectiveRequiredRidePin.value
          : userEnabledRidePin.value;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;

    await appSettingsService.preload();
    features.assignAll(appSettingsService.features);

    if (shouldShowRidePinSetting) {
      final preferenceResult = await settingsUseCase.getRidePinPreference();
      preferenceResult.fold(
        (failure) => AppDialogs.showErrorDialog(message: failure.message),
        (preference) {
          userEnabledRidePin.value = preference.userEnabled;
          adminRequiredRidePin.value = preference.adminRequired;
          effectiveRequiredRidePin.value = preference.effectiveRequired;
        },
      );

      if (adminRequiredRidePin.value) {
        effectiveRequiredRidePin.value = true;
      }
    } else {
      userEnabledRidePin.value = false;
      adminRequiredRidePin.value = false;
      effectiveRequiredRidePin.value = false;
    }

    await _loadLoginPinSettings();
    isLoading.value = false;
  }

  Future<void> _loadLoginPinSettings() async {
    biometricHardwareAvailable.value = await biometricService.isAvailable();

    final result = await getLoginPinStatusUseCase();
    result.fold((_) {}, (status) {
      loginPinSet.value = status.pinSet;
      biometricLoginEnabled.value = status.biometricEnabled;
    });
  }

  Future<void> onToggleRidePin(bool value) async {
    if (!canToggleRidePin || isSaving.value) return;

    final previousValue = userEnabledRidePin.value;
    userEnabledRidePin.value = value;
    isSaving.value = true;

    final result = await settingsUseCase.updateRidePinPreference(enabled: value);
    result.fold(
      (failure) {
        userEnabledRidePin.value = previousValue;
        AppDialogs.showErrorDialog(message: failure.message);
      },
      (preference) {
        userEnabledRidePin.value = preference.userEnabled;
        adminRequiredRidePin.value = preference.adminRequired;
        effectiveRequiredRidePin.value = preference.effectiveRequired;
      },
    );

    isSaving.value = false;
  }

  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> onToggleBiometricLogin(bool enabled) async {
    if (!canToggleBiometricLogin || isSavingBiometric.value) return;

    if (enabled) {
      final available = await biometricService.isAvailable();
      if (!available) {
        AppDialogs.showErrorDialog(
          message: AppStrings.setPinFirstForBiometric.tr,
        );
        return;
      }
      final authenticated = await biometricService.authenticate(
        localizedReason: AppStrings.unlockWithBiometric.tr,
      );
      if (!authenticated) return;
    }

    final previous = biometricLoginEnabled.value;
    biometricLoginEnabled.value = enabled;
    isSavingBiometric.value = true;

    final result = await setLoginBiometricUseCase(enabled);
    isSavingBiometric.value = false;

    result.fold(
      (failure) {
        biometricLoginEnabled.value = previous;
        if (failure is LoginPinFailure &&
            failure.errorCode == 'AUTH_PIN_REQUIRED_FOR_BIOMETRIC') {
          AppDialogs.showErrorDialog(
            message: AppStrings.setPinFirstForBiometric.tr,
            onConfirm: () => Get.toNamed(
              AppRoutes.pinSetup,
              arguments: {
                'mode': 'setup',
                'nextRoute': AppRoutes.settings,
              },
            ),
          );
          return;
        }
        AppDialogs.showErrorDialog(message: failure.message);
      },
      (serverValue) {
        biometricLoginEnabled.value = serverValue;
        if (serverValue) {
          unawaited(analyticsService.logEvent('go_biometric_enabled'));
        }
      },
    );
  }

  void openChangeLoginPin() {
    Get.toNamed(
      AppRoutes.pinChange,
      arguments: {'mode': 'change'},
    );
  }

  Future<void> toggleLanguage(BuildContext context) async {
    final current = Get.locale ?? Get.deviceLocale ?? const Locale('en');
    final nextCode = current.languageCode == 'sw' ? 'en' : 'sw';
    await Localization.instance.changeLanguage(context, nextCode);
    Get.snackbar(
      AppStrings.language.tr,
      nextCode == 'sw'
          ? AppStrings.switchedToSwahili.tr
          : AppStrings.switchedToEnglish.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  String get currentLanguageLabel {
    final current = Get.locale ?? Get.deviceLocale ?? const Locale('en');
    return current.languageCode == 'sw'
        ? AppStrings.swahili.tr
        : AppStrings.english.tr;
  }
}
