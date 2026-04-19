import 'package:get/get.dart';

import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../home/data/datasources/home_remote_data_source.dart';
import '../../../home/data/repositories/home_repository_impl.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../data/datasources/ride_remote_data_source.dart';
import '../../data/repositories/ride_repository_impl.dart';
import '../../domain/repositories/ride_repository.dart';
import '../../../payment/presentation/controllers/payment_method_controller.dart';
import '../controllers/vehicle_selection_controller.dart';

class VehicleSelectionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AppSocketService>()) {
      Get.lazyPut<AppSocketService>(() => AppSocketService(), fenix: true);
    }
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
    if (!Get.isRegistered<PaymentMethodController>()) {
      Get.lazyPut<PaymentMethodController>(
        () => PaymentMethodController(profileRepository: Get.find()),
        fenix: true,
      );
    }
    Get.put<VehicleSelectionController>(
      VehicleSelectionController(
        homeRepository: Get.find(),
        profileRepository: Get.find(),
        rideRepository: Get.find(),
        paymentMethodController: Get.find(),
      ),
    );
  }
}
