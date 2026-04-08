import 'package:get/get.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/send_otp_use_case.dart';
import '../../domain/usecases/verify_otp_use_case.dart';
import '../controllers/auth_controller.dart';

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
    Get.lazyPut(() => VerifyOtpUseCase(Get.find()));

    // Controllers
    Get.lazyPut(
      () => AuthController(
        sendOtpUseCase: Get.find(),
        verifyOtpUseCase: Get.find(),
      ),
    );
  }
}
