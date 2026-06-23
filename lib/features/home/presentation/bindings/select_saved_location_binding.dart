import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../controllers/select_saved_location_controller.dart';
import 'home_binding.dart';

class SelectSavedLocationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      HomeBinding().dependencies();
    }
    if (Get.isRegistered<SelectSavedLocationController>()) {
      Get.delete<SelectSavedLocationController>(force: true);
    }
    Get.put(
      SelectSavedLocationController(homeController: Get.find<HomeController>()),
    );
  }
}
