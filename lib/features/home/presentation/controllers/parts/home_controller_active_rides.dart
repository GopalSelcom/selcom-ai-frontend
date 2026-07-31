part of '../home_controller.dart';

/// Active-ride polling, stack expand/collapse, and open-ride navigation from Home.
extension HomeActiveRidesMethods on HomeController {
  int get additionalActiveRidesCount =>
      activeRides.length > 1 ? activeRides.length - 1 : 0;

  bool get hasMultipleActiveRides => activeRides.length > 1;

  /// Stops periodic active-ride polling (e.g. after session revoked on another device).
  void stopActiveRidePolling() {
    _activeRidePollingTimer?.cancel();
    _activeRidePollingTimer = null;
  }

  Future<void> refreshActiveRide({bool force = false}) async {
    if (SessionExpiryService.isHandling) return;
    if (_isRefreshingActiveRide) return;
    if (!force &&
        _lastActiveRideRefreshAt != null &&
        DateTime.now().difference(_lastActiveRideRefreshAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    _isRefreshingActiveRide = true;
    _lastActiveRideRefreshAt = DateTime.now();
    final result = await homeRepository.getActiveRide();
    result.fold((_) {}, _applyActiveRideResponse);
    _isRefreshingActiveRide = false;
  }

  void _startActiveRidePolling() {
    stopActiveRidePolling();
    _activeRidePollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (SessionExpiryService.isHandling) {
        stopActiveRidePolling();
        return;
      }
      refreshActiveRide(force: true);
    });
  }

  void _applyActiveRideResponse(
    active_ride_api.ActiveRideResponseModel? activeRideResponse,
  ) {
    // API shape: `{ count, rides: [{ ride, socket_rooms }, ...] }` (legacy fields still supported).
    final rides = parseActiveRidesFromResponse(activeRideResponse?.data);
    if (rides.isEmpty) {
      activeRide.value = null;
      activeRides.clear();
      isActiveRidesExpanded.value = false;
      _socketService.leaveJoinedRideRoom();
      return;
    }

    activeRides.assignAll(rides);
    final primaryRide = rides.first;
    activeRide.value = primaryRide;
    if (!hasMultipleActiveRides) {
      isActiveRidesExpanded.value = false;
    }
    _syncLiveActivity(primaryRide);
  }

  bool get canExpandActiveRides => hasMultipleActiveRides;

  void expandActiveRidesStack() {
    if (!canExpandActiveRides || isActiveRidesExpanded.value) return;
    isActiveRidesExpanded.value = true;
  }

  void collapseActiveRidesStack() {
    if (!isActiveRidesExpanded.value) return;
    isActiveRidesExpanded.value = false;
  }

  String activeRideRouteTitle(RideModel ride) {
    final route = _activeRideRouteSummary(ride);
    if (route.isNotEmpty) return route;
    return AppStrings.activeRide.tr;
  }

  String activeRideRemainingLabel(RideModel ride) {
    final minutes = ride.durationMinutes;
    if (minutes <= 0) return '';
    return AppStrings.activeRideMinRemains.trParams({'minutes': '$minutes'});
  }

  String _activeRideRouteSummary(RideModel ride) {
    final pickup = _shortPlaceLabel(ride.pickup.address);
    final destination = _shortPlaceLabel(ride.destination.address);
    if (pickup.isEmpty && destination.isEmpty) {
      return '';
    }
    if (pickup.isEmpty) return destination;
    if (destination.isEmpty) return pickup;
    return '$pickup to $destination';
  }

  String activeRideVehicleImageAsset(RideModel ride) {
    return ActiveRideVehicleImageResolver.resolveAsset(
      ride: ride,
      vehicleTypeCatalog: vehicleTypes,
    );
  }

  String _shortPlaceLabel(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(',');
    final first = parts.first.trim();
    return first.isEmpty ? trimmed : first;
  }

  Future<void> _syncLiveActivity(RideModel ride) async {
    try {
      final status = ride.status.name;
      final isCompleted = ride.status == RideStatus.rideCompleted;
      final isCancelled =
          ride.status == RideStatus.cancelled ||
          ride.status == RideStatus.noDriverFound;

      if (isCompleted || isCancelled) {
        await LiveActivityManager().endActivity(ride.id);
        return;
      }

      // Sync Live Activity

      await LiveActivityManager().startActivity(
        orderId: ride.id,
        status: status.toUpperCase(),
        driverName:
            ride.driverSnapshot?.name ?? AppStrings.searchingForDriver.tr,
        vehicleName:
            '${ride.vehicleSnapshot?.vehicleMake ?? ''} ${ride.vehicleSnapshot?.vehicleModel ?? ''}'
                .trim(),
        driverAvatarUrl: ride.driverSnapshot?.avatarUrl ?? '',
        plateNumber: ride.vehicleSnapshot?.plateNumber ?? '',
        isCompleted: isCompleted,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d('❌ Error syncing Live Activity: $e', tag: 'HOME_CONTROLLER');
    }
  }

  Future<void> openActiveRide([RideModel? ride]) async {
    collapseActiveRidesStack();
    final rideValue = ride ?? activeRide.value;
    if (rideValue == null) return;
    final rideId = rideValue.id.trim();
    if (rideId.isEmpty) return;

    final detailsResult = await homeRepository.getRideDetails(rideId);
    detailsResult.fold(
      (failure) => AppDialogs.showErrorDialog(message: failure.message),
      (freshRideDetails) async {
        final freshId = (freshRideDetails.id ?? '').trim();
        if (freshId.isEmpty || freshId != rideId) {
          AppDialogs.showErrorDialog(
            message: AppStrings.failedToLoadRideDetails.tr,
          );
          return;
        }
        final detailsModel = freshRideDetails.toRideModel();
        // Active / status `no_show` includes title/subtitle; ride details often
        // only has fire_at/fee — merge so the pickup wait banner keeps its copy.
        final mergedNoShow = detailsModel.noShow == null
            ? null
            : detailsModel.noShow!.mergingDisplayFrom(rideValue.noShow);
        final freshRide = detailsModel.copyWith(
          cancelInfo: detailsModel.cancelInfo ?? rideValue.cancelInfo,
          noShow: mergedNoShow,
          clearNoShow: mergedNoShow == null,
          routeDeviation:
              detailsModel.routeDeviation ?? rideValue.routeDeviation,
        );
        await _socketService.connect();
        _socketService.switchRideRoom(rideId: freshId);
        // 🛰️ Sync Live Activity view when user taps "View Trip"
        LiveActivityManager().startActivity(
          orderId: freshRide.id,
          status: freshRide.status.name,
          driverName: freshRide.driverSnapshot?.name ?? '',
          vehicleName: freshRide.vehicleSnapshot?.vehicleType ?? '',
          plateNumber: freshRide.vehicleSnapshot?.plateNumber ?? '',
          isCompleted: freshRide.status == RideStatus.rideCompleted,
          updateIfExists: true,
        );
        // openActiveRide already refreshed this ride — skip SCR-11 bootstrap fetch.
        navigateToOngoingRide(freshRide, skipInitialRideDetailsFetch: true);
      },
    );
  }
}
