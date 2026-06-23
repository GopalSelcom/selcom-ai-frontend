import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/app_region_service.dart';
import '../../../../core/services/apple_sign_in_service.dart';
import '../../../../core/services/google_sign_in_service.dart';
import '../../../../core/services/facebook_sign_in_service.dart';
import '../../data/datasources/apple_auth_local_data_source.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/exchange_firebase_session_use_case.dart';
import '../../domain/usecases/firebase_login_use_case.dart';
import '../../domain/usecases/resend_phone_otp_use_case.dart';
import '../../domain/usecases/save_user_additional_details_use_case.dart';
import '../../domain/usecases/send_phone_otp_use_case.dart';
import '../../domain/usecases/sign_in_with_apple_use_case.dart';
import '../../domain/usecases/sign_in_with_facebook_use_case.dart';
import '../../domain/usecases/sign_in_with_google_use_case.dart';
import '../../domain/usecases/sign_out_firebase_use_case.dart';
import '../../domain/usecases/verify_phone_otp_use_case.dart';
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
        googleSignInService: di.sl<GoogleSignInService>(),
        facebookSignInService: di.sl<FacebookSignInService>(),
        firebaseAuthDataSource: di.sl<FirebaseAuthDataSource>(),
        appleAuthLocalDataSource: di.sl<AppleAuthLocalDataSource>(),
      ),
    );

    Get.lazyPut(() => FirebaseLoginUseCase(Get.find()));
    Get.lazyPut(() => ExchangeFirebaseSessionUseCase(Get.find()));
    Get.lazyPut(() => SendPhoneOtpUseCase(Get.find()));
    Get.lazyPut(() => ResendPhoneOtpUseCase(Get.find()));
    Get.lazyPut(() => VerifyPhoneOtpUseCase(Get.find()));
    Get.lazyPut(() => SaveUserAdditionalDetailsUseCase(Get.find()));
    Get.lazyPut(() => SignInWithAppleUseCase(Get.find()));
    Get.lazyPut(() => SignInWithFacebookUseCase(Get.find()));
    Get.lazyPut(() => SignInWithGoogleUseCase(Get.find()));
    Get.lazyPut(() => SignOutFirebaseUseCase(Get.find()));

    Get.lazyPut(
      () => AuthController(
        sendPhoneOtpUseCase: Get.find(),
        resendPhoneOtpUseCase: Get.find(),
        verifyPhoneOtpUseCase: Get.find(),
        signInWithAppleUseCase: Get.find(),
        signInWithGoogleUseCase: Get.find(),
        exchangeFirebaseSessionUseCase: Get.find(),
        signInWithFacebookUseCase: Get.find(),
        appRegionService: di.sl<AppRegionService>(),
      ),
    );
    Get.lazyPut(() => OnboardingController());
    Get.lazyPut(
      () => SignUpController(saveUserAdditionalDetailsUseCase: Get.find()),
    );
  }
}
