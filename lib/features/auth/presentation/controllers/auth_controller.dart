import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/data/models/requests/go_phone_otp_request.dart';
import '../../../../core/data/models/requests/set_name_request.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/requests/go_phone_verify_otp_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_region_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/apple_sign_in_debug_log.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../domain/entities/social_auth_user.dart';
import '../../domain/usecases/exchange_firebase_session_use_case.dart';
import '../../domain/usecases/resend_phone_otp_use_case.dart';
import '../../domain/usecases/send_phone_otp_use_case.dart';
import '../../domain/usecases/set_name_use_case.dart';
import '../../domain/usecases/sign_in_with_apple_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_in_with_facebook_use_case.dart';
import '../../domain/usecases/verify_phone_otp_use_case.dart';

class AuthController extends GetxController {
  AuthController({
    required this.sendPhoneOtpUseCase,
    required this.resendPhoneOtpUseCase,
    required this.verifyPhoneOtpUseCase,
    required this.setNameUseCase,
    required this.signInWithAppleUseCase,
    required this.signInWithFacebookUseCase,
    required this.signInWithGoogleUseCase,
    required this.exchangeFirebaseSessionUseCase,
    required this.appRegionService,
  });

  final SendPhoneOtpUseCase sendPhoneOtpUseCase;
  final ResendPhoneOtpUseCase resendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase verifyPhoneOtpUseCase;
  final SetNameUseCase setNameUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final SignInWithFacebookUseCase signInWithFacebookUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final ExchangeFirebaseSessionUseCase exchangeFirebaseSessionUseCase;
  final AppRegionService appRegionService;

  final mobileNumber = ''.obs;
  /// Name typed on the phone screen when [needsName] is true.
  final userName = ''.obs;
  final countryCode = '+255'.obs;
  final selectedCountryIso = 'TZ'.obs;
  final phoneFieldResetVersion = 0.obs;
  final otp = ''.obs;
  final generatedOtp = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isPhoneAttachFlow = false.obs;
  /// Set from firebase_login `needs_name`, or inferred on resume when stored
  /// user has no name (e.g. Apple private relay / Google without display name).
  final needsName = false.obs;

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
  void onReady() {
    super.onReady();
    unawaited(_configurePhoneAttachMode());
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

  GoPhoneOtpRequest get _goPhoneOtpRequest => GoPhoneOtpRequest(
    mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
    countryCode: countryCode.value,
  );

  Future<bool> sendOtp() async {
    if (isLoading.value) return false;
    errorMessage.value = '';

    return Loader.withFlag(isLoading, () async {
      final result = await sendPhoneOtpUseCase(_goPhoneOtpRequest);
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
          }
          errorMessage.value =
              response?.message ?? AppStrings.failedToSendOtp.tr;
          generatedOtp.value = '';
          return false;
        },
      );
    });
  }

  Future<void> sendOtpAndNavigate() async {
    // SSO users missing a name must save it before phone OTP (set_name → send_otp).
    if (needsName.value) {
      final nameSaved = await setName();
      if (!nameSaved) return;
    }

    final success = await sendOtp();
    if (!success) return;
    startResendTimer();
    Get.toNamed(AppRoutes.otp);
  }

  static const int _nameMinLength = 1;
  static const int _nameMaxLength = 120; // Matches POST /go/auth/set_name contract.

  bool get _isUserNameValid {
    final value = userName.value.trim();
    return value.length >= _nameMinLength && value.length <= _nameMaxLength;
  }

  void onUserNameChanged(String value) {
    userName.value = value;
    if (errorMessage.isNotEmpty) {
      errorMessage.value = '';
    }
  }

  /// Calls `POST /go/auth/set_name` with the firebase_login access token.
  Future<bool> setName() async {
    if (isLoading.value) return false;
    errorMessage.value = '';

    final trimmedName = userName.value.trim();
    if (trimmedName.length < _nameMinLength) {
      errorMessage.value = AppStrings.nameIsRequired.tr;
      return false;
    }
    if (trimmedName.length > _nameMaxLength) {
      errorMessage.value = AppStrings.pleaseEnterAValidName.tr;
      return false;
    }

    return Loader.withFlag(isLoading, () async {
      final result = await setNameUseCase(SetNameRequest(name: trimmedName));
      return await result.fold(
        (failure) async {
          errorMessage.value = failure.message;
          return false;
        },
        (response) async {
          if (response?.isSuccess != true) {
            errorMessage.value =
                response?.message ??
                AppStrings.somethingWentWrongPleaseTryAgain.tr;
            return false;
          }

          final savedName =
              response?.user?.name?.trim().isNotEmpty == true
              ? response!.user!.name!.trim()
              : trimmedName;
          await _mergeNameIntoStoredUser(savedName);

          needsName.value = false;
          pendingSignUpName.value = savedName;
          return true;
        },
      );
    });
  }

  /// `set_name` returns a partial user (`_id`, `name` only) — patch name locally.
  Future<void> _mergeNameIntoStoredUser(String name) async {
    final raw = await StorageService().read(StorageKeys.user);
    if (raw == null || raw.trim().isEmpty) return;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    map['name'] = name;
    await StorageService().write(StorageKeys.user, jsonEncode(map));
  }

  bool get canRequestOtp {
    final phoneValid = PhoneNationalRules.isCompleteValidNational(
      selectedCountryIso.value,
      mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
    );
    // When needsName, block Continue until name length is valid (1–120).
    final nameValid = !needsName.value || _isUserNameValid;
    return phoneValid && nameValid && !isLoading.value;
  }

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

  bool get shouldShowGeneratedOtp => AppConfig.environment.isDevOrStaging;

  Future<bool> resendOtp() async {
    if (isLoading.value) return false;
    errorMessage.value = '';

    startResendTimer();

    return Loader.withFlag(isLoading, () async {
      final result = await resendPhoneOtpUseCase(_goPhoneOtpRequest);
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
          }
          errorMessage.value =
              response?.message ?? AppStrings.failedToResendOtp.tr;
          resendTimer.value = 0;
          generatedOtp.value = '';
          return false;
        },
      );
    });
  }

  Future<bool> verifyOtp() async {
    if (isLoading.value) return false;
    errorMessage.value = '';

    String? postVerifyRoute;

    final verified = await Loader.withFlag(isLoading, () async {
      final result = await verifyPhoneOtpUseCase(
        GoPhoneVerifyOtpRequest(
          mobileNumber: mobileNumber.value.replaceAll(RegExp(r'\D'), ''),
          countryCode: countryCode.value,
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
            postVerifyRoute = await _persistLoginSession(response!);
            return postVerifyRoute != null;
          }
          errorMessage.value =
              response?.message ?? AppStrings.otpVerificationFailed.tr;
          return false;
        },
      );
    });

    if (!verified || postVerifyRoute == null) return false;

    _navigateAfterAuth(postVerifyRoute!);
    return true;
  }

  static bool userNeedsPhone(String? userJson) {
    if (userJson == null || userJson.trim().isEmpty) return true;
    try {
      final user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      return user.isVerify != 1 ||
          user.mobileNumber == null ||
          user.mobileNumber == 0;
    } catch (_) {
      return true;
    }
  }

  Future<void> _configurePhoneAttachMode() async {
    final token = await StorageService().readAccessToken();
    isPhoneAttachFlow.value = token != null && token.isNotEmpty;

    if (!isPhoneAttachFlow.value) return;

    // App relaunch after firebase_login: re-show name field if profile has no name.
    final userJson = await StorageService().read(StorageKeys.user);
    if (userJson == null || userJson.trim().isEmpty) return;

    try {
      final user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      needsName.value = user.name == null || user.name!.trim().isEmpty;
    } catch (_) {
      needsName.value = true;
    }
  }

  void _navigateAfterAuth(String route) {
    if (route == AppRoutes.phone) {
      Get.offAllNamed(AppRoutes.phone);
      return;
    }
    if (route == AppRoutes.profileLoading) {
      Get.offAllNamed(AppRoutes.profileLoading);
      return;
    }
    Get.offAllNamed(route);
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

  void openContactSupport() {
    Get.toNamed(AppRoutes.loginSupport);
  }

  Future<void> signInWithGoogle() async {
    if (isLoading.value) return;
    errorMessage.value = '';

    await Loader.withFlag(isLoading, () async {
      final signInResult = await signInWithGoogleUseCase(NoParams());
      await signInResult.fold(
        (failure) async {
          if (failure is AppleSignInFailure && failure.isCancelled) {
            errorMessage.value = AppStrings.googleSignInCancelled.tr;
            return;
          }
          errorMessage.value = failure.message.isNotEmpty
              ? failure.message
              : AppStrings.googleSignInFailed.tr;
        },
        (user) => _completeSocialSignIn(user),
      );
    });
  }

  Future<void> signInWithApple() async {
    if (isLoading.value) return;
    errorMessage.value = '';

    await Loader.withFlag(isLoading, () async {
      appleSignInDebugLog('controller_sign_in_started');
      final result = await signInWithAppleUseCase(NoParams());

      await result.fold(
        (failure) async {
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
        (user) => _completeSocialSignIn(user),
      );
    });
  }

  Future<void> _completeSocialSignIn(SocialAuthUser user) async {
    appleSignInDebugLog(
      'controller_exchange_firebase_session_started',
      metadata: {
        'hasDisplayName': (user.displayName?.trim().isNotEmpty ?? false),
        'isNewUser': user.isNewUser,
      },
    );

    final exchangeResult = await exchangeFirebaseSessionUseCase(
      ExchangeFirebaseSessionParams(
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : null,
      ),
    );

    await exchangeResult.fold(
      (failure) async {
        appleSignInDebugLog(
          'controller_exchange_firebase_session_failed',
          metadata: {'failureType': failure.runtimeType.toString()},
        );
        errorMessage.value = failure.message.isNotEmpty
            ? failure.message
            : AppStrings.somethingWentWrongPleaseTryAgain.tr;
      },
      (response) async {
        appleSignInDebugLog('controller_exchange_firebase_session_succeeded');
        if (response?.isSuccess != true || response?.response == null) {
          errorMessage.value =
              response?.message ?? AppStrings.somethingWentWrongPleaseTryAgain.tr;
          return;
        }

        final route = await _persistLoginSession(response!);
        if (route == null) return;

        _navigateAfterAuth(route);
      },
    );
  }

  /// Persists tokens/user and returns the next route, or `null` on failure.
  /// Returns [AppRoutes.phone] when the rider must attach a phone number.
  Future<String?> _persistLoginSession(VerifyOtpResponseModel response) async {
    final verifyData = response.response!;
    final user = verifyData.user;
    if (user == null) {
      errorMessage.value = AppStrings.somethingWentWrongPleaseTryAgain.tr;
      return null;
    }

    if (verifyData.accessToken != null) {
      await StorageService().writeAccessToken(verifyData.accessToken!);
    }
    if (verifyData.refreshToken != null) {
      await StorageService().write(
        StorageKeys.refreshToken,
        verifyData.refreshToken!,
      );
    }

    await StorageService().write(
      StorageKeys.user,
      jsonEncode(user.toJson()),
    );

    pendingSignUpName.value = verifyData.signUpName;
    pendingSignUpEmail.value = verifyData.signUpEmail;

    if (verifyData.needsPhone == true) {
      isPhoneAttachFlow.value = true;
      // Independent of needs_phone; both can be true (collect name + phone together).
      needsName.value = verifyData.needsName == true;
      await StorageService().write(StorageKeys.signupCompleted, 'true');
      await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
      SessionExpiryService.resetOnLogin();
      return AppRoutes.phone;
    }

    isPhoneAttachFlow.value = false;
    await StorageService().write(StorageKeys.signupCompleted, 'true');
    await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
    SessionExpiryService.resetOnLogin();

    return AppRoutes.profileLoading;
  }

  Future<void> signInWithFacebook() async {
    if (isLoading.value) return;
    errorMessage.value = '';

    await Loader.withFlag(isLoading, () async {
      final result = await signInWithFacebookUseCase(NoParams());

      await result.fold(
        (failure) async {
          if (failure is FacebookSignInFailure && failure.isCancelled) {
            errorMessage.value = AppStrings.facebookSignInCancelled.tr;
            return;
          }
          if (failure is AccountLinkingFailure) {
            errorMessage.value = AppStrings.appleSignInAccountExists.tr;
            return;
          }
          if (failure is NetworkFailure) {
            errorMessage.value = failure.message;
            return;
          }
          errorMessage.value = failure.message.isNotEmpty
              ? failure.message
              : AppStrings.facebookSignInFailed.tr;
        },
        (user) => _completeSocialSignIn(user),
      );
    });
  }
}
