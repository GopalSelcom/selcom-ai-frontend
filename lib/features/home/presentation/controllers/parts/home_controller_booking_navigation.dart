part of '../home_controller.dart';

/// Fare-estimate gate and navigation into vehicle selection / location selection.
///
/// Edit here for booking entry points from chips, recents, and search.
extension HomeBookingNavigationMethods on HomeController {
  Future<EstimateValidationOutcome> _validateEstimateBeforeBookingNavigation({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required LocationEntity destination,
    List<LocationEntity> stops = const [],
    bool showHomeFareEstimateLoader = false,
  }) async {
    if (showHomeFareEstimateLoader) {
      AppDialogs.showLoadingDialog();
    }
    try {
      final req = FareEstimateRequest(
        pickup: LocationEntity(
          lat: pickupLat,
          lng: pickupLng,
          address: pickupAddress,
        ),
        destination: destination,
        stops: stops,
      );

      final result = await homeRepository.estimateFare(req);

      return result.fold((failure) {
        final parsed = _parseEstimateFailure(failure.message);
        return EstimateValidationOutcome.failure(
          message: parsed.message,
          errorCode: parsed.errorCode,
        );
      }, (model) => EstimateValidationOutcome.success(estimate: model));
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      rethrow;
    } finally {
      if (showHomeFareEstimateLoader) {
        AppDialogs.dismissLoadingDialog();
      }
    }
  }

  ({String? errorCode, String message}) _parseEstimateFailure(
    String rawMessage,
  ) {
    final cleaned = rawMessage
        .replaceFirst('Exception:', '')
        .replaceFirst('Failure:', '')
        .trim();
    if (cleaned.isEmpty) {
      return (
        errorCode: null,
        message: AppStrings.unableToEstimateFareForThisRoute.tr,
      );
    }

    final parts = cleaned.split('|');
    if (parts.length > 1) {
      final code = parts.first.trim();
      final message = parts.sublist(1).join('|').trim();
      if (code.isNotEmpty) {
        return (
          errorCode: code,
          message: message.isEmpty
              ? AppStrings.unableToEstimateFareForThisRoute.tr
              : message,
        );
      }
    }

    return (errorCode: null, message: cleaned);
  }

  Future<void> _showEstimateValidationErrorAfterLoaderDismiss({
    required String message,
    String? errorCode,
  }) async {
    await Loader.instance.hideAsync();
    _showEstimateValidationError(message, errorCode: errorCode);
  }

  void _showEstimateValidationError(String message, {String? errorCode}) {
    AppDialogs.showErrorDialog(
      title: errorCode == 'VALID_PICKUP_DROP_TOO_CLOSE'
          ? AppStrings.validation.tr
          : AppStrings.error.tr,
      message: message,
    );
  }

  /// Fare estimate gate for location flows (including vehicle-selection edit).
  Future<EstimateValidationOutcome> validateEstimateForRoute({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required LocationEntity destination,
    List<LocationEntity> stops = const [],
  }) {
    return _validateEstimateBeforeBookingNavigation(
      pickupAddress: pickupAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destination: destination,
      stops: stops,
    );
  }

  Future<void> presentEstimateValidationError(
    EstimateValidationOutcome outcome,
  ) async {
    if (outcome.canProceed || outcome.errorMessage == null) return;
    await _showEstimateValidationErrorAfterLoaderDismiss(
      message: outcome.errorMessage!,
      errorCode: outcome.errorCode,
    );
  }

  /// Pickup = current map center; destination = saved place for [label] (Home / Office / Work / Other).
  Future<void> navigateToVehicleSelectionForSavedLabel(String label) async {
    final place = getSavedPlaceByLabel(label);
    if (place == null) {
      AppDialogs.showErrorDialog(
        title: AppStrings.addASavedPlace.tr,
        message: AppStrings.saveThisAddressFirstThenYouCanBookFromHere.tr,
      );
      return;
    }

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
        message:
            AppStrings.thisSavedPlaceIsMissingCoordinatesTrySavingItAgain.tr,
      );
      return;
    }

    final destAddr = (place.address ?? place.name ?? label).trim();
    if (destAddr.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.addressMissing.tr,
        message: AppStrings.thisSavedPlaceHasNoAddress.tr,
      );
      return;
    }

    if (!hasLocationPermission.value) {
      await _openLocationSelectionWithDestination(
        destAddr: destAddr,
        destLat: dLat,
        destLng: dLng,
        destinationPlaceId: place.id,
        analyticsEvent: 'home_saved_chip_location_selection',
        analyticsParams: {'label': label},
      );
      return;
    }

    await analyticsService.logEvent(
      'home_saved_chip_vehicle_selection',
      parameters: {'label': label},
    );

    final pickupAddr = activePickupAddress;
    final pickupLL = activePickupLatLng;
    final validation = await _validateEstimateBeforeBookingNavigation(
      pickupAddress: pickupAddr,
      pickupLat: pickupLL.latitude,
      pickupLng: pickupLL.longitude,
      destination: LocationEntity(lat: dLat, lng: dLng, address: destAddr),
      showHomeFareEstimateLoader: true,
    );
    if (!validation.canProceed) {
      await _showEstimateValidationErrorAfterLoaderDismiss(
        message: validation.errorMessage!,
        errorCode: validation.errorCode,
      );
      return;
    }

    // GetX lifecycle managed via AppRoutes and VehicleSelectionBinding.
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
        if (validation.estimate != null) ...{
          'initialFareEstimate': validation.estimate,
          'initialFareEstimateAt': validation.estimatedAt,
        },
      },
    );
  }

  /// Pickup = current map center; destination = specific [SavedPlace].
  Future<void> navigateToVehicleSelectionForSavedPlace(SavedPlace place) async {
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

    final destAddr = (place.address ?? place.name ?? AppStrings.savedPlace.tr)
        .trim();
    if (destAddr.isEmpty) {
      AppDialogs.showErrorDialog(
        title: AppStrings.addressMissing.tr,
        message: AppStrings.thisSavedPlaceHasNoAddress.tr,
      );
      return;
    }

    if (!hasLocationPermission.value) {
      await _openLocationSelectionWithDestination(
        destAddr: destAddr,
        destLat: dLat,
        destLng: dLng,
        destinationPlaceId: place.id,
        analyticsEvent: 'home_saved_item_location_selection',
        analyticsParams: {'id': place.id},
      );
      return;
    }

    await analyticsService.logEvent(
      'home_saved_item_vehicle_selection',
      parameters: {'id': place.id},
    );

    final pickupAddr = activePickupAddress;
    final pickupLL = activePickupLatLng;
    final validation = await _validateEstimateBeforeBookingNavigation(
      pickupAddress: pickupAddr,
      pickupLat: pickupLL.latitude,
      pickupLng: pickupLL.longitude,
      destination: LocationEntity(lat: dLat, lng: dLng, address: destAddr),
      showHomeFareEstimateLoader: true,
    );
    if (!validation.canProceed) {
      await _showEstimateValidationErrorAfterLoaderDismiss(
        message: validation.errorMessage!,
        errorCode: validation.errorCode,
      );
      return;
    }

    // GetX lifecycle managed via AppRoutes and VehicleSelectionBinding.
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
        if (validation.estimate != null) ...{
          'initialFareEstimate': validation.estimate,
          'initialFareEstimateAt': validation.estimatedAt,
        },
      },
    );
  }

  Future<void> _openLocationSelectionWithDestination({
    required String destAddr,
    required double destLat,
    required double destLng,
    String? destinationPlaceId,
    String? analyticsEvent,
    Map<String, dynamic>? analyticsParams,
  }) async {
    final trimmed = destAddr.trim();
    if (trimmed.isEmpty) return;

    if (analyticsEvent != null) {
      await analyticsService.logEvent(
        analyticsEvent,
        parameters: analyticsParams,
      );
    }

    final args = <String, dynamic>{
      'destination': trimmed,
      'destinationLat': destLat,
      'destinationLng': destLng,
      'activeSegmentIndex': 0,
      'clearPickupOnOpen': true,
    };
    if (destinationPlaceId != null && destinationPlaceId.isNotEmpty) {
      args['destinationPlaceId'] = destinationPlaceId;
    }
    if (Get.isRegistered<LocationSelectionController>()) {
      Get.delete<LocationSelectionController>();
    }
    await Get.toNamed(AppRoutes.locationSelection, arguments: args);
  }

  /// Opens location selection with [loc] as destination; pickup empty (GPS off).
  Future<void> openLocationSelectionForRecentDestination(
    RecentDestination loc,
  ) async {
    await _openLocationSelectionWithDestination(
      destAddr: loc.address ?? '',
      destLat: loc.lat ?? 0,
      destLng: loc.lng ?? 0,
      analyticsEvent: 'home_recent_item_location_selection',
      analyticsParams: {'address': (loc.address ?? '').trim()},
    );
  }

  /// Pickup = current map center; destination = [RecentDestination].
  ///
  /// When GPS/location is unavailable, opens location selection so the user can
  /// pick pickup; [loc] is pre-filled as destination.
  ///
  /// Set [showHomeFareEstimateLoader] when the tap originates from the home
  /// sheet so the home overlay can run during fare estimate.
  Future<void> navigateToVehicleSelectionForRecentDestination(
    RecentDestination loc, {
    bool showHomeFareEstimateLoader = false,
  }) async {
    final destAddr = (loc.address ?? '').trim();
    if (destAddr.isEmpty) return;

    if (!hasLocationPermission.value) {
      await openLocationSelectionForRecentDestination(loc);
      return;
    }

    await analyticsService.logEvent(
      'home_recent_item_vehicle_selection',
      parameters: {'address': destAddr},
    );

    final pickupAddr = activePickupAddress;
    final pickupLL = activePickupLatLng;
    final validation = await _validateEstimateBeforeBookingNavigation(
      pickupAddress: pickupAddr,
      pickupLat: pickupLL.latitude,
      pickupLng: pickupLL.longitude,
      destination: LocationEntity(
        lat: loc.lat ?? 0,
        lng: loc.lng ?? 0,
        address: destAddr,
      ),
      showHomeFareEstimateLoader: showHomeFareEstimateLoader,
    );
    if (!validation.canProceed) {
      await _showEstimateValidationErrorAfterLoaderDismiss(
        message: validation.errorMessage!,
        errorCode: validation.errorCode,
      );
      return;
    }

    // GetX lifecycle managed via AppRoutes and VehicleSelectionBinding.
    Get.toNamed(
      AppRoutes.booking,
      arguments: {
        'pickup': pickupAddr,
        'pickupLat': pickupLL.latitude,
        'pickupLng': pickupLL.longitude,
        'destination': destAddr,
        'destinationLat': loc.lat,
        'destinationLng': loc.lng,
        if (validation.estimate != null) ...{
          'initialFareEstimate': validation.estimate,
          'initialFareEstimateAt': validation.estimatedAt,
        },
      },
    );
  }

  /// Opens location flow with current [activePickupAddress] / [activePickupLatLng].
  /// Optional [preferredVehicle] is forwarded to booking → vehicle selection.
  Future<void> openLocationSelection({VehicleType? preferredVehicle}) async {
    await analyticsService.logEvent('search_opened');
    final args = <String, dynamic>{
      'pickup': activePickupAddress,
      'pickupLat': activePickupLatLng.latitude,
      'pickupLng': activePickupLatLng.longitude,
    };
    if (preferredVehicle != null) {
      if ((preferredVehicle.id ?? '').isNotEmpty) {
        args['preferredVehicleTypeId'] = preferredVehicle.id;
      }
      if ((preferredVehicle.name ?? '').isNotEmpty) {
        args['preferredVehicleName'] = preferredVehicle.name;
      }
      if ((preferredVehicle.key ?? '').isNotEmpty) {
        args['preferredVehicleKey'] = preferredVehicle.key;
      }
    }
    if (Get.isRegistered<LocationSelectionController>()) {
      Get.delete<LocationSelectionController>();
    }
    Get.toNamed(AppRoutes.locationSelection, arguments: args);
  }

  Future<void> openLocationSelectionWithPreferredVehicle(VehicleType vehicle) {
    return openLocationSelection(preferredVehicle: vehicle);
  }

  void closeLocationSelection() {
    Get.back();
  }

  Future<void> proceedToBookingFromLocationSelection({
    required String pickup,
    required List<String> destinations,
    String? destinationPlaceId,
    double? routePickupLat,
    double? routePickupLng,
    double? routeDestinationLat,
    double? routeDestinationLng,
    String? preferredVehicleTypeId,
    String? preferredVehicleName,
  }) async {
    AppLogger.d(
      '[LocationSelection] BookRide tapped: '
      'pickupTextLen=${pickup.trim().length}, '
      'destinationTextLen=${destinations.isNotEmpty ? destinations.last.trim().length : 0}, '
      'routePickup=($routePickupLat,$routePickupLng), '
      'routeDestination=($routeDestinationLat,$routeDestinationLng), '
      'destinationPlaceIdPresent=${(destinationPlaceId ?? '').trim().isNotEmpty}',
      tag: 'HomeController',
    );
    final List<String> items = destinations
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();
    if (items.isEmpty) {
      AppDialogs.showErrorDialog(
        message: AppStrings.pleaseEnterAtLeastOneDestination.tr,
      );
      return;
    }

    if (isProceedingToBooking.value) return;
    isProceedingToBooking.value = true;

    Map<String, dynamic>? bookingArguments;
    EstimateValidationOutcome? estimateValidationFailure;
    try {
      bookingArguments = await Loader.run(() async {
        double? pLat = routePickupLat;
        double? pLng = routePickupLng;

        // Resolve pickup if missing
        if ((pLat == null || pLng == null) && pickup.trim().isNotEmpty) {
          final resolvedPickup = await getLatLngFromAddress(pickup.trim());
          if (resolvedPickup != null) {
            pLat = resolvedPickup.latitude;
            pLng = resolvedPickup.longitude;
          }
        }
        pLat ??= mapCenter.value.latitude;
        pLng ??= mapCenter.value.longitude;

        final List<LocationEntity> resolvedDestinations = [];
        for (int i = 0; i < items.length; i++) {
          final addr = items[i];
          double? dLat;
          double? dLng;

          // Final destination is expected to be last in the list.
          if (i == items.length - 1) {
            dLat = routeDestinationLat;
            dLng = routeDestinationLng;
          }

          if (dLat == null || dLng == null) {
            final resolved = await getLatLngFromAddress(addr);
            if (resolved != null) {
              dLat = resolved.latitude;
              dLng = resolved.longitude;
            }
          }

          // Final fallback if resolution failed
          dLat ??= pLat;
          dLng ??= pLng;

          resolvedDestinations.add(
            LocationEntity(lat: dLat, lng: dLng, address: addr),
          );
        }

        if (resolvedDestinations.isEmpty) {
          AppDialogs.showErrorDialog(
            message: AppStrings.pleaseSelectAtLeastOneDestination.tr,
          );
          return null;
        }

        final validation = await _validateEstimateBeforeBookingNavigation(
          pickupAddress: pickup,
          pickupLat: pLat,
          pickupLng: pLng,
          destination: resolvedDestinations.last,
          stops: resolvedDestinations.length > 1
              ? resolvedDestinations.sublist(0, resolvedDestinations.length - 1)
              : const [],
        );
        if (!validation.canProceed) {
          estimateValidationFailure = validation;
          return null;
        }

        AppLogger.d(
          '[LocationSelection] Navigate booking args => '
          'pickup=($pLat,$pLng), destinationsCount=${resolvedDestinations.length}, '
          'preferredVehicleTypeId=${preferredVehicleTypeId ?? ''}',
          tag: 'HomeController',
        );

        return {
          'pickup': pickup,
          'destinations': resolvedDestinations,
          'pickupLat': pLat,
          'pickupLng': pLng,
          if (preferredVehicleTypeId != null &&
              preferredVehicleTypeId.isNotEmpty)
            'preferredVehicleTypeId': preferredVehicleTypeId,
          if (preferredVehicleName != null && preferredVehicleName.isNotEmpty)
            'preferredVehicleName': preferredVehicleName,
          if (validation.estimate != null) ...{
            'initialFareEstimate': validation.estimate,
            'initialFareEstimateAt': validation.estimatedAt,
          },
        };
      });
    } finally {
      isProceedingToBooking.value = false;
    }

    if (estimateValidationFailure != null) {
      await _showEstimateValidationErrorAfterLoaderDismiss(
        message: estimateValidationFailure!.errorMessage!,
        errorCode: estimateValidationFailure!.errorCode,
      );
      return;
    }

    if (bookingArguments == null) return;

    // Navigate only after the loader overlay is dismissed (root navigator).
    Get.offNamed(AppRoutes.booking, arguments: bookingArguments);
  }

  String vehicleExploreImageAsset(String vehicleName) {
    return VehicleImageUtils.imageAssetForVehicleType(vehicleName);
  }
}
