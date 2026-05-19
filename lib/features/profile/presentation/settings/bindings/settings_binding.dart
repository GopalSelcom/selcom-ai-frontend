import 'package:get/get.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/analytics_service.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../../../features/auth/domain/usecases/login_pin_usecases.dart';
import '../../../../../features/settings/domain/usecases/settings_usecase.dart';
import '../controllers/settings_controller.dart';

/// Injects [SettingsController] including login PIN status and biometric use cases.
class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsController(
        settingsUseCase: sl<SettingsUseCase>(),
        appSettingsService: sl<AppSettingsService>(),
        getLoginPinStatusUseCase: sl<GetLoginPinStatusUseCase>(),
        setLoginBiometricUseCase: sl<SetLoginBiometricUseCase>(),
        biometricService: sl<BiometricService>(),
        analyticsService: sl<AnalyticsService>(),
      ),
    );
  }
}
