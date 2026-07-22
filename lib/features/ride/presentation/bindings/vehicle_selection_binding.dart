import 'package:get/get.dart';

import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../data/datasources/ride_remote_data_source.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/vehicle_selection_controller.dart';

class VehicleSelectionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AppSocketService>()) {
      Get.lazyPut<AppSocketService>(() => AppSocketService(), fenix: true);
    }
    if (!Get.isRegistered<RideRepository>()) {
      Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl());
      Get.lazyPut<RideRepository>(
        () => RideRepositoryImpl(remoteDataSource: Get.find()),
      );
    }
    Get.put<VehicleSelectionController>(
      VehicleSelectionController(
        rideRepository: Get.find(),
      ),
    );
  }
}
