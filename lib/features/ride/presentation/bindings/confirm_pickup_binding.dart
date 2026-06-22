import 'package:get/get.dart';

import '../../../home/domain/repositories/home_repository.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/confirm_pickup_controller.dart';

class ConfirmPickupBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<ConfirmPickupController>()) {
      Get.delete<ConfirmPickupController>(force: true);
    }
    Get.put(
      ConfirmPickupController(
        homeRepository: Get.find<HomeRepository>(),
        rideRepository: Get.find<RideRepository>(),
      ),
    );
  }
}
