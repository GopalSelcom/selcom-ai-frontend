import 'package:get/get.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../ride/data/datasources/ride_remote_data_source.dart';
import '../../../ride/data/repositories/ride_repository_impl.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../controllers/home_controller.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/analytics_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Home Data
    Get.lazyPut<HomeRemoteDataSource>(() => HomeRemoteDataSourceImpl());
    Get.lazyPut<HomeRepository>(() => HomeRepositoryImpl(remoteDataSource: Get.find()));

    // Ride Data (Needed for recent destinations on Home Screen)
    Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl());
    Get.lazyPut<RideRepository>(() => RideRepositoryImpl(remoteDataSource: Get.find()));

    // Profile Data (Needed for saved addresses on Home Screen)
    Get.lazyPut<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl());
    Get.lazyPut<ProfileRepository>(() => ProfileRepositoryImpl(remoteDataSource: Get.find()));

    // Controller
    Get.lazyPut<HomeController>(
      () => HomeController(
        homeRepository: Get.find(),
        rideRepository: Get.find(),
        profileRepository: Get.find(),
        analyticsService: di.sl<AnalyticsService>(),
      ),
    );
  }
}
