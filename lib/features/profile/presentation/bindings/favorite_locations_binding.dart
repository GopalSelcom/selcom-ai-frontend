import 'package:get/get.dart';
import '../../../../core/di/injection_container.dart';
import '../controllers/favorite_locations_controller.dart';
import '../../domain/usecases/profile_usecase.dart';
import '../../domain/repositories/profile_repository.dart';

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
