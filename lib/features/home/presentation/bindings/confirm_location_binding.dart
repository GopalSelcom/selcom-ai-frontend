import 'package:get/get.dart';

import '../../../ride/data/datasources/ride_remote_data_source.dart';
import '../../../ride/data/repositories/ride_repository_impl.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../controllers/confirm_location_controller.dart';
import '../controllers/home_controller.dart';
import 'home_binding.dart';

class ConfirmLocationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      HomeBinding().dependencies();
    }
    if (!Get.isRegistered<RideRepository>()) {
      Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl(), fenix: true);
      Get.lazyPut<RideRepository>(
        () => RideRepositoryImpl(remoteDataSource: Get.find()),
        fenix: true,
      );
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
