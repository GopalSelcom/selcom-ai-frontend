import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Must use put (not lazyPut): splash UI never reads [controller], so
    // lazy registration would never create SplashController / run onInit.
    Get.put<SplashController>(SplashController());
  }
}
