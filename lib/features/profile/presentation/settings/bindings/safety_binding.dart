import 'package:get/get.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../features/settings/domain/repositories/settings_repository.dart';
import '../controllers/settings_controller.dart';

class SafetyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsController(
        settingsRepository: sl<SettingsRepository>(),
        appSettingsService: sl<AppSettingsService>(),
      ),
    );
  }
}
