import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/app_region_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/onboarding_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuthController(
        authRepository: di.sl<AuthRepository>(),
        appRegionService: di.sl<AppRegionService>(),
      ),
    );
    Get.lazyPut(
      () => OnboardingController(authRepository: di.sl<AuthRepository>()),
    );
  }
}
