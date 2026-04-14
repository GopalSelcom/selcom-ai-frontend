import 'package:get/get.dart';

import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../data/datasources/ride_chat_socket_data_source.dart';
import '../../data/repositories/ride_chat_repository_impl.dart';
import '../../domain/repositories/ride_chat_repository.dart';
import '../controllers/ride_message_controller.dart';

class RideMessageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RideChatSocketDataSource>(
      () => RideChatSocketDataSource(socket: Get.find<AppSocketService>()),
      fenix: true,
    );
    Get.lazyPut<RideChatRepository>(
      () => RideChatRepositoryImpl(dataSource: Get.find<RideChatSocketDataSource>()),
      fenix: true,
    );
    Get.lazyPut<RideMessageController>(
      () => RideMessageController(chatRepository: Get.find<RideChatRepository>()),
      fenix: true,
    );
  }
}
