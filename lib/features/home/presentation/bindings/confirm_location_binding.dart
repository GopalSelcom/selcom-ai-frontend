import 'package:get/get.dart';

import '../controllers/confirm_location_controller.dart';
import '../controllers/home_controller.dart';
import 'home_binding.dart';

class ConfirmLocationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      HomeBinding().dependencies();
    }
    if (Get.isRegistered<ConfirmLocationController>()) {
      Get.delete<ConfirmLocationController>(force: true);
    }
    Get.put(
      ConfirmLocationController(
        homeRepository: Get.find(),
        rideRepository: Get.find(),
        homeController: Get.find<HomeController>(),
      ),
    );
  }
}
