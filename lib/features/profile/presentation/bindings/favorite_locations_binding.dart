import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/profile_usecase.dart';
import '../controllers/favorite_locations_controller.dart';

class FavoriteLocationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => FavoriteLocationsController(
        profileUseCase: sl<ProfileUseCase>(),
        profileRepository: sl<ProfileRepository>(),
      ),
    );
  }
}
