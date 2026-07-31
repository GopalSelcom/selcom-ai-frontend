part of '../home_controller.dart';

/// Recent destinations, saved places, favorite chips, and address-header pickup.
extension HomePlacesMethods on HomeController {
  /// Reloads recent destinations into the Home list (not the dedicated screen list).
  Future<void> reloadRecentDestinations() async {
    final result = await homeRepository.getRecentDestinations();
    result.fold((_) => null, (destinations) {
      recentDestinations.assignAll(destinations);
      invalidateHomeSheetMeasurement();
    });
  }

  List<RecentDestination> get recentDestinationsPreview {
    if (recentDestinations.length <= 3) return recentDestinations;
    return recentDestinations.take(3).toList(growable: false);
  }

  bool get canViewMoreRecentLocations => recentDestinations.length > 3;

  Future<void> openRecentLocationsScreen() async {
    // Show shimmer immediately (screen builds from the same controller).
    isLoadingRecentLocationsScreen.value = true;
    recentDestinationsScreen.clear();
    Get.to<void>(() => const RecentLocationsScreen());

    // Avoid 2nd API call when Home already fetched recent destinations.
    unawaited(() async {
      // If Home already has data, reuse it (still shows shimmer briefly).
      if (recentDestinations.isNotEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        recentDestinationsScreen.assignAll(recentDestinations);
        isLoadingRecentLocationsScreen.value = false;
      } else {
        // If Home is still loading, wait a bit for its request to finish.
        if (isLoadingHomeData.value) {
          final start = DateTime.now();
          while (recentDestinations.isEmpty &&
              DateTime.now().difference(start) < const Duration(seconds: 5)) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }

        // Reuse if Home populated; otherwise fallback to fetch (only then).
        if (recentDestinations.isNotEmpty) {
          recentDestinationsScreen.assignAll(recentDestinations);
          isLoadingRecentLocationsScreen.value = false;
        } else {
          await loadRecentLocationsScreen();
        }
      }
    }());
  }

  Future<void> loadRecentLocationsScreen() async {
    try {
      isLoadingRecentLocationsScreen.value = true;
      final result = await homeRepository.getRecentDestinations();
      result.fold((_) => null, (destinations) {
        recentDestinationsScreen.assignAll(destinations);
        invalidateHomeSheetMeasurement();
      });
    } finally {
      isLoadingRecentLocationsScreen.value = false;
    }
  }

  Future<void> refreshRecentDestinations() async {
    await loadRecentLocationsScreen();
  }

  Future<void> _searchPlaces(String input) async {
    isSearching.value = true;
    final result = await homeRepository.autocomplete(input: input);
    result.fold((failure) => suggestions.clear(), (list) {
      suggestions
        ..clear()
        ..addAll(list?.data?.predictions ?? []);
    });
    isSearching.value = false;
  }

  Future<void> selectPlace(Prediction place) async {
    final description = (place.description)?.trim();
    if (description == null || description.isEmpty) return;
    _pushRecentSearch(description);
    currentMapAddress.value = description;
  }

  Future<void> saveRecentAsFavorite({
    required RecentDestination loc,
    required String label,
  }) async {
    if (isSavingPlace.value) return;
    isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final request = SaveRecentAsFavoriteRequest(
          label: label.toLowerCase(),
          name: (loc.address ?? '').split(',').first,
          address: loc.address ?? '',
          lat: loc.lat ?? 0,
          lng: loc.lng ?? 0,
        );

        final result = await homeRepository.saveRecentAsFavorite(request);
        await result.fold((failure) => null, (success) async {
          if (success) {
            await refreshSavedPlacesAfterMutation();
          }
        });
      });
    } finally {
      isSavingPlace.value = false;
    }
  }

  Future<void> toggleFavoriteForRecent(RecentDestination loc) async {
    final saved = getSavedPlaceFor(loc.address ?? '', null);
    if (saved?.id != null) {
      await _confirmAndDeleteSavedPlace(saved!);
      return;
    }
    await toggleAddAddressBottomSheetForRecent(loc);
  }

  SavedPlace? getSavedPlaceByLabel(String label) {
    return SavedPlacesOrdering.placeForLabel(savedPlaces, label);
  }

  /// Saved places not bound to a preset chip (custom labels or duplicate presets).
  /// Used only on Home to show additional chips after the four presets.
  List<SavedPlace> get savedPlacesBeyondPresetSlots {
    return SavedPlacesOrdering.beyondPresetSlots(savedPlaces);
  }

  String? getSavedPlaceSubtitle(String label) {
    final place = getSavedPlaceByLabel(label);
    final value = place?.address?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  void markRecentHomeChip(String key) {
    recentHomeChipKey.value = key;
  }

  void onHomePresetChipTap(String canonical, SavedPlace? place) {
    markRecentHomeChip(FavoriteLocationChipsRow.presetChipKey(canonical));
    if (place == null) {
      Get.toNamed(AppRoutes.selectSavedLocation, arguments: canonical);
      return;
    }
    unawaited(navigateToVehicleSelectionForSavedLabel(canonical));
  }

  void onHomeExtraChipTap(SavedPlace place) {
    markRecentHomeChip(FavoriteLocationChipsRow.extraChipKey(place));
    unawaited(navigateToVehicleSelectionForSavedPlace(place));
  }

  void onHomePresetChipLongPress(String canonical) {
    markRecentHomeChip(FavoriteLocationChipsRow.presetChipKey(canonical));
    Get.toNamed(AppRoutes.selectSavedLocation, arguments: canonical);
  }

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
    final result = await homeRepository.getSavedPlaces();
    result.fold((_) => null, (response) {
      savedPlaces.assignAll(
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

  void _syncSelectedPickupAfterSavedPlacesLoad() {
    if (savedPlaces.isEmpty &&
        selectedPickupSavedPlaceId.value != HomeController._currentLocationPlaceId) {
      selectedPickupSavedPlaceId.value = null;
      return;
    }
    final current = selectedPickupSavedPlaceId.value;
    if (current == HomeController._currentLocationPlaceId) return;
    final stillValid =
        current != null && savedPlaces.any((p) => p.id == current);
    if (!stillValid) {
      selectedPickupSavedPlaceId.value = savedPlaces.isNotEmpty
          ? savedPlaces.first.id
          : HomeController._currentLocationPlaceId;
    }
  }

  Future<void> selectSavedPlaceAsPickup(SavedPlace place) async {
    if (place.id == HomeController._currentLocationPlaceId) {
      selectedPickupSavedPlaceId.value = HomeController._currentLocationPlaceId;
      isSavedPlacesExpanded.value = false;
      await _getCurrentLocation();
      return;
    }
    selectedPickupSavedPlaceId.value = place.id;
    isSavedPlacesExpanded.value = false;

    final latLng = _latLngFromSavedPlace(place);
    final addr = (place.address ?? place.name ?? '').trim();

    if (latLng != null) {
      _ignoreSelectionReset = true;
      mapCenter.value = latLng;
      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 16),
        );
      }
      if (addr.isEmpty) await _reverseGeocodeAtCenter();
    }
  }

  bool isSavedPlaceSelectedAsPickup(String? placeId) {
    if (placeId == null || placeId.isEmpty) return false;
    return selectedPickupSavedPlaceId.value == placeId;
  }

  void _pushRecentSearch(String value) {
    recentSearches.removeWhere(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    recentSearches.insert(0, value);
    if (recentSearches.length > 8) {
      recentSearches.removeRange(8, recentSearches.length);
    }
  }

  // ── Home screen UI orchestration (keep branching / navigation out of widgets) ──

  /// Collapsed: active pickup only; expanded: all saved places (tap one to set pickup).
  List<SavedPlace> get addressHeaderPlacesToShow {
    final current = currentLocationHeaderPlace;
    final active = activePickupSavedPlace;
    if (isSavedPlacesExpanded.value) {
      return <SavedPlace>[current, ...savedPlaces];
    }
    if (selectedPickupSavedPlaceId.value == HomeController._currentLocationPlaceId) {
      return <SavedPlace>[current];
    }
    if (active != null) {
      return <SavedPlace>[active];
    }
    return <SavedPlace>[current];
  }

  void toggleAddressHeaderExpansion() {
    if (savedPlaces.isNotEmpty) {
      isSavedPlacesExpanded.toggle();
    }
  }

  double get addressHeaderChevronTurns =>
      isSavedPlacesExpanded.value ? 0.5 : 0.0;

  /// Chip subtitle; Home falls back to current map address when saved line is empty.
  String? chipSubtitleFor(String label) {
    final s = getSavedPlaceSubtitle(label);
    if (s != null && s.trim().isNotEmpty) return s;
    if (label.toLowerCase() == 'home') return currentMapAddress.value;
    return null;
  }

  String recentDestinationTitleLine(RecentDestination loc) {
    final address = loc.address ?? '';
    final parts = address.split(',');
    if (parts.isEmpty) return address;
    final first = parts.first.trim();
    return first.isEmpty ? address : first;
  }

  bool get shouldShowRecentSection =>
      isLoadingHomeData.value || recentDestinations.isNotEmpty;

  bool get shouldShowVehicleSection =>
      isLoadingHomeData.value || vehicleTypes.isNotEmpty;

  SavedPlace? getSavedPlaceFor(String address, String? placeId) {
    if (savedPlaces.isEmpty) return null;
    return savedPlaces.firstWhereOrNull(
      (s) =>
          (placeId != null && s.id == placeId) ||
          s.address?.trim().toLowerCase() == address.trim().toLowerCase(),
    );
  }

  /// Saved place = favourite in product terms (no separate favourites list).
  bool isPlaceFavorite(String address, String? placeId) {
    return getSavedPlaceFor(address, placeId) != null;
  }

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
      isSaving: isSavingPlace,
      savedPlaces: savedPlaces,
      onSave: (label, resolvedAddress) async {
        await onSave(label, resolvedAddress);
        if (!isSavingPlace.value) {
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
        final result = await homeRepository.deleteSavedPlace(savedPlaceId);
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
    if (isSavingPlace.value) return;

    isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final latLng = await getLatLngFromAddress(detailedAddress);
        final lat = latLng?.latitude ?? mapCenter.value.latitude;
        final lng = latLng?.longitude ?? mapCenter.value.longitude;
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

        final result = await homeRepository.saveRecentAsFavorite(request);
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
      isSavingPlace.value = false;
    }
  }

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
    if (isSavingPlace.value) return;

    isSavingPlace.value = true;
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

        final result = await homeRepository.saveRecentAsFavorite(request);
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
      isSavingPlace.value = false;
    }
  }

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
    if (isSavingPlace.value) return;

    isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final latLng = (lat != null && lng != null)
            ? LatLng(lat, lng)
            : await getLatLngFromAddress(detailedAddress);
        final request = SaveRecentAsFavoriteRequest(
          label: normalizedLabel.toLowerCase(),
          name: detailedAddress.split(',').first.trim().isEmpty
              ? detailedAddress
              : detailedAddress.split(',').first.trim(),
          address: detailedAddress,
          lat: latLng?.latitude ?? mapCenter.value.latitude,
          lng: latLng?.longitude ?? mapCenter.value.longitude,
        );

        final result = await homeRepository.saveRecentAsFavorite(request);
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
      isSavingPlace.value = false;
    }
  }
}
