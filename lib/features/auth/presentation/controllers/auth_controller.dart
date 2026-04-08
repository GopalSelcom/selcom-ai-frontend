import 'package:get/get.dart';
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
      SendOtpParams(
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
      (success) => success,
    );
  }

  Future<bool> verifyOtp() async {
    isLoading.value = true;
    errorMessage.value = '';

    final result = await verifyOtpUseCase(
      VerifyOtpParams(
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
      (authEntity) {
        // Navigate to Home or Profile Setup
        if (authEntity.isUserAlreadyRegistered) {
          Get.offAllNamed('/home');
        } else {
          // If profile is not complete, go to profile setup
          // For now, redirect to Home until Profile Setup is built
          Get.offAllNamed('/home');
        }
        return true;
      },
    );
  }
}
