import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../controllers/promo_code_controller.dart';

class PromoCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromoCodeController>(
      () => PromoCodeController(homeRepository: sl<HomeRepository>()),
    );
  }
}
