import 'dart:async';
import 'package:get/get.dart';
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
        return false;
      },
      (response) {
        if (response?.isSuccess == true) {
          return true;
        } else {
          errorMessage.value = response?.message ?? 'Failed to send OTP';
          return false;
        }
      },
    );
  }

  Future<bool> resendOtp() async {
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
        return false;
      },
      (response) {
        if (response?.isSuccess == true) {
          startResendTimer();
          return true;
        } else {
          errorMessage.value = response?.message ?? 'Failed to resend OTP';
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
}
