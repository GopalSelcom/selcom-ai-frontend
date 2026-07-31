part of '../driver_accepted_controller.dart';

/// Live map for SCR-11: markers, camera bounds, route geometry, speed/ETA overlay.
///
/// Edit here for map chrome / polyline / driver marker behavior without touching
/// cancel, payment, or socket subscription wiring.
extension DriverAcceptedMapMethods on DriverAcceptedController {
  bool _isReachedStatusForSpeedHide(String rawStatus) {
    final normalized = normalizeRideStatusString(rawStatus);
    if (_reachedStatusesForSpeedHide.contains(normalized)) return true;
    if (_isDriverArrivedAtPickupStatus(rawStatus)) return true;
    if (normalized.contains('near_destination') ||
        normalized.contains('neardestination')) {
      return true;
    }
    return normalized == 'completed' ||
        normalized == 'ride_completed' ||
        normalized.contains('ride_completed');
  }

  bool _isDriverAtPickupProximity(LatLng? driverPosition) {
    if (rideBottomSheetState.value != RideBottomSheetState.driverAssigned) {
      return false;
    }
    if (driverPosition == null) return false;
    return _calculateDistanceInMeters(driverPosition, pickupLatLng) <=
        _driverAtPickupProximityMeters;
  }

  bool _shouldHideDriverSpeedFor({
    required String status,
    required LatLng? driverPosition,
    required double speedMps,
  }) {
    if (_isReachedStatusForSpeedHide(status)) return true;
    if (_isDriverAtPickupProximity(driverPosition)) return true;
    return speedMps <= 0.5;
  }

  bool get _shouldHideDriverSpeedLabel {
    // Read reactive deps so Obx rebuilds on status, speed, and driver position.
    final status = currentRideStatus.value;
    final driverPosition = assignedDriverLocation.value;
    rideBottomSheetState.value;
    return _shouldHideDriverSpeedFor(
      status: status,
      driverPosition: driverPosition,
      speedMps: assignedDriverSpeed.value,
    );
  }

  String get formattedSpeedLabel {
    if (_shouldHideDriverSpeedLabel) return '';
    final speedKmh = (assignedDriverSpeed.value * 3.6).round();
    return speedKmh > 0 ? '$speedKmh km/h' : '';
  }

  List<RideStopModel> get mapIntermediateStops {
    final fromRide = _intermediateStopsFromRideStops();
    if (fromRide.isNotEmpty) return fromRide;
    return _intermediateStopsFromRouteDestinations();
  }

  List<RideStopModel> _intermediateStopsFromRideStops() {
    final stops = ride.value?.stops ?? const <RideStopModel>[];
    if (stops.isEmpty) return const [];

    final filtered = stops
        .where(
          (stop) =>
              !MapRouteMarkerUtils.stopMatchesDestination(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                destinationLat: destinationLatLng.latitude,
                destinationLng: destinationLatLng.longitude,
                destinationAddress: destinationAddress,
              ) &&
              !MapRouteMarkerUtils.stopMatchesPickup(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                pickupLat: pickupLatLng.latitude,
                pickupLng: pickupLatLng.longitude,
                pickupAddress: pickupAddress,
              ),
        )
        .toList();

    final orderedEntries = filtered.asMap().entries.toList()
      ..sort((a, b) {
        final byRouteIndex = a.value.index.compareTo(b.value.index);
        if (byRouteIndex != 0) return byRouteIndex;
        return a.key.compareTo(b.key);
      });

    return MapRouteMarkerUtils.dedupeByLocation(
      items: orderedEntries.map((entry) => entry.value).toList(),
      lat: (stop) => stop.lat,
      lng: (stop) => stop.lng,
      address: (stop) => stop.address,
    );
  }

  List<RideStopModel> _intermediateStopsFromRouteDestinations() {
    if (routeDestinations.length <= 1) return const [];

    final candidates = routeDestinations
        .take(routeDestinations.length - 1)
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => RideStopModel(
            index: entry.key + 1,
            lat: entry.value.lat,
            lng: entry.value.lng,
            address: entry.value.address,
            status: 'pending',
          ),
        )
        .where(
          (stop) =>
              !MapRouteMarkerUtils.stopMatchesDestination(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                destinationLat: destinationLatLng.latitude,
                destinationLng: destinationLatLng.longitude,
                destinationAddress: destinationAddress,
              ) &&
              !MapRouteMarkerUtils.stopMatchesPickup(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                pickupLat: pickupLatLng.latitude,
                pickupLng: pickupLatLng.longitude,
                pickupAddress: pickupAddress,
              ),
        )
        .toList();

    return MapRouteMarkerUtils.dedupeByLocation(
      items: candidates,
      lat: (stop) => stop.lat,
      lng: (stop) => stop.lng,
      address: (stop) => stop.address,
    );
  }

  String routeLetterForIntermediateIndex(int sequentialIndex) =>
      MapRouteMarkerUtils.letterAt(sequentialIndex + 1);

  BitmapDescriptor redRouteLetterIconForSequentialIndex(int sequentialIndex) {
    final letter = routeLetterForIntermediateIndex(sequentialIndex);
    return RouteMapMarkerIcons.cached(
          letter: letter,
          color: RoutePinLetterStyle.intermediateColor(sequentialIndex),
        ) ??
        dropIcon.value ??
        BitmapDescriptor.defaultMarker;
  }

  bool get usesMultiStopRouteMarkers {
    return MapRouteMarkerUtils.usesMultiStopMarkers(
      isMultiStopFlag: ride.value?.isMultiStop ?? routeDestinations.length > 1,
      intermediateStopCount: mapIntermediateStops.length,
    );
  }

  Future<void> _ensureRouteLetterIcons() async {
    if (_routeLetterIconsLoaded) return;

    await RouteMapMarkerIcons.ensureLetterPinCache();
    for (int i = 0; i < MapRouteMarkerUtils.routeLetters.length - 1; i++) {
      final letter = MapRouteMarkerUtils.letterAt(i + 1);
      _redRouteLetterIcons[letter] = RouteMapMarkerIcons.cached(
        letter: letter,
        color: RoutePinLetterStyle.intermediateColor(i),
      )!;
    }
    for (int i = 1; i < MapRouteMarkerUtils.routeLetters.length; i++) {
      final letter = MapRouteMarkerUtils.routeLetters[i];
      _greenRouteLetterIcons[letter] = RouteMapMarkerIcons.cached(
        letter: letter,
        color: RoutePinLetterStyle.destinationColor,
      )!;
    }

    _routeLetterIconsLoaded = true;
  }

  Future<void> _loadMarkerIcons() async {
    final loadToken = ++_markerIconLoadToken;
    await _ensureRouteLetterIcons();
    if (loadToken != _markerIconLoadToken) return;

    final bool isMulti = usesMultiStopRouteMarkers;

    if (!isMulti) {
      pickupIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'P',
        color: RoutePinLetterStyle.pickupColor,
      );
      dropIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'D',
        color: RoutePinLetterStyle.destinationColor,
      );
      stopIcons.clear();
      return;
    }

    final intermediateCount = mapIntermediateStops.length;
    pickupIcon.value = await RouteMapMarkerIcons.pin(
      letter: RoutePinLetterStyle.pickupLetter(
        intermediateStopCount: intermediateCount,
      ),
      color: RoutePinLetterStyle.pickupColor,
    );

    final destLetter = MapRouteMarkerUtils.letterAt(
      MapRouteMarkerUtils.destinationLetterIndex(
        intermediateStopCount: intermediateCount,
      ),
    );
    dropIcon.value = _greenRouteLetterIcons[destLetter];

    final icons = List<BitmapDescriptor>.generate(
      intermediateCount,
      (i) => _redRouteLetterIcons[MapRouteMarkerUtils.letterAt(i + 1)]!,
    );
    stopIcons.assignAll(icons);
  }

  /// Updates [routeTarget] only — polylines come from `ride:tracking_update`
  /// `route_geometry` via [TrackingRouteGeometryUtils.shouldDrawPolyline].
  void _setDropRouteFallback() {
    routeTarget.value = 'drop_off';
  }

  void _setPickupRouteFallback() {
    routeTarget.value = 'pick_up';
  }

  void _clearRouteAwaitingTrackingUpdate() {
    if (routePoints.isEmpty) return;
    routePoints.clear();
    isInitialRouteLoaded.value = false;
  }

  void _markInitialRouteReady() {
    if (!isInitialRouteLoaded.value) {
      isInitialRouteLoaded.value = true;
    }
  }

  // Future<void> _loadMarkerIcon() async {
  //   try {
  //     await rootBundle.load(AppAssets.gariPlus);
  //     assignedDriverMarkerIcon.value = await BitmapDescriptor.asset(
  //       const ImageConfiguration(size: Size(36, 36)),
  //       AppAssets.gariPlus,
  //     );
  //   } catch (_) {}
  // }

  void _syncDestinationFromRide(RideModel? r) {
    if (r == null) return;
    final d = r.destination;
    if (d.lat != 0 && d.lng != 0) {
      destinationLatLng = LatLng(d.lat, d.lng);
    }
    final addr = d.address.trim();
    if (addr.isNotEmpty && addr != destinationAddress) {
      destinationAddress = addr;
      _refreshMapRouteHeader();
    }
    final stops = r.stops;
    if (stops.isEmpty) {
      summaryIntermediateStops.clear();
      return;
    }
    final intermediates = mapIntermediateStops;
    if (intermediates.isEmpty) {
      summaryIntermediateStops.clear();
      return;
    }
    summaryIntermediateStops.assignAll(
      intermediates
          .map((s) => s.address.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  Future<void> loadDriverIcon({String? vehicleType}) async {
    try {
      final assetPath = MapVehicleMarkerUtils.markerAssetForVehicleType(
        vehicleType,
      );
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        assetPath,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        "Error loading map marker icon ($vehicleType): $e",
        tag: 'DriverAcceptedController',
        error: e,
        stackTrace: stackTrace,
      );
      assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        AppAssets.mapMarkerCab,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    }
  }

  void onMapCreated(GoogleMapController c) {
    mapController = c;
    _fitRouteBounds();
    scheduleAssignedEtaOverlayRefresh();
  }

  void scheduleAssignedEtaOverlayRefresh() {
    Future.microtask(refreshAssignedDriverEtaOverlay);
  }

  Future<void> refreshAssignedDriverEtaOverlay() async {
    final ctrl = mapController;
    final pos = animatedRiderLocation.value ?? assignedDriverLocation.value;
    if (ctrl == null || pos == null) {
      assignedDriverEtaScreenPx.value = null;
      return;
    }
    final px = await AppMapService.screenOffsetFor(ctrl, pos);
    assignedDriverEtaScreenPx.value = px;
  }

  void recenterMap() {
    if (onRecenterPressed != null) {
      onRecenterPressed!();
    } else {
      _fitRouteBounds(force: true);
    }
  }

  Future<void> _fitRouteBounds({bool force = false}) async {
    final ctrl = mapController;
    if (ctrl == null) return;

    // Throttling: prevent rapid animations unless forced (e.g. by recenter button)
    // At most one update every 5 seconds to avoid flickering on every socket event.
    final now = DateTime.now();
    if (!force &&
        _lastCameraUpdate != null &&
        now.difference(_lastCameraUpdate!) < const Duration(seconds: 5)) {
      return;
    }

    final points = <LatLng>[];
    final assigned = assignedDriverLocation.value;

    // "Show driver to pickup only" when in driverAssigned status
    if (rideBottomSheetState.value == RideBottomSheetState.driverAssigned) {
      if (assigned != null) points.add(assigned);
      points.add(pickupLatLng);
    } else {
      // Focusing on segment: Pickup/Current -> Destination
      if (assigned != null) points.add(assigned);
      points.add(destinationLatLng);

      // Also include all stops for multi-stop rides to show the whole route
      final stops = ride.value?.stops ?? [];
      for (final s in stops) {
        points.add(LatLng(s.lat, s.lng));
      }
    }

    if (routePoints.isNotEmpty) {
      points.addAll(routePoints);
    }

    // Sanity Filter: Remove (0,0) and extreme outliers relative to the driver.
    if (assigned != null) {
      final filtered = points.where((p) {
        if (p.latitude == 0 && p.longitude == 0) return false;
        final dLat = (p.latitude - assigned.latitude).abs();
        final dLng = (p.longitude - assigned.longitude).abs();
        return dLat < 0.2 && dLng < 0.2; // Approx 20km
      }).toList();
      points.clear();
      points.addAll(filtered);
    } else {
      points.removeWhere((p) => p.latitude == 0 && p.longitude == 0);
    }

    if (points.isEmpty) return;
    _lastCameraUpdate = now;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    try {
      // Ensure the bounds have at least some area to prevent rendering glitches
      double latDelta = (maxLat - minLat).abs();
      double lngDelta = (maxLng - minLng).abs();
      if (latDelta < 0.001) {
        minLat -= 0.001;
        maxLat += 0.001;
      }
      if (lngDelta < 0.001) {
        minLng -= 0.001;
        maxLng += 0.001;
      }

      await ctrl.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          72, // Slightly more padding for comfort
        ),
      );
    } catch (e) {
      // Fallback if bounds animation fails
      if (points.isNotEmpty) {
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(points.first, 15));
      }
    }
  }

  /// During chained pickup, GPS movement can point away from the drawn route.
  /// Prefer the active polyline bearing so the marker faces the route line.
  double _resolveAssignedDriverHeading({
    required LatLng currentPosition,
    LatLng? previousPosition,
    double? headingDegrees,
    required double previousRotation,
    double speedMps = 0,
  }) {
    if (isDriverFinishingNearby.value && routePoints.length >= 2) {
      final routeBearing = TrackingRouteGeometryUtils.bearingAlongRouteAt(
        routePoints,
        currentPosition,
      );
      if (routeBearing != null) {
        return routeBearing;
      }
    }

    return MapVehicleMarkerUtils.resolveMarkerRotation(
      previousPosition: previousPosition,
      currentPosition: currentPosition,
      headingDegrees: headingDegrees,
      previousRotation: previousRotation,
      speedMps: speedMps,
    );
  }

  void _syncDriverHeadingFromActiveRoute({bool animate = false}) {
    if (!isDriverFinishingNearby.value || routePoints.length < 2) return;

    final driverPos =
        assignedDriverLocation.value ??
        mapWidgetKey.currentState?.currentAnimatedPosition;
    if (driverPos == null) return;

    final routeBearing = TrackingRouteGeometryUtils.bearingAlongRouteAt(
      routePoints,
      driverPos,
    );
    if (routeBearing == null) return;

    assignedDriverHeading.value = routeBearing;
    if (animate) {
      mapWidgetKey.currentState?.updateRiderPosition(
        driverPos,
        rotation: routeBearing,
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  /// Applies `route_geometry` from tracking/status payloads without re-fitting on duplicates.
  void _applyRouteGeometryFromPayload({
    required String routeTarget,
    required List<List<double>>? coordinates,
    required bool fitCameraOnChange,
  }) {
    if (routeTarget != 'pick_up' && routeTarget != 'drop_off') return;

    this.routeTarget.value = routeTarget;
    if (!_hasReceivedTrackingUpdate) return;

    final kind = TrackingRouteGeometryUtils.classify(coordinates);
    switch (kind) {
      case TrackingRouteGeometryKind.empty:
        // Wait for the next tracking payload with path geometry — never draw
        // a straight pickup→destination fallback line.
        if (routePoints.isEmpty) {
          _markInitialRouteReady();
        }
        return;
      case TrackingRouteGeometryKind.repeatedLocation:
      case TrackingRouteGeometryKind.path:
        final nextPoints = TrackingRouteGeometryUtils.pointsForMap(coordinates);
        _markInitialRouteReady();
        if (TrackingRouteGeometryUtils.routesEquivalent(
          routePoints,
          nextPoints,
        )) {
          return;
        }
        routePoints.assignAll(nextPoints);
        if (fitCameraOnChange &&
            kind == TrackingRouteGeometryKind.path &&
            nextPoints.length >= 2) {
          _fitRouteBounds();
        }
        _syncDriverHeadingFromActiveRoute(animate: true);
        return;
    }
  }

  /// Calculates the distance between two points in meters using Haversine formula.
  double _calculateDistanceInMeters(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // meters
    final double dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final double dLng = _degreesToRadians(p2.longitude - p1.longitude);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(p1.latitude)) *
            math.cos(_degreesToRadians(p2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  String _normalizeRouteTarget(String? target) {
    final t = (target ?? '').trim().toLowerCase();
    if (t == 'pickup' || t == 'pick_up') return 'pick_up';
    if (t == 'dropoff' || t == 'drop_off' || t == 'destination') {
      return 'drop_off';
    }
    return '';
  }

  RideStatus _mapBottomSheetToRideStatus(RideBottomSheetState state) {
    switch (state) {
      case RideBottomSheetState.driverAssigned:
        return RideStatus.driverAssigned;
      case RideBottomSheetState.rideStarted:
        return RideStatus.rideStarted;
    }
  }

  String get mapRoutePickupLabel {
    if (pickupAddress.trim().isEmpty) {
      return AppStrings.currentLocation.tr;
    }
    final line = compactAddressLine(pickupAddress);
    return line.isEmpty ? AppStrings.currentLocation.tr : line;
  }

  String get mapRouteDestinationLabel {
    if (destinationAddress.trim().isEmpty) {
      return AppStrings.destination.tr;
    }
    final line = compactAddressLine(destinationAddress);
    return line.isEmpty ? AppStrings.destination.tr : line;
  }

  void _refreshMapRouteHeader() => update([DriverAcceptedController.mapRouteHeaderId]);

  String get pickupTitle => _firstAddressLine(pickupAddress);

  String get destinationTitle => _firstAddressLine(destinationAddress);
}
