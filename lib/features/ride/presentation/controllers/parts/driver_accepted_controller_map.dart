part of '../driver_accepted_controller.dart';

/// Live map for SCR-11: markers, camera bounds, route geometry, speed/ETA overlay.
///
/// Edit here for map chrome / polyline / driver marker behavior without touching
/// cancel, payment, or socket subscription wiring.
class DriverAcceptedMapHelper {
  DriverAcceptedMapHelper(this.c);

  /// Parent [DriverAcceptedController] — shared ride state and lifecycle.
  final DriverAcceptedController c;

  /// Statuses where the driver speed chip should stay hidden.
  bool _isReachedStatusForSpeedHide(String rawStatus) {
    final normalized = normalizeRideStatusString(rawStatus);
    if (_reachedStatusesForSpeedHide.contains(normalized)) return true;
    if (c.statusLabelsHelper._isDriverArrivedAtPickupStatus(rawStatus)) return true;
    if (normalized.contains('near_destination') ||
        normalized.contains('neardestination')) {
      return true;
    }
    return normalized == 'completed' ||
        normalized == 'ride_completed' ||
        normalized.contains('ride_completed');
  }

  /// True when driver is within pickup proximity during assigned phase.
  bool _isDriverAtPickupProximity(LatLng? driverPosition) {
    if (c.rideBottomSheetState.value != RideBottomSheetState.driverAssigned) {
      return false;
    }
    if (driverPosition == null) return false;
    return _calculateDistanceInMeters(driverPosition, c.pickupLatLng) <=
        _driverAtPickupProximityMeters;
  }

  /// Whether speed overlay should hide for status, proximity, or near-zero speed.
  bool _shouldHideDriverSpeedFor({
    required String status,
    required LatLng? driverPosition,
    required double speedMps,
  }) {
    if (_isReachedStatusForSpeedHide(status)) return true;
    if (_isDriverAtPickupProximity(driverPosition)) return true;
    return speedMps <= 0.5;
  }

  /// Reactive wrapper so Obx rebuilds when status/speed/position change.
  bool get _shouldHideDriverSpeedLabel {
    // Read reactive deps so Obx rebuilds on status, speed, and driver position.
    final status = c.currentRideStatus.value;
    final driverPosition = c.assignedDriverLocation.value;
    c.rideBottomSheetState.value;
    return _shouldHideDriverSpeedFor(
      status: status,
      driverPosition: driverPosition,
      speedMps: c.assignedDriverSpeed.value,
    );
  }

  /// Formatted km/h label for the map speed chip (empty when hidden).
  String get formattedSpeedLabel {
    if (_shouldHideDriverSpeedLabel) return '';
    final speedKmh = (c.assignedDriverSpeed.value * 3.6).round();
    return speedKmh > 0 ? '$speedKmh km/h' : '';
  }

  /// Intermediate stops for map pins (ride.stops preferred, else destinations).
  List<RideStopModel> get mapIntermediateStops {
    final fromRide = _intermediateStopsFromRideStops();
    if (fromRide.isNotEmpty) return fromRide;
    return _intermediateStopsFromRouteDestinations();
  }

  /// Intermediate stops derived from ride.stops, excluding pickup/drop.
  List<RideStopModel> _intermediateStopsFromRideStops() {
    final stops = c.ride.value?.stops ?? const <RideStopModel>[];
    if (stops.isEmpty) return const [];

    final filtered = stops
        .where(
          (stop) =>
              !MapRouteMarkerUtils.stopMatchesDestination(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                destinationLat: c.destinationLatLng.latitude,
                destinationLng: c.destinationLatLng.longitude,
                destinationAddress: c.destinationAddress,
              ) &&
              !MapRouteMarkerUtils.stopMatchesPickup(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                pickupLat: c.pickupLatLng.latitude,
                pickupLng: c.pickupLatLng.longitude,
                pickupAddress: c.pickupAddress,
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

  /// Intermediate stops from multi-destination list (all but final drop).
  List<RideStopModel> _intermediateStopsFromRouteDestinations() {
    if (c.routeDestinations.length <= 1) return const [];

    final candidates = c.routeDestinations
        .take(c.routeDestinations.length - 1)
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
                destinationLat: c.destinationLatLng.latitude,
                destinationLng: c.destinationLatLng.longitude,
                destinationAddress: c.destinationAddress,
              ) &&
              !MapRouteMarkerUtils.stopMatchesPickup(
                stopLat: stop.lat,
                stopLng: stop.lng,
                stopAddress: stop.address,
                pickupLat: c.pickupLatLng.latitude,
                pickupLng: c.pickupLatLng.longitude,
                pickupAddress: c.pickupAddress,
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

  /// Route letter for intermediate stop at [sequentialIndex] (0-based).
  String routeLetterForIntermediateIndex(int sequentialIndex) =>
      MapRouteMarkerUtils.letterAt(sequentialIndex + 1);

  /// Cached red letter pin for an intermediate stop, or drop icon fallback.
  BitmapDescriptor redRouteLetterIconForSequentialIndex(int sequentialIndex) {
    final letter = routeLetterForIntermediateIndex(sequentialIndex);
    return RouteMapMarkerIcons.cached(
          letter: letter,
          color: RoutePinLetterStyle.intermediateColor(sequentialIndex),
        ) ??
        c.dropIcon.value ??
        BitmapDescriptor.defaultMarker;
  }

  /// Whether multi-stop letter pins should be used instead of P/D.
  bool get usesMultiStopRouteMarkers {
    return MapRouteMarkerUtils.usesMultiStopMarkers(
      isMultiStopFlag: c.ride.value?.isMultiStop ?? c.routeDestinations.length > 1,
      intermediateStopCount: mapIntermediateStops.length,
    );
  }

  /// Prefetches letter-pin bitmaps into controller caches once.
  Future<void> _ensureRouteLetterIcons() async {
    if (c._routeLetterIconsLoaded) return;

    await RouteMapMarkerIcons.ensureLetterPinCache();
    for (int i = 0; i < MapRouteMarkerUtils.routeLetters.length - 1; i++) {
      final letter = MapRouteMarkerUtils.letterAt(i + 1);
      c._redRouteLetterIcons[letter] = RouteMapMarkerIcons.cached(
        letter: letter,
        color: RoutePinLetterStyle.intermediateColor(i),
      )!;
    }
    for (int i = 1; i < MapRouteMarkerUtils.routeLetters.length; i++) {
      final letter = MapRouteMarkerUtils.routeLetters[i];
      c._greenRouteLetterIcons[letter] = RouteMapMarkerIcons.cached(
        letter: letter,
        color: RoutePinLetterStyle.destinationColor,
      )!;
    }

    c._routeLetterIconsLoaded = true;
  }

  /// Loads pickup/drop/stop marker icons for single- or multi-stop rides.
  Future<void> _loadMarkerIcons() async {
    final loadToken = ++c._markerIconLoadToken;
    await _ensureRouteLetterIcons();
    if (loadToken != c._markerIconLoadToken) return;

    final bool isMulti = usesMultiStopRouteMarkers;

    if (!isMulti) {
      c.pickupIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'P',
        color: RoutePinLetterStyle.pickupColor,
      );
      c.dropIcon.value = await RouteMapMarkerIcons.pin(
        letter: 'D',
        color: RoutePinLetterStyle.destinationColor,
      );
      c.stopIcons.clear();
      return;
    }

    final intermediateCount = mapIntermediateStops.length;
    c.pickupIcon.value = await RouteMapMarkerIcons.pin(
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
    c.dropIcon.value = c._greenRouteLetterIcons[destLetter];

    final icons = List<BitmapDescriptor>.generate(
      intermediateCount,
      (i) => c._redRouteLetterIcons[MapRouteMarkerUtils.letterAt(i + 1)]!,
    );
    c.stopIcons.assignAll(icons);
  }

  /// Updates [routeTarget] only — polylines come from `ride:tracking_update`
  /// `route_geometry` via [TrackingRouteGeometryUtils.shouldDrawPolyline].
  void _setDropRouteFallback() {
    c.routeTarget.value = 'drop_off';
  }

  /// Sets [routeTarget] to pick_up when polyline is still empty.
  void _setPickupRouteFallback() {
    c.routeTarget.value = 'pick_up';
  }

  /// Clears drawn route until the next tracking geometry arrives.
  void _clearRouteAwaitingTrackingUpdate() {
    if (c.routePoints.isEmpty) return;
    c.routePoints.clear();
    c.isInitialRouteLoaded.value = false;
  }

  /// Marks that initial route readiness is satisfied (even if empty).
  void _markInitialRouteReady() {
    if (!c.isInitialRouteLoaded.value) {
      c.isInitialRouteLoaded.value = true;
    }
  }

  // Future<void> _loadMarkerIcon() async {
  //   try {
  //     await rootBundle.load(AppAssets.gariPlus);
  //     c.assignedDriverMarkerIcon.value = await BitmapDescriptor.asset(
  //       const ImageConfiguration(size: Size(36, 36)),
  //       AppAssets.gariPlus,
  //     );
  //   } catch (_) {}
  // }

  /// Syncs destination LatLng/address and summary intermediate stop labels.
  void _syncDestinationFromRide(RideModel? r) {
    if (r == null) return;
    final d = r.destination;
    if (d.lat != 0 && d.lng != 0) {
      c.destinationLatLng = LatLng(d.lat, d.lng);
    }
    final addr = d.address.trim();
    if (addr.isNotEmpty && addr != c.destinationAddress) {
      c.destinationAddress = addr;
      _refreshMapRouteHeader();
    }
    final stops = r.stops;
    if (stops.isEmpty) {
      c.summaryIntermediateStops.clear();
      return;
    }
    final intermediates = mapIntermediateStops;
    if (intermediates.isEmpty) {
      c.summaryIntermediateStops.clear();
      return;
    }
    c.summaryIntermediateStops.assignAll(
      intermediates
          .map((s) => s.address.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  /// Loads the assigned-driver vehicle marker SVG for [vehicleType].
  Future<void> loadDriverIcon({String? vehicleType}) async {
    try {
      final assetPath = MapVehicleMarkerUtils.markerAssetForVehicleType(
        vehicleType,
      );
      c.assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
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
      c.assignedDriverMarkerIcon.value = await MapMarkerUtils.getSvgMarker(
        AppAssets.mapMarkerCab,
        MapVehicleMarkerUtils.defaultMarkerWidth,
      );
    }
  }

  /// Stores the Google Map controller and fits bounds / ETA overlay.
  void onMapCreated(GoogleMapController ctrl) {
    c.mapController = ctrl;
    _fitRouteBounds();
    scheduleAssignedEtaOverlayRefresh();
  }

  /// Schedules a microtask refresh of the driver ETA screen overlay.
  void scheduleAssignedEtaOverlayRefresh() {
    Future.microtask(refreshAssignedDriverEtaOverlay);
  }

  /// Projects driver position to screen pixels for the floating ETA chip.
  Future<void> refreshAssignedDriverEtaOverlay() async {
    final ctrl = c.mapController;
    final pos = c.animatedRiderLocation.value ?? c.assignedDriverLocation.value;
    if (ctrl == null || pos == null) {
      c.assignedDriverEtaScreenPx.value = null;
      return;
    }
    final px = await AppMapService.screenOffsetFor(ctrl, pos);
    c.assignedDriverEtaScreenPx.value = px;
  }

  /// Recenter via callback if set, else force-fit route bounds.
  void recenterMap() {
    if (c.onRecenterPressed != null) {
      c.onRecenterPressed!();
    } else {
      _fitRouteBounds(force: true);
    }
  }

  /// Animates camera to cover driver + pickup/drop (and stops) with throttle.
  Future<void> _fitRouteBounds({bool force = false}) async {
    final ctrl = c.mapController;
    if (ctrl == null) return;

    // Throttling: prevent rapid animations unless forced (e.g. by recenter button)
    // At most one update every 5 seconds to avoid flickering on every socket event.
    final now = DateTime.now();
    if (!force &&
        c._lastCameraUpdate != null &&
        now.difference(c._lastCameraUpdate!) < const Duration(seconds: 5)) {
      return;
    }

    final points = <LatLng>[];
    final assigned = c.assignedDriverLocation.value;

    // "Show driver to pickup only" when in driverAssigned status
    if (c.rideBottomSheetState.value == RideBottomSheetState.driverAssigned) {
      if (assigned != null) points.add(assigned);
      points.add(c.pickupLatLng);
    } else {
      // Focusing on segment: Pickup/Current -> Destination
      if (assigned != null) points.add(assigned);
      points.add(c.destinationLatLng);

      // Also include all stops for multi-stop rides to show the whole route
      final stops = c.ride.value?.stops ?? [];
      for (final s in stops) {
        points.add(LatLng(s.lat, s.lng));
      }
    }

    if (c.routePoints.isNotEmpty) {
      points.addAll(c.routePoints);
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
    c._lastCameraUpdate = now;

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
    if (c.isDriverFinishingNearby.value && c.routePoints.length >= 2) {
      final routeBearing = TrackingRouteGeometryUtils.bearingAlongRouteAt(
        c.routePoints,
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

  /// Points marker rotation along the active polyline while finishing nearby.
  void _syncDriverHeadingFromActiveRoute({bool animate = false}) {
    if (!c.isDriverFinishingNearby.value || c.routePoints.length < 2) return;

    final driverPos =
        c.assignedDriverLocation.value ??
        c.mapWidgetKey.currentState?.currentAnimatedPosition;
    if (driverPos == null) return;

    final routeBearing = TrackingRouteGeometryUtils.bearingAlongRouteAt(
      c.routePoints,
      driverPos,
    );
    if (routeBearing == null) return;

    c.assignedDriverHeading.value = routeBearing;
    if (animate) {
      c.mapWidgetKey.currentState?.updateRiderPosition(
        driverPos,
        rotation: routeBearing,
        duration: const Duration(milliseconds: 800),
      );
    }
  }

  /// Applies `route_geometry` from tracking/status payloads without re-fitting on duplicates.
  void _applyRouteGeometryFromPayload({
    required String nextRouteTarget,
    required List<List<double>>? coordinates,
    required bool fitCameraOnChange,
  }) {
    if (nextRouteTarget != 'pick_up' && nextRouteTarget != 'drop_off') return;

    c.routeTarget.value = nextRouteTarget;
    if (!c._hasReceivedTrackingUpdate) return;

    final kind = TrackingRouteGeometryUtils.classify(coordinates);
    switch (kind) {
      case TrackingRouteGeometryKind.empty:
        // Wait for the next tracking payload with path geometry — never draw
        // a straight pickup→destination fallback line.
        if (c.routePoints.isEmpty) {
          _markInitialRouteReady();
        }
        return;
      case TrackingRouteGeometryKind.repeatedLocation:
      case TrackingRouteGeometryKind.path:
        final nextPoints = TrackingRouteGeometryUtils.pointsForMap(coordinates);
        _markInitialRouteReady();
        if (TrackingRouteGeometryUtils.routesEquivalent(
          c.routePoints,
          nextPoints,
        )) {
          return;
        }
        c.routePoints.assignAll(nextPoints);
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
    final double haversine = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * haversine;
  }

  /// Converts degrees to radians.
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Normalizes route_target strings to `pick_up` / `drop_off` (or empty).
  String _normalizeRouteTarget(String? target) {
    final t = (target ?? '').trim().toLowerCase();
    if (t == 'pickup' || t == 'pick_up') return 'pick_up';
    if (t == 'dropoff' || t == 'drop_off' || t == 'destination') {
      return 'drop_off';
    }
    return '';
  }

  /// Maps bottom-sheet state to [RideStatus] for chat/comms arguments.
  RideStatus _mapBottomSheetToRideStatus(RideBottomSheetState state) {
    switch (state) {
      case RideBottomSheetState.driverAssigned:
        return RideStatus.driverAssigned;
      case RideBottomSheetState.rideStarted:
        return RideStatus.rideStarted;
    }
  }

  /// Compact pickup label for the map route header.
  String get mapRoutePickupLabel {
    if (c.pickupAddress.trim().isEmpty) {
      return AppStrings.currentLocation.tr;
    }
    final line = compactAddressLine(c.pickupAddress);
    return line.isEmpty ? AppStrings.currentLocation.tr : line;
  }

  /// Compact destination label for the map route header.
  String get mapRouteDestinationLabel {
    if (c.destinationAddress.trim().isEmpty) {
      return AppStrings.destination.tr;
    }
    final line = compactAddressLine(c.destinationAddress);
    return line.isEmpty ? AppStrings.destination.tr : line;
  }

  /// Rebuilds the map route header GetBuilder region.
  void _refreshMapRouteHeader() => c.update([DriverAcceptedController.mapRouteHeaderId]);

  /// First address line for the pickup pin/title.
  String get pickupTitle => c.statusLabelsHelper._firstAddressLine(c.pickupAddress);

  /// First address line for the destination pin/title.
  String get destinationTitle => c.statusLabelsHelper._firstAddressLine(c.destinationAddress);
}
