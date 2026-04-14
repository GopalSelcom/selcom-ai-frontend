import 'package:get/get.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../domain/usecases/profile_usecase.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../../core/routes/app_routes.dart';

class FavoriteLocationsController extends GetxController {
  final ProfileUseCase profileUseCase;
  final ProfileRepository profileRepository;

  FavoriteLocationsController({
    required this.profileUseCase,
    required this.profileRepository,
  });

  final RxList<SavedPlace> favorites = <SavedPlace>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    isLoading.value = true;
    final result = await profileUseCase.getFavoritePlaces();
    result.fold(
      (failure) {
        Get.snackbar('Error', failure.message);
      },
      (response) {
        if (response != null && response.data != null) {
          favorites.value = response.data!.savedPlaces ?? [];
        }
      },
    );
    isLoading.value = false;
  }

  Future<void> toggleFavorite(SavedPlace place) async {
    // Optimistic UI update: remove from list if unfavoriting
    final originalList = List<SavedPlace>.from(favorites);
    favorites.removeWhere((p) => p.id == place.id);

    final result = await profileRepository.toggleFavorite(place.id!, false);

    result.fold(
      (failure) {
        // Rollback
        favorites.value = originalList;
        Get.snackbar('Error', 'Failed to update favorite status');
      },
      (success) {
        if (!success) {
          // Rollback
          favorites.value = originalList;
          Get.snackbar('Error', 'Failed to update favorite status');
        } else {
          // Sync with HomeController if it exists
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().loadSavedPlaces();
          }
        }
      },
    );
  }

  void onLocationSelected(SavedPlace place) {
    if (!Get.isRegistered<HomeController>()) {
      Get.snackbar('Error', 'Unable to initiate booking right now.');
      return;
    }

    final homeController = Get.find<HomeController>();

    double? dLat = place.lat;
    double? dLng = place.lng;
    final coords = place.location?.coordinates;
    if ((dLat == null || dLng == null) &&
        coords != null &&
        coords.length >= 2) {
      dLng = coords[0];
      dLat = coords[1];
    }

    if (dLat == null || dLng == null) {
      Get.snackbar(
        'Location unavailable',
        'This saved place is missing coordinates.',
      );
      return;
    }

    final destAddr = (place.address ?? place.name ?? place.label ?? 'Location')
        .trim();
    final pickupAddr = homeController.activePickupAddress;
    final pickupLL = homeController.activePickupLatLng;

    Get.toNamed(
      AppRoutes.booking,
      arguments: {
        'pickup': pickupAddr,
        'pickupLat': pickupLL.latitude,
        'pickupLng': pickupLL.longitude,
        'destination': destAddr,
        'destinationLat': dLat,
        'destinationLng': dLng,
        if (place.id != null && place.id!.isNotEmpty)
          'destinationPlaceId': place.id,
      },
    );
  }
}
