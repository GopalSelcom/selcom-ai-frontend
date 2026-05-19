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
/// - **login:** `VerifyLoginPinUseCase` → refresh tokens → home or phone (signup incomplete).
/// - **change:** current → new → confirm → `ChangeLoginPinUseCase` → success dialog.
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
  });

  final SetupLoginPinUseCase setupLoginPinUseCase;
  final VerifyLoginPinUseCase verifyLoginPinUseCase;
  final ChangeLoginPinUseCase changeLoginPinUseCase;
  final GetLoginPinStatusUseCase getLoginPinStatusUseCase;
  final DeleteLoginPinUseCase deleteLoginPinUseCase;
  final LoginPinGateService loginPinGateService;
  final AnalyticsService analyticsService;

  late final LoginPinScreenMode mode;
  String _nextRoute = AppRoutes.home;

  final setupStep = LoginPinSetupStep.enter.obs;
  final changeStep = LoginPinChangeStep.current.obs;
  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final isInputDisabled = false.obs;
  final lockCountdownLabel = ''.obs;

  String _firstPin = '';
  String _newPinCandidate = '';
  Timer? _lockTimer;

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
      unawaited(_loadLockState());
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
        if (maskedPhone.isEmpty) return AppStrings.enterLoginPinTitle.tr;
        return AppStrings.enterLoginPinSubtitle.trParams({
          'maskedPhone': maskedPhone,
        });
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

  Future<void> _loadLockState() async {
    final statusResult = await getLoginPinStatusUseCase();
    statusResult.fold((_) {}, (status) {
      final until = status.lockedUntil;
      if (until != null && until.isAfter(DateTime.now())) {
        _startLockCountdown(until);
      }
    });
  }

  void _startLockCountdown(DateTime until) {
    isInputDisabled.value = true;
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
    pinController.clear();
    hasError.value = false;
    errorMessage.value = '';
  }

  void _resetPinField() {
    pinController.clear();
    hasError.value = false;
  }

  /// Called when all 4 digits entered — branches by [mode] and setup/change step.
  Future<void> onPinCompleted(String pin) async {
    if (isLoading.value || isInputDisabled.value) return;

    if (!LoginPinValidator.isValidFormat(pin)) {
      hasError.value = true;
      errorMessage.value = AppStrings.pinMustBeExactly4Digits.tr;
      _resetPinField();
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
      hasError.value = true;
      errorMessage.value = AppStrings.pinsDoNotMatch.tr;
      setupStep.value = LoginPinSetupStep.enter;
      _firstPin = '';
      _resetPinField();
      return;
    }

    isLoading.value = true;
    final result = await setupLoginPinUseCase(_firstPin);
    isLoading.value = false;

    result.fold(
      (failure) {
        hasError.value = true;
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
        errorMessage.value = failure.message;
        unawaited(
          analyticsService.logEvent(
            'go_pin_setup_failed',
            parameters: {
              'error_code':
                  failure is LoginPinFailure ? failure.errorCode : null,
            },
          ),
        );
        setupStep.value = LoginPinSetupStep.enter;
        _firstPin = '';
        _resetPinField();
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
      (failure) async {
        hasError.value = true;
        if (_handlePinApiFailure(failure)) return;
        errorMessage.value = failure.message;
        _resetPinField();
      },
      (_) async {
        unawaited(analyticsService.logEvent('go_pin_login_success'));
        await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
        final signupCompleted =
            await StorageService().read(StorageKeys.signupCompleted);
        if (signupCompleted == 'false') {
          Get.offAllNamed(AppRoutes.phone);
        } else {
          Get.offAllNamed(AppRoutes.home);
        }
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
        if (pin != _newPinCandidate) {
          hasError.value = true;
          errorMessage.value = AppStrings.pinsDoNotMatch.tr;
          changeStep.value = LoginPinChangeStep.newPin;
          _newPinCandidate = '';
          _resetPinField();
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
            hasError.value = true;
            if (_handlePinApiFailure(failure, forChangePin: true)) return;
            errorMessage.value = failure.message;
            changeStep.value = LoginPinChangeStep.current;
            _firstPin = '';
            _newPinCandidate = '';
            _resetPinField();
          },
          (_) {
            AppDialogs.showSuccessDialog(
              message: AppStrings.loginPinChangedSuccessfully.tr,
              onConfirm: () => Get.back(),
            );
          },
        );
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
        errorMessage.value = failure.message;
        _resetPinField();
        return true;
      case 'AUTH_USER_BLOCKED':
        errorMessage.value =
            AppStrings.accountUnavailablePleaseContactSupport.tr;
        isInputDisabled.value = true;
        _resetPinField();
        return true;
      case 'AUTH_PIN_LOCKED':
        unawaited(analyticsService.logEvent('go_pin_locked'));
        if (failure.lockedUntil != null) {
          _startLockCountdown(failure.lockedUntil!);
        } else {
          isInputDisabled.value = true;
        }
        errorMessage.value = failure.message;
        _resetPinField();
        return true;
      case 'AUTH_PIN_INCORRECT':
        final left = failure.attemptsRemaining;
        if (left != null) {
          final tries = left == 1 ? 'try' : 'tries';
          errorMessage.value = AppStrings.pinIncorrectAttemptsLeft.trParams({
            'count': '$left',
            'tries': tries,
          });
        } else {
          errorMessage.value = failure.message;
        }
        if (forChangePin) {
          changeStep.value = LoginPinChangeStep.current;
          _firstPin = '';
          _newPinCandidate = '';
        }
        _resetPinField();
        return true;
      case 'AUTH_PIN_INVALID_FORMAT':
      case 'AUTH_PIN_TOO_WEAK':
        errorMessage.value = failure.message;
        if (forSetup) {
          setupStep.value = LoginPinSetupStep.enter;
          _firstPin = '';
        }
        if (forChangePin) {
          changeStep.value = LoginPinChangeStep.newPin;
          _newPinCandidate = '';
        }
        _resetPinField();
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

  Future<void> useDifferentAccount() async {
    await StorageService().deleteAll();
    Get.offAllNamed(AppRoutes.onboarding);
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
