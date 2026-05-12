import 'package:get/get.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/app_region_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/resend_otp_use_case.dart';
import '../../domain/usecases/save_user_additional_details_use_case.dart';
import '../../domain/usecases/send_otp_use_case.dart';
import '../../domain/usecases/verify_otp_use_case.dart';
import '../controllers/auth_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/sign_up_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Data Sources (no Dio needed — ApiService is a singleton)
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(),
    );

    // Repositories
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: Get.find()),
    );

    // Use Cases
    Get.lazyPut(() => SendOtpUseCase(Get.find()));
    Get.lazyPut(() => ResendOtpUseCase(Get.find()));
    Get.lazyPut(() => VerifyOtpUseCase(Get.find()));
    Get.lazyPut(() => SaveUserAdditionalDetailsUseCase(Get.find()));

    // Controllers
    Get.lazyPut(
      () => AuthController(
        sendOtpUseCase: Get.find(),
        resendOtpUseCase: Get.find(),
        verifyOtpUseCase: Get.find(),
        appRegionService: di.sl<AppRegionService>(),
      ),
    );
    Get.lazyPut(() => OnboardingController());
    Get.lazyPut(
      () => SignUpController(saveUserAdditionalDetailsUseCase: Get.find()),
    );
  }
}
