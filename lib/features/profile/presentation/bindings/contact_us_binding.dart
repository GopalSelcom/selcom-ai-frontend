import 'package:get/get.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../controllers/contact_us_controller.dart';

class ContactUsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ContactUsController(
      profileRepository: sl<ProfileRepository>(),
      rideRepository: sl<RideRepository>(),
    ));
  }
}
