part of '../home_controller.dart';

/// Helpers for LocationSelectionController: apply text / suggestion / saved / recent
/// into the active pickup or destination segment.
extension HomeLocationSelectionMethods on HomeController {
  // Location selection screen orchestration helpers.
  void applyLocationSelectionTextToSegment({
    required int activeSegmentIndex,
    required String text,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    if (activeSegmentIndex == 0) {
      pickupEditedByUser.value = true;
      routePickupLat.value = null;
      routePickupLng.value = null;
      pickupController.text = text;
      return;
    }

    if (activeSegmentIndex == 1) {
      destinationController.text = text;
      routeDestinationLat.value = null;
      routeDestinationLng.value = null;
      destinationPlaceId.value = null;
      return;
    }

    final i = activeSegmentIndex - 2;
    if (i >= 0 && i < extraDestinationControllers.length) {
      extraDestinationControllers[i].text = text;
    }
  }

  void applySuggestionToLocationSelection({
    required Prediction prediction,
    required int activeSegmentIndex,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    final description = prediction.description ?? '';
    if (activeSegmentIndex == 0) {
      pickupEditedByUser.value = true;
      routePickupLat.value = null;
      routePickupLng.value = null;
      pickupController.text = description;
      pickupController.selection = TextSelection.fromPosition(
        TextPosition(offset: pickupController.text.length),
      );
      getLatLngFromAddress(description).then((latLng) {
        if (latLng != null) {
          routePickupLat.value = latLng.latitude;
          routePickupLng.value = latLng.longitude;
        }
      });
      return;
    }

    if (activeSegmentIndex == 1) {
      destinationController.text = description;
      routeDestinationLat.value = null;
      routeDestinationLng.value = null;
      destinationPlaceId.value = prediction.placeId?.trim();
      destinationController.selection = TextSelection.fromPosition(
        TextPosition(offset: destinationController.text.length),
      );

      // Async resolve coordinates to avoid faulty fallbacks later
      getLatLngFromAddress(description).then((latLng) {
        if (latLng != null) {
          routeDestinationLat.value = latLng.latitude;
          routeDestinationLng.value = latLng.longitude;
        }
      });
      return;
    }

    final i = activeSegmentIndex - 2;
    if (i >= 0 && i < extraDestinationControllers.length) {
      final c = extraDestinationControllers[i];
      c.text = description;
      c.selection = TextSelection.fromPosition(
        TextPosition(offset: c.text.length),
      );

      // Also resolve for extra stops if needed
      getLatLngFromAddress(description).then((latLng) {
        if (latLng != null && activeSegmentIndex == (i + 2)) {
          // We don't have reactive lat/lng list for extra stops yet in this controller state,
          // but we can at least resolve if we add them later.
        }
      });
    }
  }

  bool applySavedPlaceToLocationSelection({
    required SavedPlace savedPlace,
    required int activeSegmentIndex,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    final saved = savedPlace.address?.trim();
    if (saved == null || saved.isEmpty) return false;

    final coords = savedPlace.location?.coordinates;
    final lat =
        savedPlace.lat ??
        ((coords != null && coords.length >= 2) ? coords[1] : null);
    final lng =
        savedPlace.lng ??
        ((coords != null && coords.length >= 2) ? coords[0] : null);

    applyLocationSelectionTextToSegment(
      activeSegmentIndex: activeSegmentIndex,
      text: saved,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );

    if (lat != null && lng != null) {
      if (activeSegmentIndex == 0) {
        routePickupLat.value = lat;
        routePickupLng.value = lng;
      } else if (activeSegmentIndex == 1) {
        routeDestinationLat.value = lat;
        routeDestinationLng.value = lng;
        destinationPlaceId.value = null;
      }
    }

    searchQuery.value = '';
    return true;
  }

  void applyRecentDestinationToLocationSelection({
    required RecentDestination destination,
    required int activeSegmentIndex,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    applyLocationSelectionTextToSegment(
      activeSegmentIndex: activeSegmentIndex,
      text: destination.address ?? '',
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    if (activeSegmentIndex == 1) {
      routeDestinationLat.value = destination.lat;
      routeDestinationLng.value = destination.lng;
    }
    searchQuery.value = '';
  }

  void applyRecentSearchToLocationSelection({
    required String recentText,
    required int activeSegmentIndex,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    applyLocationSelectionTextToSegment(
      activeSegmentIndex: activeSegmentIndex,
      text: recentText,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    searchQuery.value = '';
  }
}
