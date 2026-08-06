import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/finding_driver_controller.dart';

class FindingDriverBinding extends Bindings {
  @override
  void dependencies() {
    // Always recreate so a new active ride never reuses a stale rideId/socket session.
    if (Get.isRegistered<FindingDriverController>()) {
      Get.delete<FindingDriverController>(force: true);
    }
    Get.put<FindingDriverController>(
      FindingDriverController(rideRepository: sl<RideRepository>()),
    );
  }
}
