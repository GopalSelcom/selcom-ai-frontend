import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../controllers/my_rides_controller.dart';

class MyRidesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyRidesController>(() => sl<MyRidesController>());
  }
}
