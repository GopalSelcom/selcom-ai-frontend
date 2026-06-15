import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/support_repository.dart';
import '../controllers/login_support_controller.dart';

class LoginSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginSupportController(supportRepository: sl<SupportRepository>()),
    );
  }
}
