import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/login_pin_gate_service.dart';
import '../../domain/usecases/login_pin_usecases.dart';
import '../controllers/biometric_unlock_controller.dart';
import '../controllers/login_pin_controller.dart';

/// DI for [LoginPinScreen] routes: pin-setup, pin-login, pin-change.
class LoginPinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginPinController(
        setupLoginPinUseCase: sl<SetupLoginPinUseCase>(),
        verifyLoginPinUseCase: sl<VerifyLoginPinUseCase>(),
        changeLoginPinUseCase: sl<ChangeLoginPinUseCase>(),
        getLoginPinStatusUseCase: sl<GetLoginPinStatusUseCase>(),
        deleteLoginPinUseCase: sl<DeleteLoginPinUseCase>(),
        loginPinGateService: sl<LoginPinGateService>(),
        analyticsService: sl<AnalyticsService>(),
      ),
    );
  }
}

/// DI for [BiometricUnlockScreen] (cold start when biometric enabled).
class BiometricUnlockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => BiometricUnlockController(
        biometricService: sl<BiometricService>(),
        refreshLoginSessionUseCase: sl<RefreshLoginSessionUseCase>(),
        analyticsService: sl<AnalyticsService>(),
      ),
    );
  }
}
