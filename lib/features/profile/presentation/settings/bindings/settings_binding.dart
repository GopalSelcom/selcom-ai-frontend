import 'package:get/get.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../features/settings/domain/usecases/settings_usecase.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SettingsController(settingsUseCase: sl<SettingsUseCase>()),
    );
  }
}
