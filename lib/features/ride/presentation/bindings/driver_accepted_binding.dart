import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/analytics_service.dart';
import '../../data/datasources/ride_remote_data_source.dart';
import '../../data/datasources/ride_share_remote_datasource.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../data/repositories/ride_share_repository_impl.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../domain/repositories/ride_share_repository.dart';
import '../../domain/usecases/generate_share_link_use_case.dart';
import '../../domain/usecases/revoke_share_link_use_case.dart';
import '../controllers/driver_accepted_controller.dart';
import '../controllers/ride_share_controller.dart';

class DriverAcceptedBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RideRepository>()) {
      Get.lazyPut<RideRemoteDataSource>(() => RideRemoteDataSourceImpl());
      Get.lazyPut<RideRepository>(() => RideRepositoryImpl(remoteDataSource: Get.find()));
    }
    if (!Get.isRegistered<RideShareRepository>()) {
      Get.lazyPut<RideShareRemoteDataSource>(() => RideShareRemoteDataSourceImpl());
      Get.lazyPut<RideShareRepository>(
        () => RideShareRepositoryImpl(remoteDataSource: Get.find()),
      );
      Get.lazyPut<GenerateShareLinkUseCase>(
        () => GenerateShareLinkUseCase(Get.find<RideShareRepository>()),
      );
      Get.lazyPut<RevokeShareLinkUseCase>(
        () => RevokeShareLinkUseCase(Get.find<RideShareRepository>()),
      );
    }
    if (!Get.isRegistered<RideShareController>()) {
      Get.lazyPut<RideShareController>(
        () => RideShareController(
          generateShareLinkUseCase: Get.find<GenerateShareLinkUseCase>(),
          revokeShareLinkUseCase: Get.find<RevokeShareLinkUseCase>(),
          enableRevokeLink: false,
        ),
        fenix: true,
      );
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
