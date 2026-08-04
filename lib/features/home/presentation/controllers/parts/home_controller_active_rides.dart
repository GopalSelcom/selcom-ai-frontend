part of '../home_controller.dart';

/// Active-ride polling, stack expand/collapse, and open-ride navigation from Home.
class HomeActiveRidesHelper {
  HomeActiveRidesHelper(this.c);

  /// Parent [HomeController] — shared home state and lifecycle.
  final HomeController c;

  /// Count of extra active rides beyond the primary card (for the "+N" badge).
  int get additionalActiveRidesCount =>
      c.activeRides.length > 1 ? c.activeRides.length - 1 : 0;

  /// True when more than one in-progress ride should be stacked on Home.
  bool get hasMultipleActiveRides => c.activeRides.length > 1;

  /// Stops periodic active-ride polling (e.g. after session revoked on another device).
  void stopActiveRidePolling() {
    c._activeRidePollingTimer?.cancel();
    c._activeRidePollingTimer = null;
  }

  /// Fetches the latest active-ride list (throttled unless [force]).
  Future<void> refreshActiveRide({bool force = false}) async {
    if (SessionExpiryService.isHandling) return;
    if (c._isRefreshingActiveRide) return;
    if (!force &&
        c._lastActiveRideRefreshAt != null &&
        DateTime.now().difference(c._lastActiveRideRefreshAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    c._isRefreshingActiveRide = true;
    c._lastActiveRideRefreshAt = DateTime.now();
    final result = await c.homeRepository.getActiveRide();
    result.fold((_) {}, _applyActiveRideResponse);
    c._isRefreshingActiveRide = false;
  }

  /// Starts a 1-minute periodic active-ride refresh.
  void _startActiveRidePolling() {
    stopActiveRidePolling();
    c._activeRidePollingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (SessionExpiryService.isHandling) {
        stopActiveRidePolling();
        return;
      }
      refreshActiveRide(force: true);
    });
  }

  /// Applies the active-rides API payload to [activeRide] / [activeRides].
  void _applyActiveRideResponse(
    active_ride_api.ActiveRideResponseModel? activeRideResponse,
  ) {
    // API shape: `{ count, rides: [{ ride, socket_rooms }, ...] }` (legacy fields still supported).
    final rides = parseActiveRidesFromResponse(activeRideResponse?.data);
    if (rides.isEmpty) {
      c.activeRide.value = null;
      c.activeRides.clear();
      c.isActiveRidesExpanded.value = false;
      c._socketService.leaveJoinedRideRoom();
      return;
    }

    c.activeRides.assignAll(rides);
    final primaryRide = rides.first;
    c.activeRide.value = primaryRide;
    if (!hasMultipleActiveRides) {
      c.isActiveRidesExpanded.value = false;
    }
    _syncLiveActivity(primaryRide);
  }

  /// Whether the stacked active-rides UI can expand.
  bool get canExpandActiveRides => hasMultipleActiveRides;

  /// Expands the multi-ride stack on Home.
  void expandActiveRidesStack() {
    if (!canExpandActiveRides || c.isActiveRidesExpanded.value) return;
    c.isActiveRidesExpanded.value = true;
  }

  /// Collapses the multi-ride stack on Home.
  void collapseActiveRidesStack() {
    if (!c.isActiveRidesExpanded.value) return;
    c.isActiveRidesExpanded.value = false;
  }

  /// Title line for an active-ride card (route summary or fallback).
  String activeRideRouteTitle(RideModel ride) {
    final route = _activeRideRouteSummary(ride);
    if (route.isNotEmpty) return route;
    return AppStrings.activeRide.tr;
  }

  /// Remaining-time label for an active-ride card (empty when unknown).
  String activeRideRemainingLabel(RideModel ride) {
    final minutes = ride.durationMinutes;
    if (minutes <= 0) return '';
    return AppStrings.activeRideMinRemains.trParams({'minutes': '$minutes'});
  }

  /// Short "pickup to destination" summary for card titles.
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

  /// Vehicle image asset path for an active-ride card.
  String activeRideVehicleImageAsset(RideModel ride) {
    return ActiveRideVehicleImageResolver.resolveAsset(
      ride: ride,
      vehicleTypeCatalog: c.vehicleTypes,
    );
  }

  /// First comma-separated segment of an address for compact UI.
  String _shortPlaceLabel(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(',');
    final first = parts.first.trim();
    return first.isEmpty ? trimmed : first;
  }

  /// Mirrors the primary active ride into the platform Live Activity.
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

  /// Opens the ongoing-ride screen for [ride] (or the primary active ride).
  Future<void> openActiveRide([RideModel? ride]) async {
    collapseActiveRidesStack();
    final rideValue = ride ?? c.activeRide.value;
    if (rideValue == null) return;
    final rideId = rideValue.id.trim();
    if (rideId.isEmpty) return;

    final detailsResult = await c.homeRepository.getRideDetails(rideId);
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
        final mergedNoShow = detailsModel.noShow?.mergingDisplayFrom(rideValue.noShow);
        final freshRide = detailsModel.copyWith(
          cancelInfo: detailsModel.cancelInfo ?? rideValue.cancelInfo,
          noShow: mergedNoShow,
          clearNoShow: mergedNoShow == null,
          routeDeviation:
              detailsModel.routeDeviation ?? rideValue.routeDeviation,
        );
        await c._socketService.connect();
        c._socketService.switchRideRoom(rideId: freshId);
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
