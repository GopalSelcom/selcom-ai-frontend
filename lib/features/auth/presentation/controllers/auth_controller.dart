import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/login_pin_gate_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/usecases/login_pin_usecases.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../domain/usecases/resend_otp_use_case.dart';
import '../../domain/usecases/send_otp_use_case.dart';
import '../../domain/usecases/verify_otp_use_case.dart';

class AuthController extends GetxController {
  AuthController({
    required this.sendOtpUseCase,
    required this.resendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.appRegionService,
  });

  final SendOtpUseCase sendOtpUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final AppRegionService appRegionService;

  final mobileNumber = ''.obs;
  final countryCode = '+255'.obs;
  final selectedCountryIso = 'TZ'.obs;
  final phoneFieldResetVersion = 0.obs;
  final otp = ''.obs;
  final generatedOtp = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final resendTimer = 59.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    final c = appRegionService.selected;
    selectedCountryIso.value = c.code.toUpperCase();
    countryCode.value = c.dialCode;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startResendTimer() {
    _timer?.cancel();
    resendTimer.value = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> sendOtp() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await sendOtpUseCase(
      SendOtpRequest(
        mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
        countryCode: countryCode.value.replaceAll('+', ''),
      ),
    );

    isLoading.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        generatedOtp.value = '';
        return false;
      },
      (response) {
        if (response?.isSuccess == true) {
          generatedOtp.value = response?.response?.otp ?? '';
          return true;
        } else {
          errorMessage.value =
              response?.message ?? AppStrings.failedToSendOtp.tr;
          generatedOtp.value = '';
          return false;
        }
      },
    );
  }

  Future<void> sendOtpAndNavigate() async {
    final success = await sendOtp();
    if (!success) return;
    startResendTimer();
    Get.toNamed(AppRoutes.otp);
  }

  bool get canRequestOtp =>
      PhoneNationalRules.isCompleteValidNational(
        selectedCountryIso.value,
        mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
      ) &&
      !isLoading.value;

  void onPhoneCountrySelected(CountryData country) {
    if (country.code == selectedCountryIso.value) return;
    applyPhoneCountry(country);
  }

  Future<void> applyPhoneCountry(CountryData country) async {
    await appRegionService.setSelectedCountry(country);
    selectedCountryIso.value = country.code.toUpperCase();
    countryCode.value = country.dialCode;
    mobileNumber.value = '';
    phoneFieldResetVersion.value++;
  }

  bool get shouldShowGeneratedOtp =>
      AppConfig.environment == Environment.dev ||
      AppConfig.environment == Environment.staging;

  Future<bool> resendOtp() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    // Start timer immediately for better user feedback
    startResendTimer();

    final result = await resendOtpUseCase(
      SendOtpRequest(
        mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
        countryCode: countryCode.value.replaceAll('+', ''),
      ),
    );

    isLoading.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        generatedOtp.value = '';
        // If it failed, we might want to stop the timer, but usually keeping it 
        // prevents spamming. If you want to allow retry immediately on error:
        // resendTimer.value = 0;
        return false;
      },
      (response) {
        if (response?.isSuccess == true) {
          generatedOtp.value = response?.response?.otp ?? '';
          return true;
        } else {
          errorMessage.value =
              response?.message ?? AppStrings.failedToResendOtp.tr;
          resendTimer.value = 0; // Show resend button again if API specifically failed
          generatedOtp.value = '';
          return false;
        }
      },
    );
  }

  Future<bool> verifyOtp() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await verifyOtpUseCase(
      VerifyOtpRequest(
        mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
        countryCode: countryCode.value.replaceAll('+', ''),
        otp: otp.value,
      ),
    );

    isLoading.value = false;

    return await result.fold(
      (failure) async {
        errorMessage.value = failure.message;
        return false;
      },
      (response) async {
        if (response?.isSuccess == true && response?.response != null) {
          final verifyData = response!.response!;

          if (verifyData.accessToken != null) {
            await StorageService().write(
              StorageKeys.authorizationToken,
              verifyData.accessToken!,
            );
            await StorageService().write(
              StorageKeys.accessToken,
              verifyData.accessToken!,
            );
          }
          if (verifyData.refreshToken != null) {
            await StorageService().write(
              StorageKeys.refreshToken,
              verifyData.refreshToken!,
            );
          }

          await StorageService().write(
            StorageKeys.user,
            jsonEncode(verifyData.user!.toJson()),
          );

          final isUserAlreadyRegistered =
              verifyData.isUserAlreadyRegistered == true;
          await StorageService().write(
            StorageKeys.signupCompleted,
            isUserAlreadyRegistered ? 'true' : 'false',
          );

          await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();

          await sl<LoginPinGateService>().saveLoginIdentity(
            mobileNumber: mobileNumber.value,
            countryCode: countryCode.value,
          );

          // App login PIN after OTP: forgot → delete PIN + pin-setup; else resolvePostAuthRoute.
          final forgotPending = await StorageService().read(
            StorageKeys.forgotLoginPinPending,
          );
          if (forgotPending == 'true') {
            await StorageService().delete(StorageKeys.forgotLoginPinPending);
            await sl<DeleteLoginPinUseCase>().call();
            await _navigateAfterOtp(AppRoutes.pinSetup, arguments: {
              'mode': 'setup',
              'nextRoute': AppRoutes.home,
            });
            return true;
          }

          if (isUserAlreadyRegistered) {
            final nextRoute = await sl<LoginPinGateService>().resolvePostAuthRoute(
              defaultRoute: AppRoutes.profileLoading,
            );
            if (nextRoute == AppRoutes.pinSetup) {
              await _navigateAfterOtp(AppRoutes.pinSetup, arguments: {
                'mode': 'setup',
                'nextRoute': AppRoutes.profileLoading,
              });
            } else {
              await _navigateAfterOtp(AppRoutes.profileLoading);
            }
          } else {
            Get.offNamed(AppRoutes.signUp);
          }
          return true;
        } else {
          errorMessage.value =
              response?.message ?? AppStrings.otpVerificationFailed.tr;
          return false;
        }
      },
    );
  }

  void onOtpChanged(String value) {
    otp.value = value;
    if (errorMessage.isNotEmpty) {
      errorMessage.value = '';
    }
  }

  void completeProfileLoading() {
    Get.offAllNamed(AppRoutes.home);
  }

  /// Unfocuses OTP field then navigates — avoids [AppOtpField] dispose races on offAll.
  Future<void> _navigateAfterOtp(
    String route, {
    Object? arguments,
  }) async {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
    }
    await Future<void>.delayed(Duration.zero);
    Get.offAllNamed(route, arguments: arguments);
  }
}
