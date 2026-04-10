import 'package:get/get.dart';

import '../../data/datasources/ride_remote_data_source.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/finding_driver_controller.dart';

class FindingDriverBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RideRepository>()) {
      Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl());
      Get.lazyPut<RideRepository>(() => RideRepositoryImpl(remoteDataSource: Get.find()));
    }
    Get.lazyPut<FindingDriverController>(
      () => FindingDriverController(rideRepository: Get.find()),
      fenix: true,
    );
  }
}
