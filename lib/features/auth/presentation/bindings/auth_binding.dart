import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/apple_sign_in_service.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../data/datasources/apple_auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/resend_otp_use_case.dart';
import '../../domain/usecases/save_user_additional_details_use_case.dart';
import '../../domain/usecases/send_otp_use_case.dart';
import '../../domain/usecases/sign_in_with_apple_use_case.dart';
import '../../domain/usecases/sign_out_firebase_use_case.dart';
import '../../domain/usecases/verify_otp_use_case.dart';
import '../controllers/auth_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/sign_up_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl());

    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: Get.find(),
        appleSignInService: di.sl<AppleSignInService>(),
        firebaseAuthDataSource: di.sl<FirebaseAuthDataSource>(),
        appleAuthLocalDataSource: di.sl<AppleAuthLocalDataSource>(),
      ),
    );

    Get.lazyPut(() => SendOtpUseCase(Get.find()));
    Get.lazyPut(() => ResendOtpUseCase(Get.find()));
    Get.lazyPut(() => VerifyOtpUseCase(Get.find()));
    Get.lazyPut(() => SaveUserAdditionalDetailsUseCase(Get.find()));
    Get.lazyPut(() => SignInWithAppleUseCase(Get.find()));
    Get.lazyPut(() => SignOutFirebaseUseCase(Get.find()));

    Get.lazyPut(
      () => AuthController(
        sendOtpUseCase: Get.find(),
        resendOtpUseCase: Get.find(),
        verifyOtpUseCase: Get.find(),
        signInWithAppleUseCase: Get.find(),
        appRegionService: di.sl<AppRegionService>(),
        googleSignInService: di.sl<GoogleSignInService>(),
      ),
    );
    Get.lazyPut(() => OnboardingController());
    Get.lazyPut(
      () => SignUpController(saveUserAdditionalDetailsUseCase: Get.find()),
    );
  }
}
