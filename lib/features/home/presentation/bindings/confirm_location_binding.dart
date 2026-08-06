import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../domain/repositories/home_repository.dart';
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
        homeRepository: sl<HomeRepository>(),
        rideRepository: sl<RideRepository>(),
        homeController: Get.find<HomeController>(),
      ),
    );
  }
}
