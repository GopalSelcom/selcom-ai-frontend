import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/routes/app_routes.dart';
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
        mobileNumber: mobileNumber.value,
        countryCode: countryCode.value,
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
        countryCode: countryCode.value,
        email: email.value.trim().isEmpty ? null : email.value.trim(),
      ),
    );

    isLoading.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        return false;
      },
      (success) {
        startResendTimer();
        return success;
      },
    );
  }

  Future<bool> verifyOtp() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await verifyOtpUseCase(
      VerifyOtpRequest(
        mobileNumber: mobileNumber.value.replaceAll(' ', ''),
        countryCode: countryCode.value,
        otp: otp.value,
      ),
    );

    isLoading.value = false;

    return await result.fold(
      (failure) async {
        errorMessage.value = failure.message;
        return false;
      },
      (authEntity) async {
        const storage = FlutterSecureStorage();
        await storage.write(key: 'authorization_token', value: authEntity.accessToken);
        await storage.write(key: 'access_token', value: authEntity.accessToken);
        await storage.write(key: 'refresh_token', value: authEntity.refreshToken);

        // Navigate to Profile Loading to sync data
        Get.offAllNamed(AppRoutes.profileLoading);
        return true;
      },
    );
  }
}
