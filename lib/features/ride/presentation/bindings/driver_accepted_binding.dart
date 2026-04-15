import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/datasources/ride_remote_data_source.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../domain/repositories/ride_repository.dart';
import '../controllers/driver_accepted_controller.dart';

class DriverAcceptedBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RideRepository>()) {
      Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl());
      Get.lazyPut<RideRepository>(() => RideRepositoryImpl(remoteDataSource: Get.find()));
    }
    Get.lazyPut<DriverAcceptedController>(
      () => DriverAcceptedController(
        rideRepository: Get.find(),
        analyticsService: sl<AnalyticsService>(),
      ),
      fenix: true,
    );
  }
}
