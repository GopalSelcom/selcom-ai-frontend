import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/apple_sign_in_debug_log.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../domain/usecases/resend_otp_use_case.dart';
import '../../domain/usecases/send_otp_use_case.dart';
import '../../domain/usecases/sign_in_with_apple_use_case.dart';
import '../../domain/usecases/verify_otp_use_case.dart';

class AuthController extends GetxController {
  AuthController({
    required this.sendOtpUseCase,
    required this.resendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.signInWithAppleUseCase,
    required this.appRegionService,
    required this.googleSignInService,
  });

  final SendOtpUseCase sendOtpUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final AppRegionService appRegionService;
  final GoogleSignInService googleSignInService;

  final mobileNumber = ''.obs;
  final countryCode = '+255'.obs;
  final selectedCountryIso = 'TZ'.obs;
  final phoneFieldResetVersion = 0.obs;
  final otp = ''.obs;
  final generatedOtp = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final resendTimer = 59.obs;
  final pendingSignUpName = ''.obs;
  final pendingSignUpEmail = ''.obs;
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
    if (isLoading.value) return false;
    errorMessage.value = '';

    return Loader.withFlag(isLoading, () async {
      final result = await sendOtpUseCase(
        SendOtpRequest(
          mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
          countryCode: countryCode.value.replaceAll('+', ''),
        ),
      );

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
    });
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
    if (isLoading.value) return false;
    errorMessage.value = '';

    // Start timer immediately for better user feedback
    startResendTimer();

    return Loader.withFlag(isLoading, () async {
      final result = await resendOtpUseCase(
        SendOtpRequest(
          mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
          countryCode: countryCode.value.replaceAll('+', ''),
        ),
      );

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
            resendTimer.value =
                0; // Show resend button again if API specifically failed
            generatedOtp.value = '';
            return false;
          }
        },
      );
    });
  }

  Future<bool> verifyOtp() async {
    if (isLoading.value) return false;
    errorMessage.value = '';

    String? postVerifyRoute;

    final verified = await Loader.withFlag(isLoading, () async {
      final result = await verifyOtpUseCase(
        VerifyOtpRequest(
          mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
          countryCode: countryCode.value.replaceAll('+', ''),
          otp: otp.value,
        ),
      );

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
            final walletNotCreated = verifyData.isWalletNotCreated;
            final needsSignUp = !isUserAlreadyRegistered || walletNotCreated;

            pendingSignUpName.value = verifyData.signUpName;
            pendingSignUpEmail.value = verifyData.signUpEmail;

            await StorageService().write(
              StorageKeys.signupCompleted,
              needsSignUp ? 'false' : 'true',
            );

            await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
            SessionExpiryService.resetOnLogin();

            postVerifyRoute = needsSignUp
                ? AppRoutes.signUp
                : AppRoutes.profileLoading;
            return true;
          }
          errorMessage.value =
              response?.message ?? AppStrings.otpVerificationFailed.tr;
          return false;
        },
      );
    });

    if (!verified || postVerifyRoute == null) return false;

    if (postVerifyRoute == AppRoutes.profileLoading) {
      Get.offAllNamed(AppRoutes.profileLoading);
    } else {
      Get.offNamed(postVerifyRoute!);
    }
    return true;
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

  Future<void> signInWithGoogle() async {
    if (isLoading.value) return;
    errorMessage.value = '';

    await Loader.withFlag(isLoading, () async {
      try {
        final account = await googleSignInService.signIn();
        final email = account.email.trim();

        if (email.isEmpty) {
          errorMessage.value = AppStrings.googleSignInFailed.tr;
          return;
        }

        // TODO: call backend Google-auth API with id token when available.

        Get.snackbar(
          AppStrings.accountVerified.tr,
          AppStrings.googleSignInSuccess.trParams({'email': email}),
        );
      } on GoogleSignInServiceException catch (e) {
        switch (e.type) {
          case GoogleSignInErrorType.canceled:
            errorMessage.value = AppStrings.googleSignInCancelled.tr;
          case GoogleSignInErrorType.configurationError:
            errorMessage.value = AppStrings.googleSignInConfigError.tr;
          case GoogleSignInErrorType.unsupported:
            errorMessage.value = AppStrings.googleSignInUnsupported.tr;
          case GoogleSignInErrorType.other:
            errorMessage.value = AppStrings.googleSignInFailed.tr;
        }
      } catch (_) {
        errorMessage.value = AppStrings.googleSignInFailed.tr;
      }
    });
  }

  Future<void> signInWithApple() async {
    if (isLoading.value) return;
    errorMessage.value = '';

    await Loader.withFlag(isLoading, () async {
      appleSignInDebugLog('controller_sign_in_started');
      final result = await signInWithAppleUseCase(NoParams());

      result.fold(
        (failure) {
          if (failure is AppleSignInFailure && failure.isCancelled) {
            appleSignInDebugLog(
              'controller_failed',
              metadata: {'reason': 'cancelled'},
            );
            errorMessage.value = AppStrings.appleSignInCancelled.tr;
            return;
          }
          if (failure is AccountLinkingFailure) {
            appleSignInDebugLog(
              'controller_failed',
              metadata: {'reason': 'account_linking'},
            );
            errorMessage.value = AppStrings.appleSignInAccountExists.tr;
            return;
          }
          if (failure is NetworkFailure) {
            appleSignInDebugLog(
              'controller_failed',
              metadata: {'reason': 'network'},
            );
            errorMessage.value = failure.message;
            return;
          }
          if (failure is FirebaseAuthFailure) {
            appleSignInDebugLog(
              'controller_failed',
              metadata: {
                'reason': 'firebase_auth_failure',
                'firebaseCode': failure.code ?? 'unknown',
              },
            );
          } else if (failure is AppleSignInFailure) {
            appleSignInDebugLog(
              'controller_failed',
              metadata: {'reason': 'apple_sign_in_failure'},
            );
          } else {
            appleSignInDebugLog(
              'controller_failed',
              metadata: {
                'reason': 'other_failure',
                'failureType': failure.runtimeType.toString(),
              },
            );
          }
          errorMessage.value = AppStrings.appleSignInFailed.tr;
        },
        (user) {
          final email = user.email?.trim() ?? '';
          if (email.isEmpty) {
            appleSignInDebugLog(
              'controller_failed',
              metadata: {
                'reason': 'empty_email_after_success',
                'hasDisplayName': (user.displayName?.trim().isNotEmpty ?? false),
                'isNewUser': user.isNewUser,
              },
            );
            errorMessage.value = AppStrings.appleSignInFailed.tr;
            return;
          }

          appleSignInDebugLog(
            'controller_sign_in_succeeded',
            metadata: {
              'hasDisplayName': (user.displayName?.trim().isNotEmpty ?? false),
              'isNewUser': user.isNewUser,
            },
          );

          // TODO: exchange Firebase ID token with Selcom backend when API exists.

          Get.snackbar(
            AppStrings.accountVerified.tr,
            AppStrings.appleSignInSuccess.trParams({'email': email}),
          );
        },
      );
    });
  }
}
