part of '../home_controller.dart';

/// Home map: GPS permission, camera, reverse geocode, pickup pin / radius.
///
/// Edit here for map/location behavior without touching booking or places lists.
class HomeMapHelper {
  HomeMapHelper(this.c);

  /// Parent [HomeController] — shared home state and lifecycle.
  final HomeController c;

  /// Loads the blue pickup circle marker used on the home map.
  Future<void> _loadMapIcons() async {
    c.pickupMarkerIcon.value = await MapMarkerUtils.createCustomCircleMarker(
      color: AppColors.mapPickupMarkerBlue,
      // Match the blue used in vehicle selection
      size: 60,
    );
  }

  /// Recenter on device GPS; requests permission and may open settings.
  Future<void> recenterMap() async {
    if (c._isResolvingLocationPermission) return;
    c._isResolvingLocationPermission = true;
    try {
      // GPS tap: request permission if needed; settings dialog only here.
      c.selectedPickupSavedPlaceId.value = HomeController._currentLocationPlaceId;
      c.isSavedPlacesExpanded.value = false;
      await _getCurrentLocation(
        requestPermissionIfDenied: true,
        showLocationSettingsDialogIfBlocked: true,
      );
    } finally {
      c._isResolvingLocationPermission = false;
    }
  }

  /// True when the header pickup is still "current location" (follow GPS).
  bool get _isFollowingDeviceGps =>
      c.selectedPickupSavedPlaceId.value == HomeController._currentLocationPlaceId;

  /// Keeps the GPS dot in the center of the map area above the bottom sheet.
  Future<void> _recenterCameraOnDeviceGps({
    bool animated = false,
    double? zoom,
  }) async {
    final controller = c._mapController;
    final location = c.deviceGpsLocation.value;
    if (controller == null || location == null || !_isFollowingDeviceGps) {
      return;
    }
    if (!c.hasLocationPermission.value || c.activeRide.value != null) return;

    try {
      final cameraZoom = zoom ?? c._cachedMapZoom;
      if (zoom != null) {
        c._cachedMapZoom = zoom;
      }
      final update = CameraUpdate.newLatLngZoom(location, cameraZoom);
      if (animated) {
        await controller.animateCamera(update);
      } else {
        await controller.moveCamera(update);
      }
    } catch (_) {
      // Map may be disposed mid-drag.
    }
  }

  /// Smooth incremental pan while the sheet drags (avoids full recenter each frame).
  void _nudgeCameraForSheetDelta(double previousSize, double newSize) {
    final controller = c._mapController;
    if (controller == null || c.deviceGpsLocation.value == null) return;
    if (!_isFollowingDeviceGps) return;
    if (!c.hasLocationPermission.value || c.activeRide.value != null) return;

    final deltaPx =
        (newSize - previousSize) * c.sheetHelper._homeSheetScreenHeight;
    if (deltaPx.abs() < 0.5) return;

    try {
      // Positive scrollY moves the map up as the sheet covers more from the bottom.
      controller.moveCamera(CameraUpdate.scrollBy(0, deltaPx / 2));
    } catch (_) {
      // Map may be disposed mid-drag.
    }

    _scheduleSheetCameraSettle();
  }

  /// Debounces a full GPS recenter after sheet drag settles.
  void _scheduleSheetCameraSettle() {
    c._sheetCameraSettleTimer?.cancel();
    c._sheetCameraSettleTimer = Timer(const Duration(milliseconds: 150), () {
      unawaited(_recenterCameraOnDeviceGps(animated: false));
    });
  }

  /// Clears GPS state and shows the permission-denied address placeholder.
  void _applyLocationPermissionDenied() {
    c.hasLocationPermission.value = false;
    c.deviceGpsLocation.value = null;
    c.currentMapAddress.value = AppStrings.locationPermissionDenied.tr;
  }

  /// Returns true when location permission is granted and services are on.
  ///
  /// GPS button (`showLocationSettingsDialogIfBlocked: true`): check device
  /// Location Services first so we open the correct settings, then app permission.
  /// Startup / silent refresh: keep previous order (app permission first) so we
  /// still grant permission and enable the map blue-dot without blocking on a
  /// transient device-service false while [force] is off.
  Future<bool> _ensureLocationPermission({
    bool requestPermissionIfDenied = false,
    bool showLocationSettingsDialogIfBlocked = false,
  }) async {
    if (showLocationSettingsDialogIfBlocked) {
      final serviceEnabled = await LocationService.instance
          .checkLocationService(force: true);
      if (!serviceEnabled) {
        c.hasLocationPermission.value = false;
        c.deviceGpsLocation.value = null;
        c.currentMapAddress.value = AppStrings.enableLocationService.tr;
        return false;
      }
    }

    final hasPermission = await LocationService.instance.checkPermission(
      force: showLocationSettingsDialogIfBlocked,
      precise: true,
    );

    if (!hasPermission) {
      if (requestPermissionIfDenied) {
        final granted = await LocationService.instance.requestPermission(
          force: showLocationSettingsDialogIfBlocked,
          precise: true,
        );
        if (!granted) {
          _applyLocationPermissionDenied();
          return false;
        }
      } else {
        _applyLocationPermissionDenied();
        return false;
      }
    }

    final serviceEnabled = await LocationService.instance.checkLocationService(
      force: showLocationSettingsDialogIfBlocked,
    );
    if (!serviceEnabled) {
      c.hasLocationPermission.value = false;
      c.deviceGpsLocation.value = null;
      c.currentMapAddress.value = AppStrings.enableLocationService.tr;
      return false;
    }

    c.hasLocationPermission.value = true;
    return true;
  }

  /// 200 m radius around [deviceGpsLocation] (true GPS), not map drag position.
  LatLng? _cachedRadiusCenter;
  Set<Circle> _cachedRadiusCircles = const {};

  Set<Circle> get nearbyPickupRadiusCircles {
    final center = c.deviceGpsLocation.value;
    if (center == null || !c.hasLocationPermission.value) {
      _cachedRadiusCenter = null;
      _cachedRadiusCircles = const {};
      return _cachedRadiusCircles;
    }
    final cached = _cachedRadiusCenter;
    // Ignore sub-~25 m GPS jitter so we do not re-push circles to the platform.
    if (cached != null) {
      final meters = Geolocator.distanceBetween(
        cached.latitude,
        cached.longitude,
        center.latitude,
        center.longitude,
      );
      if (meters < 25) return _cachedRadiusCircles;
    }
    _cachedRadiusCenter = center;
    _cachedRadiusCircles = {
      Circle(
        circleId: const CircleId('pickup_200m_radius'),
        center: center,
        radius: 200,
        fillColor: AppColors.primary.withValues(alpha: 0.08),
        strokeColor: AppColors.primary.withValues(alpha: 0.4),
        strokeWidth: 2,
      ),
    };
    return _cachedRadiusCircles;
  }

  /// Pin for the pickup implied by the header dropdown ([activePickupLatLng]).
  Set<Marker> get selectedPickupMarkers {
    final pos = activePickupLatLng;
    final addr = activePickupAddress.trim();
    final snippet = addr.length > 56 ? '${addr.substring(0, 53)}...' : addr;
    return {
      Marker(
        markerId: const MarkerId('home_selected_pickup'),
        position: pos,
        anchor: const Offset(0.5, 1),
        infoWindow: InfoWindow(
          title: c.savedPlaces.isEmpty
              ? AppStrings.location.tr
              : AppStrings.pickup.tr,
          snippet: snippet.isEmpty ? AppStrings.selectedAddress.tr : snippet,
        ),
        icon:
            c.pickupMarkerIcon.value ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  /// Debounces [getZoomLevel] platform calls (idle fires often during tile load).
  DateTime? _lastZoomReadAt;

  /// Stores the map controller and snaps to the current [mapCenter].
  void onMapCreated(GoogleMapController controller) {
    c._mapController = controller;
    c.isMapReady.value = true;
    c._cachedMapZoom = 16;
    // Keep sheet drag from nudging the camera during the quiet window.
    c._suppressSheetCameraNudgesUntil =
        DateTime.now().add(const Duration(milliseconds: 3000));
    // Instant move on create — animateCamera here often stacks with GPS
    // recenter and sheet padding updates on the same frames.
    unawaited(
      controller.moveCamera(
        CameraUpdate.newLatLngZoom(c.mapCenter.value, c._cachedMapZoom),
      ),
    );
  }

  /// Caches zoom after the home map camera stops moving.
  void onHomeMapCameraIdle() {
    final controller = c._mapController;
    if (controller == null) return;
    // Skip during settle — tile load triggers many idles; each getZoomLevel
    // is a platform round-trip that shows up as raster/SceneDisplayLag.
    final suppressUntil = c._suppressSheetCameraNudgesUntil;
    if (suppressUntil != null && DateTime.now().isBefore(suppressUntil)) {
      return;
    }
    final now = DateTime.now();
    final last = _lastZoomReadAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastZoomReadAt = now;
    unawaited(
      controller.getZoomLevel().then((zoom) {
        if (zoom.isFinite && zoom > 0) {
          c._cachedMapZoom = zoom;
        }
      }),
    );
  }

  /// Updates [mapCenter] while dragging; resets saved pickup to GPS when panned.
  void onCameraMove(CameraPosition position) {
    if (!c._ignoreSelectionReset &&
        c.selectedPickupSavedPlaceId.value !=
            HomeController._currentLocationPlaceId) {
      c.selectedPickupSavedPlaceId.value =
          HomeController._currentLocationPlaceId;
    }
    c.mapCenter.value = position.target;
  }

  /// Reverse-geocodes the map center after the camera settles.
  Future<void> onCameraIdle() async {
    c._ignoreSelectionReset = false;
    await _reverseGeocodeAtCenter();
  }

  /// Fetches last-known then high-accuracy GPS and recenters when following.
  Future<void> _getCurrentLocation({
    bool requestPermissionIfDenied = false,
    bool showLocationSettingsDialogIfBlocked = false,
  }) async {
    try {
      final granted = await _ensureLocationPermission(
        requestPermissionIfDenied: requestPermissionIfDenied,
        showLocationSettingsDialogIfBlocked:
            showLocationSettingsDialogIfBlocked,
      );
      if (!granted) return;

      LatLng? lastKnownTarget;

      // ── Step 1: Try Last Known Position (Quick, no camera animation) ──
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        lastKnownTarget = LatLng(lastPos.latitude, lastPos.longitude);
        c.deviceGpsLocation.value = lastKnownTarget;
        c.mapCenter.value = lastKnownTarget;

        if (c._mapController != null) {
          // Instant move — avoid competing animations with the accurate fix.
          await _recenterCameraOnDeviceGps(animated: false, zoom: 16);
        }
      }

      // ── Step 2: Fetch Fresh High-Accuracy Position with Timeout ──
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 20));

      final target = LatLng(position.latitude, position.longitude);
      final movedMeters = lastKnownTarget == null
          ? double.infinity
          : Geolocator.distanceBetween(
              lastKnownTarget.latitude,
              lastKnownTarget.longitude,
              target.latitude,
              target.longitude,
            );

      // Skip a second camera storm when the accurate fix is essentially
      // the same spot (common on warm GPS). Still refresh coords for distance.
      const significantMoveMeters = 40.0;
      if (movedMeters < significantMoveMeters) {
        c.deviceGpsLocation.value = target;
        c.mapCenter.value = target;
        await _reverseGeocodeAtCenter();
        return;
      }

      c.deviceGpsLocation.value = target;
      c.mapCenter.value = target;

      if (c._mapController != null) {
        // Prefer instant move during bootstrap settle; animate only on GPS tap.
        await _recenterCameraOnDeviceGps(
          animated: showLocationSettingsDialogIfBlocked,
          zoom: 16,
        );
      }

      // Final attempt to geocode the fresh position.
      await _reverseGeocodeAtCenter();
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d("📍 Location Fetch Error: $e", tag: 'HomeController');
      // Even if GPS fails, try geocoding the current map center (which might be the default Dar Lat/Lng)
      await _reverseGeocodeAtCenter();
    }
  }

  /// Resolves [mapCenter] to a human-readable [currentMapAddress].
  Future<void> _reverseGeocodeAtCenter() async {
    if (c.isResolvingAddress.value) return;

    try {
      c.isResolvingAddress.value = true;
      final target = c.mapCenter.value;

      final result = await c.homeRepository
          .reverseGeocode(lat: target.latitude, lng: target.longitude)
          .timeout(const Duration(seconds: 10));

      result.fold(
        (failure) {
          AppLogger.d(
            "📍 Reverse Geocode Failure: ${failure.message}",
            tag: 'HomeController',
          );
          if (c.currentMapAddress.value == AppStrings.locating.tr) {
            c.currentMapAddress.value = AppStrings.currentLocation.tr;
          }
        },
        (data) {
          if (data == null) {
            if (c.currentMapAddress.value == AppStrings.locating.tr) {
              c.currentMapAddress.value = AppStrings.currentLocation.tr;
            }
            return;
          }
          AppLogger.d(
            "📍 Reverse Geocode Success. Status: ${data.data?.status}, Results: ${data.data?.results?.length}",
            tag: 'HomeController',
          );
          final firstResult = data.data?.results?.firstOrNull;
          final formatted = (firstResult?.formattedAddress ?? "").trim();
          if (formatted.isNotEmpty) {
            AppLogger.d(
              "📍 Resolved Address: $formatted",
              tag: 'HomeController',
            );
            c.currentMapAddress.value = formatted;
          } else {
            AppLogger.d("📍 Resolved Address is EMPTY", tag: 'HomeController');
            if (c.currentMapAddress.value == AppStrings.locating.tr) {
              c.currentMapAddress.value = AppStrings.currentLocation.tr;
            }
          }
        },
      );
    } catch (e) {
      AppLogger.d("📍 Reverse Geocode Exception: $e", tag: 'HomeController');
    } finally {
      c.isResolvingAddress.value = false;
    }
  }

  /// Synthetic saved-place row for "Current location" in the address header.
  SavedPlace get currentLocationHeaderPlace => SavedPlace(
    id: HomeController._currentLocationPlaceId,
    label: AppStrings.currentLocation.tr,
    name: AppStrings.currentLocation.tr,
    address: c.currentMapAddress.value,
    lat: c.mapCenter.value.latitude,
    lng: c.mapCenter.value.longitude,
  );

  /// Lat/lng from a [SavedPlace] (flat fields or GeoJSON coordinates).
  LatLng? _latLngFromSavedPlace(SavedPlace p) {
    if (p.lat != null && p.lng != null) return LatLng(p.lat!, p.lng!);
    final coords = p.location?.coordinates;
    if (coords != null && coords.length >= 2) return LatLng(coords[1], coords[0]);
    return null;
  }

  /// Saved place currently selected as pickup, or null when using GPS.
  SavedPlace? get activePickupSavedPlace {
    final id = c.selectedPickupSavedPlaceId.value;
    if (id == null || id == HomeController._currentLocationPlaceId) return null;
    if (c.savedPlaces.isEmpty) return null;
    for (final p in c.savedPlaces) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Coordinates for booking / chips: saved pickup or live [mapCenter].
  LatLng get activePickupLatLng {
    final p = activePickupSavedPlace;
    if (p != null) {
      final ll = _latLngFromSavedPlace(p);
      if (ll != null) return ll;
    }
    return c.mapCenter.value;
  }

  /// GPS / permission / geocode placeholders — not real addresses for text fields.
  bool isNonSelectableMapAddress(String address) {
    final t = address.trim();
    if (t.isEmpty) return true;
    return t == AppStrings.locating.tr ||
        t == AppStrings.enableLocationService.tr ||
        t == AppStrings.locationPermissionDenied.tr ||
        t == AppStrings.currentLocation.tr;
  }

  /// Short hint for location selection when GPS is off or denied (not shown in pickup field).
  String? get mapAddressSetupHint {
    final t = c.currentMapAddress.value.trim();
    if (t == AppStrings.enableLocationService.tr ||
        t == AppStrings.locationPermissionDenied.tr) {
      return t;
    }
    return null;
  }

  /// Human-readable pickup address for booking (empty while still resolving GPS).
  String get activePickupAddress {
    final p = activePickupSavedPlace;
    if (p != null) {
      final a = (p.address ?? p.name ?? '').trim();
      if (a.isNotEmpty) return a;
    }
    final live = c.currentMapAddress.value;
    if (isNonSelectableMapAddress(live)) return '';
    return live;
  }

  /// Distance from device GPS to [lat]/[lng], formatted for list rows.
  String calculateDistanceKm(double? lat, double? lng) {
    // If coordinates are likely placeholders (0,0) or missing, don't show distance
    if ((lat == 0.0 && lng == 0.0) || lat == null || lng == null) return '';

    final current = c.deviceGpsLocation.value;
    if (current == null) return '';

    final distanceMeters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      lat,
      lng,
    );

    final km = distanceMeters / 1000;
    return DistanceDisplay.formatKm(km);
  }

  /// Geocodes [address]; failures resolve to `null` (legacy booking helper).
  Future<LatLng?> getLatLngFromAddress(String address) {
    return resolveAddressCoordinates(address);
  }

  /// Geocodes [address] for booking / stop flows.
  ///
  /// When [onFailure] is provided, surfaces API / empty-result errors there.
  /// Without it, failures resolve to `null` (same as legacy [getLatLngFromAddress]).
  Future<LatLng?> resolveAddressCoordinates(
    String address, {
    void Function(String message)? onFailure,
  }) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      onFailure?.call(AppStrings.unableToGetLocationCoordinates.tr);
      return null;
    }

    final result = await c.homeRepository.getGeocode(address: trimmed);
    return result.fold(
      (failure) {
        onFailure?.call(failure.message);
        return null;
      },
      (response) {
        final results = response.results;
        if (results == null || results.isEmpty) {
          onFailure?.call(AppStrings.unableToGetLocationCoordinates.tr);
          return null;
        }
        final loc = results.first.geometry?.location;
        if (loc?.lat == null || loc?.lng == null) {
          onFailure?.call(AppStrings.unableToGetLocationCoordinates.tr);
          return null;
        }
        return LatLng(loc!.lat!, loc.lng!);
      },
    );
  }
}
