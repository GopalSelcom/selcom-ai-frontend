part of '../driver_accepted_controller.dart';

/// Bottom-sheet and map chip copy derived from ride status (ETA, titles, ratings).
///
/// Edit here for pickup / in-trip label rules and completion handoff copy.
extension DriverAcceptedStatusLabelsMethods on DriverAcceptedController {
  bool _isDriverArrivedAtPickupStatus(String rawStatus) {
    final normalized = normalizeRideStatusString(rawStatus);
    return normalized == 'driver_arrived' ||
        normalized == 'driverarrived' ||
        normalized.contains('driver_arrived') ||
        normalized.contains('driverarrived');
  }

  void _syncBottomSheetVehicleImage(String? vehicleType) {
    final previousAsset = bottomSheetVehicleImageAsset.value;
    bottomSheetVehicleImageAsset
        .value = VehicleImageUtils.imageAssetForVehicleType(
      vehicleType,
      // Keep previously resolved vehicle image when an event payload
      // doesn't include enough vehicle metadata (common during stop transitions).
      fallbackAsset: previousAsset.isNotEmpty
          ? previousAsset
          : AppAssets.imgCab,
    );
  }

  void _applyUnifiedDriverVehicleLine({
    required String modelName,
    required String plate,
    String fallbackModel = '',
  }) {
    final model = modelName.trim().isNotEmpty
        ? modelName.trim()
        : fallbackModel.trim();
    final rawRegistration = plate.trim();
    final registration = rawRegistration.isEmpty
        ? ''
        : TanzaniaLicensePlateFormatter.formatDisplay(rawRegistration);
    final line = [model, registration].where((e) => e.isNotEmpty).join(' - ');
    if (line.isNotEmpty) {
      driverVehicleLine.value = line;
    }
  }

  /// Prefer root `driver_avg_rating` from [ride:status_update], then snapshot `rating`.
  void _applyDriverRatingFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
    DriverSnapshot? d,
  ) {
    final fromRoot = _socketAverageRatingLabel(payload.driverAvgRating);
    if (fromRoot != null) {
      driverRating.value = fromRoot;
      return;
    }
    final snap = d?.rating;
    if (snap != null && snap > 0) {
      driverRating.value = snap.toStringAsFixed(1);
    }
  }

  String? _socketAverageRatingLabel(num? raw) {
    if (raw == null) return null;
    final v = raw.toDouble();
    if (v <= 0) return null;
    return v.toStringAsFixed(1);
  }

  /// Maps status → bottom sheet variant (pickup vs in-trip) and updates [currentRideStatus].
  void _applyBottomSheetStateForStatus(String rawStatus) {
    final normalizedStatus = normalizeRideStatusString(rawStatus);
    if (normalizedStatus.isEmpty) return;
    currentRideStatus.value = normalizedStatus;
    if (_isReachedStatusForSpeedHide(normalizedStatus)) {
      assignedDriverSpeed.value = 0;
    }

    if (normalizedStatus == 'cancelled' ||
        normalizedStatus == 'no_driver_found' ||
        normalizedStatus == 'no_drivers_found') {
      return;
    }

    RideBottomSheetState nextState = RideBottomSheetState.driverAssigned;
    if (normalizedStatus == 'ride_started' ||
        normalizedStatus == 'ride_in_progress' ||
        normalizedStatus == 'near_destination' ||
        normalizedStatus == 'completed' ||
        normalizedStatus == 'ride_completed') {
      nextState = RideBottomSheetState.rideStarted;
    }

    // Only allow state to move backwards if we are currently in 'rideCompleted'.
    // This maintains the fix for the "sticky finish button" while preventing
    // accidental regressions from 'rideStarted' back to 'driverAssigned'.
    final currentState = rideBottomSheetState.value;
    if (currentState == RideBottomSheetState.rideStarted &&
        nextState == RideBottomSheetState.driverAssigned) {
      return; // Block regression while trip is in progress
    }

    rideBottomSheetState.value = nextState;
    _syncSheetLayoutForCurrentStatus();
    if (_isDriverArrivedAtPickupStatus(normalizedStatus) ||
        nextState == RideBottomSheetState.rideStarted) {
      // Driver is free / trip started — no longer "finishing nearby".
      if (isDriverFinishingNearby.value) {
        isDriverFinishingNearby.value = false;
      }
    }
    if (_isDriverArrivedAtPickupStatus(normalizedStatus)) {
      _syncDriverArrivedPickupMessages();
    }
    final isCompletedStatus =
        normalizedStatus == 'completed' || normalizedStatus == 'ride_completed';
    if (isCompletedStatus) {
      _openCompletedRideDetailsScreen();
    }
  }

  /// Driver name for localized ride-status copy; falls back to generic "Driver".
  String get localizedDriverNameForCopy {
    final name = driverName.value.trim();
    return name.isNotEmpty ? name : AppStrings.driver.tr;
  }

  /// Pickup sheet + map chip copy when the driver is at pickup ([driver_arrived]).
  void _syncDriverArrivedPickupMessages() {
    isDriverFinishingNearby.value = false;
    assignedDriverSpeed.value = 0;
    arrivalLabel.value = AppStrings.driverArrivedPickupPrimary.tr;
    etaLabel.value = AppStrings.driverArrivedMapBadge.tr;
  }

  /// Second line on the driver-assigned pickup sheet (below the ETA row).
  ///
  /// Pickup progression: assigned → arriving → arrived (see [RidePickupStatusLabels]).
  String get driverPickupPhaseHeadline {
    switch (currentRideStatus.value) {
      case 'driver_arrived':
        return AppStrings.yourDriverHasArrived.tr;
      case 'driver_arriving':
        return AppStrings.driverHeadingTowardsYou.tr;
      case 'driver_assigned':
      case 'accepted':
        return AppStrings.driverHasAcceptedYourRide.tr;
      default:
        return AppStrings.driverIsHeadingToYourLocation.tr;
    }
  }

  /// Opens post-completion Ride Details once. Trusts realtime status over lagging HTTP.
  void _openCompletedRideDetailsScreen() {
    if (_openedCompletedRideDetails) return;
    if (_completionHandoffInProgress) {
      return;
    }
    final normalizedCurrentStatus = currentRideStatus.value
        .trim()
        .toLowerCase();
    if (normalizedCurrentStatus != 'completed' &&
        normalizedCurrentStatus != 'ride_completed') {
      return;
    }
    if (rideId.isEmpty) return;

    _completionHandoffInProgress = true;
    unawaited(
      _presentCompletedRideDetailsScreen().whenComplete(() {
        _completionHandoffInProgress = false;
      }),
    );
  }

  /// Fetches fresh details for the completed-ride screen.
  Future<void> _presentCompletedRideDetailsScreen() async {
    if (_openedCompletedRideDetails) return;
    if (rideId.isEmpty) return;

    final result = await rideRepository.getRideDetails(rideId);
    if (_openedCompletedRideDetails || _navigatedAway) return;

    final details = result.fold((_) => null, (r) => r);
    if (details == null) {
      AppDialogs.showErrorDialog(
        message: AppStrings.failedToLoadRideDetails.tr,
      );
      return;
    }

    // Guard: intermediate-stop "completed" (or stale socket) can race with
    // `ride_in_progress`. Never open completion UI unless HTTP confirms end.
    final detailsStatus = normalizeRideStatusString(details.status);
    if (detailsStatus != 'completed' && detailsStatus != 'ride_completed') {
      AppLogger.w(
        'Skip completion handoff; ride details status is $detailsStatus',
        tag: 'DriverAcceptedController',
      );
      await _applyRideDetailsFromModel(details.toRideModel());
      return;
    }

    // Normalize for details screen: force completed status and review UI.
    details.status = 'ride_completed';
    details.showReviewUi = true;

    _openedCompletedRideDetails = true;
    if (Get.isRegistered<RideDetailsController>()) {
      Get.delete<RideDetailsController>();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.off(
        () => RideDetailsScreen(
          ride: details,
          openedFromCompletionFlow: true,
          refreshOnInit: false,
        ),
        binding: BindingsBuilder(() {
          Get.put(
            RideDetailsController(
              ride: details,
              openedFromCompletionFlow: true,
              refreshOnInit: false,
            ),
          );
        }),
      );
    });
  }

  void _applyRouteFallbackForStatus(String rawStatus) {
    if (!_hasReceivedTrackingUpdate) return;
    // Only apply fallback if we don't already have points.
    if (routePoints.isNotEmpty) return;

    final status = rawStatus.trim();
    final canonicalStatus = status
        .replaceAll('ridestatus.', '')
        .replaceAll('RideStatus.', '')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m.group(1)}_${m.group(2)}',
        )
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    final normalizedStatus = canonicalStatus.toLowerCase();
    if (status.isEmpty) return;

    const pickupStatuses = {'accepted', 'driver_assigned', 'driver_arriving'};
    const dropStatuses = {
      'driver_arrived',
      'ride_started',
      'ride_in_progress',
      'near_destination',
      'ride_completed',
      'completed',
    };

    if (pickupStatuses.contains(normalizedStatus)) {
      _setPickupRouteFallback();
      return;
    }

    if (dropStatuses.contains(normalizedStatus)) {
      _setDropRouteFallback();
    }
  }

  /// In-trip sheet headline. Pickup-phase titles use [RidePickupStatusLabels] in `default`.
  String get rideProgressTitle {
    switch (currentRideStatus.value) {
      case 'ride_completed':
      case 'completed':
        return AppStrings.youHaveArrived.tr;
      case 'near_destination':
        return AppStrings.youAreAlmostThere.tr;
      case 'ride_in_progress':
        return AppStrings.onYourWayWithDriver.trParams({
          'driverName': localizedDriverNameForCopy,
        });
      case 'ride_started':
        return AppStrings.driverStartedYourRide.trParams({
          'driverName': localizedDriverNameForCopy,
        });
      default:
        return RidePickupStatusLabels.titleFor(currentRideStatus.value);
    }
  }

  /// In-trip / pickup supporting line (ETA-aware where applicable).
  String get rideProgressSubtitle {
    final etaSeconds = currentEtaSeconds.value;
    final etaMinutes = etaSeconds > 0 ? (etaSeconds / 60).ceil() : 0;
    final hasEta = etaMinutes > 0;
    switch (currentRideStatus.value) {
      case 'near_destination':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.approachingYourDestination.tr;
      case 'ride_in_progress':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.headingToYourDestination.tr;
      case 'ride_started':
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.tripHasStarted.tr;
      case 'driver_arrived':
        return AppStrings.driverArrivedPickupPrimary.tr;
      case 'driver_arriving':
        return AppStrings.driverHeadingTowardsYou.tr;
      case 'driver_assigned':
        return AppStrings.driverAssignedDescription.tr;
      case 'ride_completed':
      case 'completed':
        return arrivalDateLabel;
      default:
        return hasEta
            ? AppStrings.arrivedInMinutes.trParams({
                'minutes': etaMinutes.toString(),
              })
            : AppStrings.tripHasStarted.tr;
    }
  }

  int get rideEtaMinutes {
    final etaSeconds = currentEtaSeconds.value;
    if (etaSeconds <= 0) return 0;
    return (etaSeconds / 60).ceil();
  }

  /// Pickup-phase statuses: map chip + driver-assigned sheet use same rule.
  bool _isDriverHeadingToPickupForEta(String rideStatusRaw) {
    final s = normalizeRideStatusString(rideStatusRaw);
    if (s.isEmpty || s == 'driver_arrived') return false;
    return s == 'driver_assigned' ||
        s == 'driver_arriving' ||
        s == 'accepted' ||
        s == 'driver_en_route' ||
        s == 'en_route';
  }

  void _applySocketEtaSecondsToLabels(
    double etaSeconds, {
    required bool skipIfArrived,
  }) {
    if (skipIfArrived &&
        normalizeRideStatusString(currentRideStatus.value) ==
            'driver_arrived') {
      return;
    }
    if (etaSeconds <= 0) return;
    currentEtaSeconds.value = etaSeconds;
    final minutes = (etaSeconds / 60).ceil();
    // Keep ETA in state, but do not show the minutes chip while finishing nearby.
    if (!isDriverFinishingNearby.value) {
      etaLabel.value = AppStrings.minutesShortCount.trParams({
        'count': '$minutes',
      });
    }
    final rideStatus = normalizeRideStatusString(currentRideStatus.value);
    if (_isDriverHeadingToPickupForEta(rideStatus) &&
        !isDriverFinishingNearby.value) {
      arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
    }
  }

  /// Driver-assigned sheet first line — matches map chip math on [currentEtaSeconds].
  String get driverAssignedSheetArrivalEtaLine {
    final st = normalizeRideStatusString(currentRideStatus.value);
    if (st == 'driver_arrived') {
      return arrivalLabel.value;
    }
    if (isDriverFinishingNearby.value && _isDriverHeadingToPickupForEta(st)) {
      return AppStrings.driverFinishingNearbyTrip.tr;
    }
    final secs = currentEtaSeconds.value;
    if (secs > 0 && _isDriverHeadingToPickupForEta(st)) {
      final minutes = (secs / 60).ceil();
      return AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
    }
    return arrivalLabel.value;
  }

  /// Map ETA chip — hidden while the chained driver is finishing another trip.
  bool get shouldShowMapEtaChip {
    if (hasRideLoadError) return false;
    if (isDriverFinishingNearby.value) return false;
    final st = normalizeRideStatusString(currentRideStatus.value);
    if (st == 'driver_arrived') return true;
    return currentEtaSeconds.value > 0 || etaLabel.value.trim().isNotEmpty;
  }

  bool get shouldShowRideEtaBadge {
    final status = currentRideStatus.value;
    if (rideEtaMinutes <= 0) return false;
    return status == 'ride_started' ||
        status == 'ride_in_progress' ||
        status == 'near_destination';
  }

  void _setDriverFinishingNearby(bool finishing) {
    final wasFinishing = isDriverFinishingNearby.value;
    isDriverFinishingNearby.value = finishing;
    if (finishing) {
      // Replaces "Driver will arrive in X min..." while the prior trip is active.
      arrivalLabel.value = AppStrings.driverFinishingNearbyTrip.tr;
      _lastDriverRotationSamplePosition = null;
      _syncDriverHeadingFromActiveRoute(animate: true);
      return;
    }
    if (!wasFinishing) return;
    _lastDriverRotationSamplePosition = null;
    _restorePickupArrivalLabelsAfterFinishingNearby();
  }

  /// When chaining ends (`driver_finishing_nearby` → false), always drop the
  /// finishing-trip copy. Prefer cached ETA minutes; otherwise show arriving.
  void _restorePickupArrivalLabelsAfterFinishingNearby() {
    final st = normalizeRideStatusString(currentRideStatus.value);
    if (!_isDriverHeadingToPickupForEta(st)) return;

    final secs = currentEtaSeconds.value;
    if (secs > 0) {
      final minutes = (secs / 60).ceil();
      etaLabel.value = AppStrings.minutesShortCount.trParams({
        'count': '$minutes',
      });
      arrivalLabel.value = AppStrings.driverWillArrivingInMinutes.trParams({
        'minutes': '$minutes',
      });
      return;
    }

    // No ETA cached yet — clear finishing text so the old arrival line can show.
    etaLabel.value = AppStrings.arriving.tr;
    arrivalLabel.value = AppStrings.driverIsArriving.tr;
  }

  String get rideVehicleLabel {
    final value = driverVehicleLine.value.trim();
    if (value.isNotEmpty) return value.split('-').first.trim();
    return AppStrings.boda.tr;
  }

  String get arrivalDateLabel {
    final value = ride.value;
    if (value == null) return '05th Mar 2026 . 08:08PM';
    return DateFormat('dd\'th\' MMM yyyy . hh:mma').format(value.createdAt);
  }

  /// Total Fare rows from `fare_breakdown.line_items` (API order).
  List<FareBreakdownDisplayRow> get fareLineRows {
    final lineItems = ride.value?.fareBreakdown?.lineItems;
    if (!FareBreakdownDisplay.hasLineItems(lineItems)) {
      return const [];
    }
    return FareBreakdownDisplay.rowsFromLineItems(lineItems!);
  }

  bool get hasFareLineItems => fareLineRows.isNotEmpty;

  String _firstAddressLine(String address) {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return AppStrings.unknownLocation.tr;
    return trimmed.split(',').first.trim();
  }

  bool isNearDestination() {
    return currentRideStatus.value.toLowerCase() == 'near_destination';
  }

  String priceFormatter(int? amount) {
    if (amount == null) return '0';
    return NumberFormat('#,###').format(amount);
  }
}
