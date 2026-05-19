import 'package:get/get.dart';

import '../../../home/data/datasources/home_remote_data_source.dart';
import '../../../home/data/repositories/home_repository_impl.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../controllers/promo_code_controller.dart';

class PromoCodeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeRemoteDataSource>()) {
      Get.lazyPut<HomeRemoteDataSource>(() => HomeRemoteDataSourceImpl());
    }
    if (!Get.isRegistered<HomeRepository>()) {
      Get.lazyPut<HomeRepository>(
        () => HomeRepositoryImpl(remoteDataSource: Get.find()),
      );
    }
    Get.lazyPut<PromoCodeController>(
      () => PromoCodeController(homeRepository: Get.find()),
    );
  }
}
