import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/vehicle_selection_controller.dart';

class VehicleSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<VehicleSelectionController>(
      VehicleSelectionController(
        rideRepository: sl<RideRepository>(),
      ),
    );
  }
}
