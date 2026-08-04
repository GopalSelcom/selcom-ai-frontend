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
import '../controllers/auth_controller.dart';
import '../controllers/onboarding_controller.dart';

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

    Get.lazyPut(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        appRegionService: di.sl<AppRegionService>(),
      ),
    );
    Get.lazyPut(() => OnboardingController());
  }
}
