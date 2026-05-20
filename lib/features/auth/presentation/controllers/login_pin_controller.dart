import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/user_model.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/login_pin_failure.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/login_pin_gate_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../core/utils/login_pin_validator.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../domain/usecases/login_pin_usecases.dart';

/// Screen mode passed via route args or inferred from [Get.currentRoute].
enum LoginPinScreenMode {
  /// First-time PIN after OTP when `pin_set == false`.
  setup,

  /// Returning user on cold start or after biometric cancel.
  login,

  /// Settings → Change PIN (`current` → `newPin` → `confirmNew`).
  change,
}

enum LoginPinSetupStep { enter, confirm }

enum LoginPinChangeStep { current, newPin, confirmNew }

/// Business logic for [LoginPinScreen] (setup, login, change).
///
/// **Not ride PIN** (`ride-pin-preference` is separate in settings).
///
/// - **setup:** enter → confirm → `SetupLoginPinUseCase` → `Get.offAllNamed(nextRoute)`.
/// - **login:** PIN verify or tap biometric → session refresh → home or phone.
/// - **change:** current → new → confirm → `ChangeLoginPinUseCase` (old PIN
///   validated by API on submit) → success dialog.
///
/// Route args: `{ 'mode': 'setup'|'login'|'change', 'nextRoute': AppRoutes.* }`.
/// API: `/v4/go/auth/pin/*`, `/auth/biometric`.
class LoginPinController extends GetxController {
  LoginPinController({
    required this.setupLoginPinUseCase,
    required this.verifyLoginPinUseCase,
    required this.changeLoginPinUseCase,
    required this.getLoginPinStatusUseCase,
    required this.deleteLoginPinUseCase,
    required this.loginPinGateService,
    required this.analyticsService,
    required this.biometricService,
    required this.refreshLoginSessionUseCase,
  });

  final SetupLoginPinUseCase setupLoginPinUseCase;
  final VerifyLoginPinUseCase verifyLoginPinUseCase;
  final ChangeLoginPinUseCase changeLoginPinUseCase;
  final GetLoginPinStatusUseCase getLoginPinStatusUseCase;
  final DeleteLoginPinUseCase deleteLoginPinUseCase;
  final LoginPinGateService loginPinGateService;
  final AnalyticsService analyticsService;
  final BiometricService biometricService;
  final RefreshLoginSessionUseCase refreshLoginSessionUseCase;

  late final LoginPinScreenMode mode;
  String _nextRoute = AppRoutes.home;

  final setupStep = LoginPinSetupStep.enter.obs;
  final changeStep = LoginPinChangeStep.current.obs;
  final isLoading = false.obs;

  /// Biometric tap only — avoids full-screen loader over the PIN screen.
  final isBiometricLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final isInputDisabled = false.obs;
  final lockCountdownLabel = ''.obs;

  /// Server `biometric_enabled` + device hardware (login screen only).
  final biometricLoginEnabled = false.obs;
  final biometricHardwareAvailable = false.obs;

  bool get showBiometricUnlockButton =>
      mode == LoginPinScreenMode.login &&
      biometricLoginEnabled.value &&
      biometricHardwareAvailable.value &&
      !isInputDisabled.value;

  String _firstPin = '';
  String _newPinCandidate = '';
  Timer? _lockTimer;

  /// Prevents [AppOtpField.onChanged] from clearing [errorMessage] when we
  /// programmatically clear the PIN after an API error.
  bool _suppressPinFieldCallbacks = false;

  /// Used by [LoginPinScreen] — do not clear errors while resetting PIN fields.
  bool get ignorePinFieldCallbacks => _suppressPinFieldCallbacks;

  final pinController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      mode = _parseMode(args['mode']);
      _nextRoute = args['nextRoute']?.toString() ?? AppRoutes.home;
    } else if (args is LoginPinScreenMode) {
      mode = args;
    } else if (Get.currentRoute == AppRoutes.pinSetup) {
      mode = LoginPinScreenMode.setup;
    } else if (Get.currentRoute == AppRoutes.pinChange) {
      mode = LoginPinScreenMode.change;
    } else {
      mode = LoginPinScreenMode.login;
    }

    if (mode == LoginPinScreenMode.setup) {
      unawaited(analyticsService.logEvent('go_pin_setup_started'));
    }
    if (mode == LoginPinScreenMode.login) {
      unawaited(_loadLoginStatusForLoginMode());
    }
  }

  LoginPinScreenMode _parseMode(dynamic raw) {
    if (raw == 'setup') return LoginPinScreenMode.setup;
    if (raw == 'change') return LoginPinScreenMode.change;
    return LoginPinScreenMode.login;
  }

  @override
  void onClose() {
    _lockTimer?.cancel();
    pinController.dispose();
    super.onClose();
  }

  String titleFor({
    required LoginPinSetupStep setupStep,
    required LoginPinChangeStep changeStep,
  }) {
    switch (mode) {
      case LoginPinScreenMode.setup:
        return setupStep == LoginPinSetupStep.enter
            ? AppStrings.createLoginPinTitle.tr
            : AppStrings.confirmLoginPinTitle.tr;
      case LoginPinScreenMode.login:
        return AppStrings.enterLoginPinTitle.tr;
      case LoginPinScreenMode.change:
        switch (changeStep) {
          case LoginPinChangeStep.current:
            return AppStrings.enterCurrentLoginPin.tr;
          case LoginPinChangeStep.newPin:
            return AppStrings.enterNewLoginPin.tr;
          case LoginPinChangeStep.confirmNew:
            return AppStrings.confirmNewLoginPin.tr;
        }
    }
  }

  String subtitleFor({required String maskedPhone}) {
    switch (mode) {
      case LoginPinScreenMode.setup:
        return AppStrings.createLoginPinSubtitle.tr;
      case LoginPinScreenMode.login:
        return AppStrings.enterLoginPinMessage.tr;
      case LoginPinScreenMode.change:
        return subtitleForChange(changeStep: changeStep.value);
    }
  }

  String subtitleForChange({required LoginPinChangeStep changeStep}) {
    switch (changeStep) {
      case LoginPinChangeStep.current:
        return AppStrings.changeLoginPinCurrentSubtitle.tr;
      case LoginPinChangeStep.newPin:
        return AppStrings.changeLoginPinNewSubtitle.tr;
      case LoginPinChangeStep.confirmNew:
        return AppStrings.changeLoginPinConfirmSubtitle.tr;
    }
  }

  Future<String> maskedPhoneSubtitle() async {
    final mobile =
        await StorageService().read(StorageKeys.loginMobileNumber) ?? '';
    final countryCode =
        await StorageService().read(StorageKeys.loginCountryCode) ?? '+255';
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) {
      return countryCode;
    }
    final last3 = digits.substring(digits.length - 3);
    return '$countryCode *** *** $last3';
  }

  final maskedPhone = ''.obs;
  final displayName = ''.obs;

  String get notYouLabel {
    final name = displayName.value;
    if (name.isEmpty) return AppStrings.useDifferentAccount.tr;
    return AppStrings.notYouSignInWithOtp.trParams({'name': name});
  }

  @override
  void onReady() {
    super.onReady();
    if (mode == LoginPinScreenMode.login) {
      unawaited(_loadLoginContext());
    }
  }

  Future<void> _loadLoginContext() async {
    final userRaw = await StorageService().read(StorageKeys.user);
    if (userRaw != null && userRaw.isNotEmpty) {
      try {
        final user = UserModel.fromJson(
          jsonDecode(userRaw) as Map<String, dynamic>,
        );
        final name = user.name?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          displayName.value = name.split(' ').first;
        }
      } catch (_) {}
    }
    maskedPhone.value = await maskedPhoneSubtitle();
  }

  Future<void> _loadLoginStatusForLoginMode() async {
    biometricHardwareAvailable.value = await biometricService.isAvailable();

    final statusResult = await getLoginPinStatusUseCase();
    statusResult.fold((_) {}, (status) {
      biometricLoginEnabled.value = status.biometricEnabled;
      final until = status.lockedUntil;
      if (until != null && until.isAfter(DateTime.now())) {
        _startLockCountdown(until);
      }
    });
  }

  /// Face ID / fingerprint on login screen (no separate unlock route).
  Future<void> authenticateWithBiometric() async {
    if (!showBiometricUnlockButton ||
        isLoading.value ||
        isBiometricLoading.value) {
      return;
    }

    isBiometricLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    try {
      final ok = await biometricService.authenticate(
        localizedReason: AppStrings.unlockWithBiometric.tr,
      );
      if (!ok) return;

      final refreshed = await refreshLoginSessionUseCase();
      if (!refreshed) {
        hasError.value = true;
        errorMessage.value = AppStrings.sessionExpiredPleaseLoginAgain.tr;
        AppDialogs.showErrorDialog(
          message: AppStrings.sessionExpiredPleaseLoginAgain.tr,
        );
        return;
      }

      unawaited(analyticsService.logEvent('go_biometric_login_success'));
      await _navigateAfterSuccessfulLogin();
    } finally {
      isBiometricLoading.value = false;
    }
  }

  Future<void> _navigateAfterSuccessfulLogin() async {
    await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
    final signupCompleted =
        await StorageService().read(StorageKeys.signupCompleted);
    if (signupCompleted == 'false') {
      Get.offAllNamed(AppRoutes.phone);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void _startLockCountdown(DateTime until) {
    isInputDisabled.value = true;
    errorMessage.value = '';
    void tick() {
      final remaining = until.difference(DateTime.now());
      if (remaining.isNegative) {
        _lockTimer?.cancel();
        isInputDisabled.value = false;
        lockCountdownLabel.value = '';
        hasError.value = false;
        return;
      }
      final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      lockCountdownLabel.value = AppStrings.pinLockedTryAgainIn.trParams({
        'time': '$minutes:$seconds',
      });
    }

    tick();
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void clearPinInput() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
    }
    _suppressPinFieldCallbacks = true;
    pinController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressPinFieldCallbacks = false;
    });
    hasError.value = false;
    errorMessage.value = '';
  }

  void _clearPinInputSilently() {
    _suppressPinFieldCallbacks = true;
    pinController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressPinFieldCallbacks = false;
    });
  }

  /// Shows API/validation error under the PIN field and clears digits for retry.
  void _showPinError(String message) {
    hasError.value = true;
    errorMessage.value = message;
    _clearPinInputSilently();
  }

  /// Called when all 4 digits entered — branches by [mode] and setup/change step.
  Future<void> onPinCompleted(String pin) async {
    if (isLoading.value || isInputDisabled.value) return;

    if (!LoginPinValidator.isValidFormat(pin)) {
      _showPinError(AppStrings.pinMustBeExactly4Digits.tr);
      return;
    }

    switch (mode) {
      case LoginPinScreenMode.setup:
        await _handleSetupPin(pin);
      case LoginPinScreenMode.login:
        await _handleLoginPin(pin);
      case LoginPinScreenMode.change:
        await _handleChangePin(pin);
    }
  }

  Future<void> _handleSetupPin(String pin) async {
    if (setupStep.value == LoginPinSetupStep.enter) {
      _firstPin = pin;
      setupStep.value = LoginPinSetupStep.confirm;
      clearPinInput();
      return;
    }

    if (pin != _firstPin) {
      setupStep.value = LoginPinSetupStep.enter;
      _firstPin = '';
      _showPinError(AppStrings.pinsDoNotMatch.tr);
      return;
    }

    isLoading.value = true;
    final result = await setupLoginPinUseCase(_firstPin);
    isLoading.value = false;

    result.fold(
      (failure) {
        if (_handlePinApiFailure(failure, forSetup: true)) {
          unawaited(
            analyticsService.logEvent(
              'go_pin_setup_failed',
              parameters: {
                'error_code':
                    failure is LoginPinFailure ? failure.errorCode : null,
              },
            ),
          );
          return;
        }
        setupStep.value = LoginPinSetupStep.enter;
        _firstPin = '';
        _showPinError(failure.message);
        unawaited(
          analyticsService.logEvent(
            'go_pin_setup_failed',
            parameters: {
              'error_code':
                  failure is LoginPinFailure ? failure.errorCode : null,
            },
          ),
        );
      },
      (_) async {
        unawaited(analyticsService.logEvent('go_pin_setup_success'));
        Get.offAllNamed(_nextRoute);
      },
    );
  }

  Future<void> _handleLoginPin(String pin) async {
    isLoading.value = true;
    unawaited(analyticsService.logEvent('go_pin_login_attempt'));
    final result = await verifyLoginPinUseCase(pin);
    isLoading.value = false;

    result.fold(
      (failure) {
        if (_handlePinApiFailure(failure)) return;
        _showPinError(failure.message);
      },
      (_) async {
        unawaited(analyticsService.logEvent('go_pin_login_success'));
        await _navigateAfterSuccessfulLogin();
      },
    );
  }

  Future<void> _handleChangePin(String pin) async {
    switch (changeStep.value) {
      case LoginPinChangeStep.current:
        _firstPin = pin;
        changeStep.value = LoginPinChangeStep.newPin;
        clearPinInput();
      case LoginPinChangeStep.newPin:
        _newPinCandidate = pin;
        changeStep.value = LoginPinChangeStep.confirmNew;
        clearPinInput();
      case LoginPinChangeStep.confirmNew:
        await _submitChangePin(pin);
    }
  }

  Future<void> _submitChangePin(String pin) async {
    if (pin != _newPinCandidate) {
      changeStep.value = LoginPinChangeStep.newPin;
      _newPinCandidate = '';
      _showPinError(AppStrings.pinsDoNotMatch.tr);
      return;
    }

    isLoading.value = true;
    final result = await changeLoginPinUseCase(
      oldPin: _firstPin,
      newPin: _newPinCandidate,
    );
    isLoading.value = false;

    result.fold(
      (failure) {
        if (_handlePinApiFailure(failure, forChangePin: true)) return;
        changeStep.value = LoginPinChangeStep.current;
        _firstPin = '';
        _newPinCandidate = '';
        _showPinError(failure.message);
      },
      (_) {
        AppDialogs.showSuccessDialog(
          message: AppStrings.loginPinChangedSuccessfully.tr,
          onConfirm: () => Get.back(),
        );
      },
    );
  }

  String _incorrectPinMessage(LoginPinFailure failure) {
    final left = failure.attemptsRemaining;
    if (left == 1) return AppStrings.pinIncorrectOneAttemptLeft.tr;
    if (left != null && left > 0) {
      return AppStrings.pinIncorrectAttemptsLeft.trParams({
        'count': '$left',
      });
    }
    if (failure.message.isNotEmpty) return failure.message;
    return AppStrings.incorrectPin.tr;
  }

  void _applyPinLock({DateTime? until}) {
    isInputDisabled.value = true;
    if (until != null && until.isAfter(DateTime.now())) {
      _startLockCountdown(until);
    } else {
      lockCountdownLabel.value = '';
      _showPinError(AppStrings.pinLocked.tr);
    }
  }

  /// Maps server `error_code` (e.g. AUTH_PIN_LOCKED) to banner / lock countdown.
  bool _handlePinApiFailure(
    Failure failure, {
    bool forSetup = false,
    bool forChangePin = false,
  }) {
    if (failure is! LoginPinFailure) return false;

    switch (failure.errorCode) {
      case 'AUTH_PIN_NOT_SET':
        _showPinError(failure.message);
        return true;
      case 'AUTH_USER_BLOCKED':
        isInputDisabled.value = true;
        _showPinError(
          AppStrings.accountUnavailablePleaseContactSupport.tr,
        );
        return true;
      case 'AUTH_PIN_LOCKED':
        unawaited(analyticsService.logEvent('go_pin_locked'));
        if (forChangePin) {
          changeStep.value = LoginPinChangeStep.current;
          _firstPin = '';
          _newPinCandidate = '';
        }
        _applyPinLock(until: failure.lockedUntil);
        _clearPinInputSilently();
        return true;
      case 'AUTH_PIN_INCORRECT':
        final left = failure.attemptsRemaining;
        if (left != null && left <= 0) {
          unawaited(analyticsService.logEvent('go_pin_locked'));
          if (forChangePin) {
            changeStep.value = LoginPinChangeStep.current;
            _firstPin = '';
            _newPinCandidate = '';
          }
          _applyPinLock(until: failure.lockedUntil);
          _clearPinInputSilently();
          return true;
        }
        if (forChangePin) {
          changeStep.value = LoginPinChangeStep.current;
          _firstPin = '';
          _newPinCandidate = '';
        }
        _showPinError(_incorrectPinMessage(failure));
        return true;
      case 'AUTH_PIN_INVALID_FORMAT':
      case 'AUTH_PIN_TOO_WEAK':
        if (forSetup) {
          setupStep.value = LoginPinSetupStep.enter;
          _firstPin = '';
        }
        if (forChangePin) {
          changeStep.value = LoginPinChangeStep.newPin;
          _newPinCandidate = '';
        }
        _showPinError(failure.message);
        return true;
      case 'AUTH_PIN_ALREADY_SET':
        if (forSetup) {
          AppDialogs.showErrorDialog(
            message: failure.message,
            onConfirm: () => Get.offNamed(
              AppRoutes.pinChange,
              arguments: {'mode': 'change'},
            ),
          );
          return true;
        }
        return false;
      default:
        return false;
    }
  }

  /// Clears login PIN via OTP re-auth ([StorageKeys.forgotLoginPinPending]).
  void openForgotPin() {
    unawaited(analyticsService.logEvent('go_forgot_pin_used'));
    unawaited(
      StorageService().write(StorageKeys.forgotLoginPinPending, 'true'),
    );
    Get.offAllNamed(AppRoutes.phone);
  }

  /// Clears stored session and starts OTP sign-in (not onboarding carousel).
  Future<void> useDifferentAccount() async {
    await StorageService().deleteAll();
    Get.offAllNamed(AppRoutes.phone);
  }

  void goBackOnSetup() {
    if (mode == LoginPinScreenMode.setup &&
        setupStep.value == LoginPinSetupStep.confirm) {
      setupStep.value = LoginPinSetupStep.enter;
      _firstPin = '';
      clearPinInput();
    } else if (Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  /// Back on change-PIN: step back within flow, or pop settings on current step.
  void goBackOnChangePin() {
    switch (changeStep.value) {
      case LoginPinChangeStep.confirmNew:
        changeStep.value = LoginPinChangeStep.newPin;
        _newPinCandidate = '';
        clearPinInput();
      case LoginPinChangeStep.newPin:
        changeStep.value = LoginPinChangeStep.current;
        _newPinCandidate = '';
        clearPinInput();
      case LoginPinChangeStep.current:
        if (Get.key.currentState?.canPop() == true) {
          Get.back();
        }
    }
  }
}
