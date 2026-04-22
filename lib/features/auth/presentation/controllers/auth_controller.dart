import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/usecases/send_otp_use_case.dart';
import '../../domain/usecases/verify_otp_use_case.dart';

class AuthController extends GetxController {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  AuthController({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
  });

  final mobileNumber = ''.obs;
  final email = ''.obs;
  final countryCode = '+255'.obs;
  final otp = ''.obs;
  final generatedOtp = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final resendTimer = 59.obs;
  Timer? _timer;

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
        mobileNumber: mobileNumber.value.replaceAll(' ', ''),
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
          errorMessage.value = response?.message ?? 'Failed to send OTP';
          generatedOtp.value = '';
          return false;
        }
      },
    );
  }

  Future<void> sendOtpAndNavigate() async {
    if (!isEmailValidOrEmpty) {
      errorMessage.value = invalidEmailMessage;
      return;
    }

    final success = await sendOtp();
    if (!success) return;
    startResendTimer();
    Get.toNamed(AppRoutes.otp);
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(value);
  }

  bool get isEmailValidOrEmpty {
    final normalized = email.value.trim();
    if (normalized.isEmpty) return true;
    return _isValidEmail(normalized);
  }

  bool get canRequestOtp =>
      mobileNumber.value.length >= 9 && isEmailValidOrEmpty && !isLoading.value;
  bool get shouldShowGeneratedOtp =>
      AppConfig.environment == Environment.dev ||
      AppConfig.environment == Environment.staging;

  String get invalidEmailMessage => 'Please enter a valid email address';

  void onEmailChanged(String value) {
    email.value = value;
    final normalized = value.trim();
    if (normalized.isEmpty) {
      if (errorMessage.value == invalidEmailMessage) {
        errorMessage.value = '';
      }
      return;
    }
    if (_isValidEmail(normalized)) {
      if (errorMessage.value == invalidEmailMessage) {
        errorMessage.value = '';
      }
      return;
    }
    errorMessage.value = invalidEmailMessage;
  }

  Future<bool> resendOtp() async {
    isLoading.value = true;
    errorMessage.value = '';
    
    // Start timer immediately for better user feedback
    startResendTimer();

    final result = await sendOtpUseCase(
      SendOtpRequest(
        mobileNumber: mobileNumber.value.replaceAll(' ', ''),
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
          errorMessage.value = response?.message ?? 'Failed to resend OTP';
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
        mobileNumber: mobileNumber.value.replaceAll(' ', ''),
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

          // Navigate to Profile Loading to sync data
          Get.offAllNamed(AppRoutes.profileLoading);
          return true;
        } else {
          errorMessage.value = response?.message ?? 'OTP verification failed';
          return false;
        }
      },
    );
  }

  void completeProfileLoading() {
    Get.offAllNamed(AppRoutes.home);
  }
}
