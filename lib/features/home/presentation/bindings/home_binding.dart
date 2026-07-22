import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../ride_rating/presentation/bindings/ride_rating_binding.dart';
import '../../../ride_rating/presentation/controllers/ride_rating_controller.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../controllers/home_controller.dart';
import '../controllers/location_selection_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RideRatingController>()) {
      RideRatingBinding().dependencies();
    }

    // Home Data
    Get.lazyPut<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(),
      fenix: true,
    );
    Get.lazyPut<HomeRepository>(
      () => HomeRepositoryImpl(remoteDataSource: Get.find()),
      fenix: true,
    );



    // Controller
    Get.lazyPut<HomeController>(
      () => HomeController(
        homeRepository: Get.find(),
        analyticsService: di.sl<AnalyticsService>(),
        notificationService: di.sl<NotificationService>(),
        rideRatingController: Get.find<RideRatingController>(),
      ),
      fenix: true,
    );

    Get.lazyPut<LocationSelectionController>(
      () => LocationSelectionController(),
      fenix: true,
    );
  }
}
