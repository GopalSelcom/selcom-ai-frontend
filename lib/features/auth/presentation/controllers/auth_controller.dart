import 'package:get/get.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
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
  final countryCode = '+255'.obs;
  final otp = ''.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

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
        mobileNumber: mobileNumber.value,
        countryCode: countryCode.value,
        otp: otp.value,
      ),
    );

    isLoading.value = false;

    return result.fold(
      (failure) {
        errorMessage.value = failure.message;
        return false;
      },
      (response) {
        if (response?.isSuccess == true && response?.response != null) {
          final verifyData = response!.response!;
          // Navigate to Home or Profile Setup based on registration status
          if (verifyData.isUserAlreadyRegistered == true) {
            Get.offAllNamed('/home');
          } else {
            // If profile is not complete, go to profile setup
            // For now, redirect to Home until Profile Setup is built
            Get.offAllNamed('/home');
          }
          return true;
        } else {
          errorMessage.value = response?.message ?? 'OTP verification failed';
          return false;
        }
      },
    );
  }
}
