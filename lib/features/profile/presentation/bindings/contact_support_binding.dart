import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/contact_support_controller.dart';

class ContactSupportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ContactSupportController(
        profileRepository: sl<ProfileRepository>(),
        rideRepository: sl<RideRepository>(),
      ),
    );
  }
}
