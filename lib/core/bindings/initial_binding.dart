import 'package:get/get.dart';
import '../../features/payment/presentation/controllers/payment_method_controller.dart';
import '../di/injection_container.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentMethodController>(
      () => PaymentMethodController(profileRepository: sl()),
      fenix: true,
    );
  }
}
