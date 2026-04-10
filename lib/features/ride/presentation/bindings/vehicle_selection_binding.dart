import 'package:get/get.dart';

import '../../../home/data/datasources/home_remote_data_source.dart';
import '../../../home/data/repositories/home_repository_impl.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../data/datasources/ride_remote_data_source.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/vehicle_selection_controller.dart';

class VehicleSelectionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeRepository>()) {
      Get.lazyPut<HomeRemoteDataSource>(() => HomeRemoteDataSourceImpl());
      Get.lazyPut<HomeRepository>(() => HomeRepositoryImpl(remoteDataSource: Get.find()));
    }
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl());
      Get.lazyPut<ProfileRepository>(() => ProfileRepositoryImpl(remoteDataSource: Get.find()));
    }
    if (!Get.isRegistered<RideRepository>()) {
      Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl());
      Get.lazyPut<RideRepository>(() => RideRepositoryImpl(remoteDataSource: Get.find()));
    }
    Get.lazyPut<VehicleSelectionController>(
      () => VehicleSelectionController(
        homeRepository: Get.find(),
        profileRepository: Get.find(),
        rideRepository: Get.find(),
      ),
    );
  }
}
