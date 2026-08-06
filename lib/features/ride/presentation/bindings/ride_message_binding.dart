import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/ride_chat_repository.dart';
import '../controllers/ride_message_controller.dart';

class RideMessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RideMessageController>(
      () => RideMessageController(chatRepository: sl<RideChatRepository>()),
      fenix: true,
    );
  }
}
