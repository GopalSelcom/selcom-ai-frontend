import 'package:get/get.dart';

import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../domain/repositories/profile_repository.dart';

/// Profile → Saved locations screen.
///
/// Uses the same saved-places API as home (`GET go/user/saved-places`).
/// Removing an item deletes it on the server — there is no unfavourite-only path.
/// See `docs/SAVED-PLACES-FLOW.md`.
class FavoriteLocationsController extends GetxController {
  final ProfileRepository profileRepository;

  FavoriteLocationsController({
    required this.profileRepository,
  });

  final RxList<SavedPlace> savedPlaces = <SavedPlace>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSavedPlaces();
  }

  Future<void> fetchSavedPlaces() async {
    isLoading.value = true;
    final result = await profileRepository.getSavedPlaces();
    result.fold(
      (failure) {
        AppDialogs.showErrorDialog(message: failure.message);
      },
      (response) {
        savedPlaces.assignAll(response?.data?.savedPlaces ?? const []);
      },
    );
    isLoading.value = false;
  }

  /// Removing a saved place deletes it on the server (no separate unfavourite).
  void removeSavedPlace(SavedPlace place) {
    final placeId = place.id?.trim();
    if (placeId == null || placeId.isEmpty) return;

    AppDialogs.showConfirmationDialog(
      title: AppStrings.removeSavedAddress.tr,
      message: AppStrings.areYouSureYouWantToRemoveThisSavedAddress.tr,
      confirmText: AppStrings.remove.tr,
      cancelText: AppStrings.cancel.tr,
      onConfirm: () async {
        AppDialogs.showLoadingDialog();
        try {
          final result = await profileRepository.deleteSavedPlace(placeId);
          var shouldRefresh = false;
          result.fold(
            (failure) {
              AppDialogs.showErrorDialog(message: failure.message);
            },
            (success) {
              if (!success) {
                AppDialogs.showErrorDialog(
                  message: AppStrings.couldNotRemoveAddress.tr,
                );
                return;
              }
              shouldRefresh = true;
            },
          );

          if (shouldRefresh) {
            await fetchSavedPlaces();
            if (Get.isRegistered<HomeController>()) {
              Get.find<HomeController>().loadSavedPlaces();
            }
          }
        } finally {
          AppDialogs.dismissLoadingDialog();
        }
      },
    );
  }

  void onLocationSelected(SavedPlace place) {
    if (!Get.isRegistered<HomeController>()) {
      AppDialogs.showErrorDialog(
        message: AppStrings.unableToInitiateBookingRightNow.tr,
      );
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
      AppDialogs.showErrorDialog(
        title: AppStrings.locationUnavailable.tr,
        message: AppStrings.thisSavedPlaceIsMissingCoordinates.tr,
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
