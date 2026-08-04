import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/favorite_locations_controller.dart';

class FavoriteLocationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => FavoriteLocationsController(
        profileRepository: sl<ProfileRepository>(),
      ),
    );
  }
}
