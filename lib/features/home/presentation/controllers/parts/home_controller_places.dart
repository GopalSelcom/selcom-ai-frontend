part of '../home_controller.dart';

/// Recent destinations, saved places, favorite chips, and address-header pickup.
class HomePlacesHelper {
  HomePlacesHelper(this.c);

  /// Parent [HomeController] — shared home state and lifecycle.
  final HomeController c;

  /// Reloads recent destinations into the Home list (not the dedicated screen list).
  Future<void> reloadRecentDestinations() async {
    final result = await c.homeRepository.getRecentDestinations();
    result.fold((_) => null, (destinations) {
      c.recentDestinations.assignAll(destinations);
      c.sheetHelper.invalidateHomeSheetMeasurement();
    });
  }

  /// Up to three recent destinations for the home sheet preview.
  List<RecentDestination> get recentDestinationsPreview {
    if (c.recentDestinations.length <= 3) return c.recentDestinations;
    return c.recentDestinations.take(3).toList(growable: false);
  }

  /// True when Home should show a "View more" link for recent destinations.
  bool get canViewMoreRecentLocations => c.recentDestinations.length > 3;

  /// Opens the full recent-locations screen and populates its list.
  Future<void> openRecentLocationsScreen() async {
    // Show shimmer immediately (screen builds from the same controller).
    c.isLoadingRecentLocationsScreen.value = true;
    c.recentDestinationsScreen.clear();
    Get.to<void>(() => const RecentLocationsScreen());

    // Avoid 2nd API call when Home already fetched recent destinations.
    unawaited(() async {
      // If Home already has data, reuse it (still shows shimmer briefly).
      if (c.recentDestinations.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        c.recentDestinationsScreen.assignAll(c.recentDestinations);
        c.isLoadingRecentLocationsScreen.value = false;
      } else {
        // If Home is still loading, wait a bit for its request to finish.
        if (c.isLoadingHomeData.value) {
          final start = DateTime.now();
          while (c.recentDestinations.isEmpty &&
              DateTime.now().difference(start) < const Duration(seconds: 5)) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }

        // Reuse if Home populated; otherwise fallback to fetch (only then).
        if (c.recentDestinations.isNotEmpty) {
          c.recentDestinationsScreen.assignAll(c.recentDestinations);
          c.isLoadingRecentLocationsScreen.value = false;
        } else {
          await loadRecentLocationsScreen();
        }
      }
    }());
  }

  /// Fetches recent destinations for the dedicated recent-locations screen.
  Future<void> loadRecentLocationsScreen() async {
    try {
      c.isLoadingRecentLocationsScreen.value = true;
      final result = await c.homeRepository.getRecentDestinations();
      result.fold((_) => null, (destinations) {
        c.recentDestinationsScreen.assignAll(destinations);
        c.sheetHelper.invalidateHomeSheetMeasurement();
      });
    } finally {
      c.isLoadingRecentLocationsScreen.value = false;
    }
  }

  /// Reloads the recent-locations screen list from the API.
  Future<void> refreshRecentDestinations() async {
    await loadRecentLocationsScreen();
  }

  /// Autocomplete search for [input]; updates [suggestions].
  Future<void> _searchPlaces(String input) async {
    c.isSearching.value = true;
    final result = await c.homeRepository.autocomplete(input: input);
    result.fold((failure) => c.suggestions.clear(), (list) {
      c.suggestions
        ..clear()
        ..addAll(list?.data?.predictions ?? []);
    });
    c.isSearching.value = false;
  }

  /// Selects an autocomplete prediction as the current map address.
  Future<void> selectPlace(Prediction place) async {
    final description = (place.description)?.trim();
    if (description == null || description.isEmpty) return;
    _pushRecentSearch(description);
    c.currentMapAddress.value = description;
  }

  /// Saves a recent destination as a labeled favorite place.
  Future<void> saveRecentAsFavorite({
    required RecentDestination loc,
    required String label,
  }) async {
    if (c.isSavingPlace.value) return;
    c.isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final request = SaveRecentAsFavoriteRequest(
          label: label.toLowerCase(),
          name: (loc.address ?? '').split(',').first,
          address: loc.address ?? '',
          lat: loc.lat ?? 0,
          lng: loc.lng ?? 0,
        );

        final result = await c.homeRepository.saveRecentAsFavorite(request);
        await result.fold((failure) => null, (success) async {
          if (success) {
            await refreshSavedPlacesAfterMutation();
          }
        });
      });
    } finally {
      c.isSavingPlace.value = false;
    }
  }

  /// Toggles favorite for a recent row (delete if saved, else open add sheet).
  Future<void> toggleFavoriteForRecent(RecentDestination loc) async {
    final saved = getSavedPlaceFor(loc.address ?? '', null);
    if (saved?.id != null) {
      await _confirmAndDeleteSavedPlace(saved!);
      return;
    }
    await toggleAddAddressBottomSheetForRecent(loc);
  }

  /// Finds a saved place matching the preset [label] (Home / Office / …).
  SavedPlace? getSavedPlaceByLabel(String label) {
    return SavedPlacesOrdering.placeForLabel(c.savedPlaces, label);
  }

  /// Saved places not bound to a preset chip (custom labels or duplicate presets).
  /// Used only on Home to show additional chips after the four presets.
  List<SavedPlace> get savedPlacesBeyondPresetSlots {
    return SavedPlacesOrdering.beyondPresetSlots(c.savedPlaces);
  }

  /// Address subtitle for a preset chip, or null when unset.
  String? getSavedPlaceSubtitle(String label) {
    final place = getSavedPlaceByLabel(label);
    final value = place?.address?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Remembers which home chip was last tapped (highlight on return).
  void markRecentHomeChip(String key) {
    c.recentHomeChipKey.value = key;
  }

  /// Handles tap on a preset favorite chip (book or open save flow).
  void onHomePresetChipTap(String canonical, SavedPlace? place) {
    markRecentHomeChip(FavoriteLocationChipsRow.presetChipKey(canonical));
    if (place == null) {
      Get.toNamed(AppRoutes.selectSavedLocation, arguments: canonical);
      return;
    }
    unawaited(
      c.bookingNavigationHelper.navigateToVehicleSelectionForSavedLabel(
        canonical,
      ),
    );
  }

  /// Handles tap on an extra (non-preset) saved-place chip.
  void onHomeExtraChipTap(SavedPlace place) {
    markRecentHomeChip(FavoriteLocationChipsRow.extraChipKey(place));
    unawaited(
      c.bookingNavigationHelper.navigateToVehicleSelectionForSavedPlace(place),
    );
  }

  /// Long-press on a preset chip opens the select-saved-location screen.
  void onHomePresetChipLongPress(String canonical) {
    markRecentHomeChip(FavoriteLocationChipsRow.presetChipKey(canonical));
    Get.toNamed(AppRoutes.selectSavedLocation, arguments: canonical);
  }

  /// Long-press on an extra chip opens select-saved-location for that label.
  void onHomeExtraChipLongPress(SavedPlace place) {
    markRecentHomeChip(FavoriteLocationChipsRow.extraChipKey(place));
    final raw = (place.label ?? place.name ?? '').trim();
    Get.toNamed(
      AppRoutes.selectSavedLocation,
      arguments: raw.isEmpty ? AppStrings.saved.tr : raw,
    );
  }

  /// Reload from `GET go/user/saved-places`; always applies API list including `[]`.
  Future<void> loadSavedPlaces() async {
    final result = await c.homeRepository.getSavedPlaces();
    result.fold((_) => null, (response) {
      c.savedPlaces.assignAll(
        SavedPlacesOrdering.sortForDisplay(
          response?.data?.savedPlaces ?? const [],
        ),
      );
      _syncSelectedPickupAfterSavedPlacesLoad();
    });
  }

  /// After a save/delete mutation, fetch latest saved places from server.
  /// Some backends are eventually consistent, so we retry once shortly.
  Future<void> refreshSavedPlacesAfterMutation() async {
    // await loadSavedPlaces();
    // await Future<void>.delayed(const Duration(milliseconds: 250));
    await loadSavedPlaces();
  }

  /// Keeps [selectedPickupSavedPlaceId] valid after a saved-places reload.
  void _syncSelectedPickupAfterSavedPlacesLoad() {
    if (c.savedPlaces.isEmpty &&
        c.selectedPickupSavedPlaceId.value !=
            HomeController._currentLocationPlaceId) {
      c.selectedPickupSavedPlaceId.value = null;
      return;
    }
    final current = c.selectedPickupSavedPlaceId.value;
    if (current == HomeController._currentLocationPlaceId) return;
    final stillValid =
        current != null && c.savedPlaces.any((p) => p.id == current);
    if (!stillValid) {
      c.selectedPickupSavedPlaceId.value = c.savedPlaces.isNotEmpty
          ? c.savedPlaces.first.id
          : HomeController._currentLocationPlaceId;
    }
  }

  /// Sets pickup from a saved place (or GPS when selecting current location).
  Future<void> selectSavedPlaceAsPickup(SavedPlace place) async {
    if (place.id == HomeController._currentLocationPlaceId) {
      c.selectedPickupSavedPlaceId.value =
          HomeController._currentLocationPlaceId;
      c.isSavedPlacesExpanded.value = false;
      await c.mapHelper._getCurrentLocation();
      return;
    }
    c.selectedPickupSavedPlaceId.value = place.id;
    c.isSavedPlacesExpanded.value = false;

    final latLng = c.mapHelper._latLngFromSavedPlace(place);
    final addr = (place.address ?? place.name ?? '').trim();

    if (latLng != null) {
      c._ignoreSelectionReset = true;
      c.mapCenter.value = latLng;
      if (c._mapController != null) {
        await c._mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
      }
      if (addr.isEmpty) await c.mapHelper._reverseGeocodeAtCenter();
    }
  }

  /// Whether [placeId] is the currently selected pickup saved place.
  bool isSavedPlaceSelectedAsPickup(String? placeId) {
    if (placeId == null || placeId.isEmpty) return false;
    return c.selectedPickupSavedPlaceId.value == placeId;
  }

  /// Pushes [value] onto the recent-searches list (deduped, capped at 8).
  void _pushRecentSearch(String value) {
    c.recentSearches.removeWhere(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    c.recentSearches.insert(0, value);
    if (c.recentSearches.length > 8) {
      c.recentSearches.removeRange(8, c.recentSearches.length);
    }
  }

  // ── Home screen UI orchestration (keep branching / navigation out of widgets) ──

  /// Collapsed: active pickup only; expanded: all saved places (tap one to set pickup).
  List<SavedPlace> get addressHeaderPlacesToShow {
    final current = c.mapHelper.currentLocationHeaderPlace;
    final active = c.mapHelper.activePickupSavedPlace;
    if (c.isSavedPlacesExpanded.value) {
      return <SavedPlace>[current, ...c.savedPlaces];
    }
    if (c.selectedPickupSavedPlaceId.value ==
        HomeController._currentLocationPlaceId) {
      return <SavedPlace>[current];
    }
    if (active != null) {
      return <SavedPlace>[active];
    }
    return <SavedPlace>[current];
  }

  /// Toggles the address-header saved-places dropdown when places exist.
  void toggleAddressHeaderExpansion() {
    if (c.savedPlaces.isNotEmpty) {
      c.isSavedPlacesExpanded.toggle();
    }
  }

  /// Chevron rotation for the address-header expand affordance.
  double get addressHeaderChevronTurns =>
      c.isSavedPlacesExpanded.value ? 0.5 : 0.0;

  /// Chip subtitle; Home falls back to current map address when saved line is empty.
  String? chipSubtitleFor(String label) {
    final s = getSavedPlaceSubtitle(label);
    if (s != null && s.trim().isNotEmpty) return s;
    if (label.toLowerCase() == 'home') return c.currentMapAddress.value;
    return null;
  }

  /// First line of a recent destination address for list titles.
  String recentDestinationTitleLine(RecentDestination loc) {
    final address = loc.address ?? '';
    final parts = address.split(',');
    if (parts.isEmpty) return address;
    final first = parts.first.trim();
    return first.isEmpty ? address : first;
  }

  /// Whether the recent-destinations block should render (including shimmer).
  bool get shouldShowRecentSection =>
      c.isLoadingHomeData.value || c.recentDestinations.isNotEmpty;

  /// Whether the vehicle explore row should render (including shimmer).
  bool get shouldShowVehicleSection =>
      c.isLoadingHomeData.value || c.vehicleTypes.isNotEmpty;

  /// Finds a saved place by id or matching address.
  SavedPlace? getSavedPlaceFor(String address, String? placeId) {
    if (c.savedPlaces.isEmpty) return null;
    return c.savedPlaces.firstWhereOrNull(
      (s) =>
          (placeId != null && s.id == placeId) ||
          s.address?.trim().toLowerCase() == address.trim().toLowerCase(),
    );
  }

  /// Saved place = favourite in product terms (no separate favourites list).
  bool isPlaceFavorite(String address, String? placeId) {
    return getSavedPlaceFor(address, placeId) != null;
  }

  /// Toggles add/remove favorite for an autocomplete prediction row.
  Future<void> toggleAddAddressBottomSheet(Prediction item) async {
    final detailedAddress = (item.description ?? '').trim();
    if (detailedAddress.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.noLocationsFound.tr);
      return;
    }
    final saved = getSavedPlaceFor(detailedAddress, item.placeId);
    if (saved?.id != null) {
      await _confirmAndDeleteSavedPlace(saved!);
      return;
    }
    await _openAddFavoriteBottomSheet(
      address: detailedAddress,
      onSave: (label, address) =>
          saveAddressFromPrediction(item: item, label: label, address: address),
    );
  }

  /// Toggles add/remove favorite for a recent-destination row.
  Future<void> toggleAddAddressBottomSheetForRecent(
    RecentDestination loc,
  ) async {
    final saved = getSavedPlaceFor(loc.address ?? '', null);
    if (saved?.id != null) {
      await _confirmAndDeleteSavedPlace(saved!);
      return;
    }
    await _openAddFavoriteBottomSheet(
      address: (loc.address ?? '').trim(),
      onSave: (label, address) => saveAddressFromRecentLocation(
        loc: loc,
        label: label,
        address: address,
      ),
    );
  }

  /// Toggles add/remove favorite for a free-form address (+ optional coords).
  Future<void> toggleAddAddressBottomSheetForAddress({
    required String address,
    double? lat,
    double? lng,
  }) async {
    final saved = getSavedPlaceFor(address, null);
    if (saved?.id != null) {
      await _confirmAndDeleteSavedPlace(saved!);
      return;
    }
    await _openAddFavoriteBottomSheet(
      address: address.trim(),
      onSave: (label, resolvedAddress) => saveAddressFromAddress(
        address: resolvedAddress,
        label: label,
        lat: lat,
        lng: lng,
      ),
    );
  }

  /// Opens the shared add-favorite bottom sheet for [address].
  Future<void> _openAddFavoriteBottomSheet({
    required String address,
    required Future<void> Function(String label, String address) onSave,
  }) async {
    final detailedAddress = address.trim();
    if (detailedAddress.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.noLocationsFound.tr);
      return;
    }

    await AppDialogs.ensureKeyboardClosed();

    await AddFavoriteLocationSheet.show(
      address: detailedAddress,
      resolveSavedPlace: getSavedPlaceByLabel,
      isSaving: c.isSavingPlace,
      savedPlaces: c.savedPlaces,
      onSave: (label, resolvedAddress) async {
        await onSave(label, resolvedAddress);
        if (!c.isSavingPlace.value) {
          Get.back<void>();
        }
      },
    );
  }

  /// `DELETE go/user/saved-places/{id}` after user confirms.
  Future<void> _confirmAndDeleteSavedPlace(SavedPlace place) async {
    final savedPlaceId = place.id?.trim();
    if (savedPlaceId == null || savedPlaceId.isEmpty) return;

    AppDialogs.showConfirmationDialog(
      title: AppStrings.removeSavedAddress.tr,
      message: AppStrings.areYouSureYouWantToRemoveThisSavedAddress.tr,
      confirmText: AppStrings.remove.tr,
      cancelText: AppStrings.cancel.tr,
      onConfirm: () async {
        final result = await c.homeRepository.deleteSavedPlace(savedPlaceId);
        result.fold(
          (failure) => AppDialogs.showErrorDialog(message: failure.message),
          (success) async {
            if (success) {
              await refreshSavedPlacesAfterMutation();
            } else {
              AppDialogs.showErrorDialog(
                message: AppStrings.couldNotRemoveAddress.tr,
              );
            }
          },
        );
      },
    );
  }

  /// Saves an autocomplete prediction as a labeled favorite.
  Future<void> saveAddressFromPrediction({
    required Prediction item,
    required String label,
    required String address,
  }) async {
    final normalizedLabel = label.trim();
    final detailedAddress = address.trim();
    if (normalizedLabel.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterLabel.tr);
      return;
    }
    if (detailedAddress.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.noLocationsFound.tr);
      return;
    }
    if (c.isSavingPlace.value) return;

    c.isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final latLng = await c.mapHelper.getLatLngFromAddress(detailedAddress);
        final lat = latLng?.latitude ?? c.mapCenter.value.latitude;
        final lng = latLng?.longitude ?? c.mapCenter.value.longitude;
        final name = detailedAddress.split(',').first.trim().isEmpty
            ? detailedAddress
            : detailedAddress.split(',').first.trim();

        final request = SaveRecentAsFavoriteRequest(
          label: normalizedLabel.toLowerCase(),
          name: name,
          address: detailedAddress,
          lat: lat,
          lng: lng,
        );

        final result = await c.homeRepository.saveRecentAsFavorite(request);
        await result.fold(
          (failure) async =>
              AppDialogs.showErrorDialog(message: failure.message),
          (success) async {
            if (success) {
              await refreshSavedPlacesAfterMutation();
            }
          },
        );
      });
    } finally {
      c.isSavingPlace.value = false;
    }
  }

  /// Saves a recent destination as a labeled favorite.
  Future<void> saveAddressFromRecentLocation({
    required RecentDestination loc,
    required String label,
    required String address,
  }) async {
    final normalizedLabel = label.trim();
    final detailedAddress = address.trim();
    if (normalizedLabel.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterLabel.tr);
      return;
    }
    if (detailedAddress.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.noLocationsFound.tr);
      return;
    }
    if (c.isSavingPlace.value) return;

    c.isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final request = SaveRecentAsFavoriteRequest(
          label: normalizedLabel.toLowerCase(),
          name: detailedAddress.split(',').first.trim().isEmpty
              ? detailedAddress
              : detailedAddress.split(',').first.trim(),
          address: detailedAddress,
          lat: loc.lat ?? 0,
          lng: loc.lng ?? 0,
        );

        final result = await c.homeRepository.saveRecentAsFavorite(request);
        await result.fold(
          (failure) async =>
              AppDialogs.showErrorDialog(message: failure.message),
          (success) async {
            if (success) {
              await refreshSavedPlacesAfterMutation();
            }
          },
        );
      });
    } finally {
      c.isSavingPlace.value = false;
    }
  }

  /// Saves a free-form address (+ optional coords) as a labeled favorite.
  Future<void> saveAddressFromAddress({
    required String address,
    required String label,
    double? lat,
    double? lng,
  }) async {
    final normalizedLabel = label.trim();
    final detailedAddress = address.trim();
    if (normalizedLabel.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterLabel.tr);
      return;
    }
    if (detailedAddress.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.noLocationsFound.tr);
      return;
    }
    if (c.isSavingPlace.value) return;

    c.isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final latLng = (lat != null && lng != null)
            ? LatLng(lat, lng)
            : await c.mapHelper.getLatLngFromAddress(detailedAddress);
        final request = SaveRecentAsFavoriteRequest(
          label: normalizedLabel.toLowerCase(),
          name: detailedAddress.split(',').first.trim().isEmpty
              ? detailedAddress
              : detailedAddress.split(',').first.trim(),
          address: detailedAddress,
          lat: latLng?.latitude ?? c.mapCenter.value.latitude,
          lng: latLng?.longitude ?? c.mapCenter.value.longitude,
        );

        final result = await c.homeRepository.saveRecentAsFavorite(request);
        await result.fold(
          (failure) async =>
              AppDialogs.showErrorDialog(message: failure.message),
          (success) async {
            if (success) {
              await refreshSavedPlacesAfterMutation();
            }
          },
        );
      });
    } finally {
      c.isSavingPlace.value = false;
    }
  }
}
