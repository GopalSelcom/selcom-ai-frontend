import 'package:get/get.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../ride/data/datasources/ride_remote_data_source.dart';
import '../../../ride/data/repositories/ride_repository_impl.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Home Data
    Get.lazyPut<HomeRemoteDataSource>(() => HomeRemoteDataSourceImpl());
    Get.lazyPut<HomeRepository>(() => HomeRepositoryImpl(remoteDataSource: Get.find()));

    // Ride Data (Needed for recent destinations on Home Screen)
    Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl());
    Get.lazyPut<RideRepository>(() => RideRepositoryImpl(remoteDataSource: Get.find()));

    // Controller
    Get.lazyPut<HomeController>(
      () => HomeController(
        homeRepository: Get.find(),
        rideRepository: Get.find(),
      ),
    );
  }
}
