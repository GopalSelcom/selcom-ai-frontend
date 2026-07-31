part of '../home_controller.dart';

/// Home map: GPS permission, camera, reverse geocode, pickup pin / radius.
///
/// Edit here for map/location behavior without touching booking or places lists.
extension HomeMapMethods on HomeController {
  Future<void> _loadMapIcons() async {
    pickupMarkerIcon.value = await MapMarkerUtils.createCustomCircleMarker(
      color: AppColors.mapPickupMarkerBlue,
      // Match the blue used in vehicle selection
      size: 60,
    );
  }

  Future<void> recenterMap() async {
    if (_isResolvingLocationPermission) return;
    _isResolvingLocationPermission = true;
    try {
      // GPS tap: request permission if needed; settings dialog only here.
      selectedPickupSavedPlaceId.value = HomeController._currentLocationPlaceId;
      isSavedPlacesExpanded.value = false;
      await _getCurrentLocation(
        requestPermissionIfDenied: true,
        showLocationSettingsDialogIfBlocked: true,
      );
    } finally {
      _isResolvingLocationPermission = false;
    }
  }

  bool get _isFollowingDeviceGps =>
      selectedPickupSavedPlaceId.value == HomeController._currentLocationPlaceId;

  /// Keeps the GPS dot in the center of the map area above the bottom sheet.
  Future<void> _recenterCameraOnDeviceGps({
    bool animated = false,
    double? zoom,
  }) async {
    final controller = _mapController;
    final location = deviceGpsLocation.value;
    if (controller == null || location == null || !_isFollowingDeviceGps) {
      return;
    }
    if (!hasLocationPermission.value || activeRide.value != null) return;

    try {
      final cameraZoom = zoom ?? _cachedMapZoom;
      if (zoom != null) {
        _cachedMapZoom = zoom;
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
    final controller = _mapController;
    if (controller == null || deviceGpsLocation.value == null) return;
    if (!_isFollowingDeviceGps) return;
    if (!hasLocationPermission.value || activeRide.value != null) return;

    final deltaPx = (newSize - previousSize) * _homeSheetScreenHeight;
    if (deltaPx.abs() < 0.5) return;

    try {
      // Positive scrollY moves the map up as the sheet covers more from the bottom.
      controller.moveCamera(CameraUpdate.scrollBy(0, deltaPx / 2));
    } catch (_) {
      // Map may be disposed mid-drag.
    }

    _scheduleSheetCameraSettle();
  }

  void _scheduleSheetCameraSettle() {
    _sheetCameraSettleTimer?.cancel();
    _sheetCameraSettleTimer = Timer(const Duration(milliseconds: 150), () {
      unawaited(_recenterCameraOnDeviceGps(animated: false));
    });
  }

  void _applyLocationPermissionDenied() {
    hasLocationPermission.value = false;
    deviceGpsLocation.value = null;
    currentMapAddress.value = AppStrings.locationPermissionDenied.tr;
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
        hasLocationPermission.value = false;
        deviceGpsLocation.value = null;
        currentMapAddress.value = AppStrings.enableLocationService.tr;
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
      hasLocationPermission.value = false;
      deviceGpsLocation.value = null;
      currentMapAddress.value = AppStrings.enableLocationService.tr;
      return false;
    }

    hasLocationPermission.value = true;
    return true;
  }

  /// 200 m radius around [deviceGpsLocation] (true GPS), not map drag position.
  Set<Circle> get nearbyPickupRadiusCircles {
    final center = deviceGpsLocation.value;
    if (center == null || !hasLocationPermission.value) return {};
    return {
      Circle(
        circleId: const CircleId('pickup_200m_radius'),
        center: center,
        radius: 200,
        fillColor: AppColors.primary.withValues(alpha: 0.08),
        strokeColor: AppColors.primary.withValues(alpha: 0.4),
        strokeWidth: 2,
      ),
    };
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
          title: savedPlaces.isEmpty
              ? AppStrings.location.tr
              : AppStrings.pickup.tr,
          snippet: snippet.isEmpty ? AppStrings.selectedAddress.tr : snippet,
        ),
        icon:
            pickupMarkerIcon.value ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    isMapReady.value = true;
    _cachedMapZoom = 16;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(mapCenter.value, _cachedMapZoom),
    );
  }

  void onHomeMapCameraIdle() {
    final controller = _mapController;
    if (controller == null) return;
    unawaited(
      controller.getZoomLevel().then((zoom) {
        if (zoom.isFinite && zoom > 0) {
          _cachedMapZoom = zoom;
        }
      }),
    );
  }

  void onCameraMove(CameraPosition position) {
    if (!_ignoreSelectionReset &&
        selectedPickupSavedPlaceId.value != HomeController._currentLocationPlaceId) {
      selectedPickupSavedPlaceId.value = HomeController._currentLocationPlaceId;
    }
    mapCenter.value = position.target;
  }

  Future<void> onCameraIdle() async {
    _ignoreSelectionReset = false;
    await _reverseGeocodeAtCenter();
  }

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

      // ── Step 1: Try Last Known Position (Quick) ──
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        final target = LatLng(lastPos.latitude, lastPos.longitude);
        deviceGpsLocation.value = target;
        mapCenter.value = target;

        if (_mapController != null) {
          await _recenterCameraOnDeviceGps(animated: true, zoom: 16);
        }
      }

      // ── Step 2: Fetch Fresh High-Accuracy Position with Timeout ──
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 20));

      final target = LatLng(position.latitude, position.longitude);
      deviceGpsLocation.value = target;
      mapCenter.value = target;

      if (_mapController != null) {
        await _recenterCameraOnDeviceGps(animated: true, zoom: 16);
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

  Future<void> _reverseGeocodeAtCenter() async {
    if (isResolvingAddress.value) return;

    try {
      isResolvingAddress.value = true;
      final target = mapCenter.value;

      final result = await homeRepository
          .reverseGeocode(lat: target.latitude, lng: target.longitude)
          .timeout(const Duration(seconds: 10));

      result.fold(
        (failure) {
          AppLogger.d(
            "📍 Reverse Geocode Failure: ${failure.message}",
            tag: 'HomeController',
          );
          if (currentMapAddress.value == AppStrings.locating.tr) {
            currentMapAddress.value = AppStrings.currentLocation.tr;
          }
        },
        (data) {
          if (data == null) {
            if (currentMapAddress.value == AppStrings.locating.tr) {
              currentMapAddress.value = AppStrings.currentLocation.tr;
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
            currentMapAddress.value = formatted;
          } else {
            AppLogger.d("📍 Resolved Address is EMPTY", tag: 'HomeController');
            if (currentMapAddress.value == AppStrings.locating.tr) {
              currentMapAddress.value = AppStrings.currentLocation.tr;
            }
          }
        },
      );
    } catch (e) {
      AppLogger.d("📍 Reverse Geocode Exception: $e", tag: 'HomeController');
    } finally {
      isResolvingAddress.value = false;
    }
  }

  SavedPlace get currentLocationHeaderPlace => SavedPlace(
    id: HomeController._currentLocationPlaceId,
    label: AppStrings.currentLocation.tr,
    name: AppStrings.currentLocation.tr,
    address: currentMapAddress.value,
    lat: mapCenter.value.latitude,
    lng: mapCenter.value.longitude,
  );

  LatLng? _latLngFromSavedPlace(SavedPlace p) {
    if (p.lat != null && p.lng != null) return LatLng(p.lat!, p.lng!);
    final c = p.location?.coordinates;
    if (c != null && c.length >= 2) return LatLng(c[1], c[0]);
    return null;
  }

  SavedPlace? get activePickupSavedPlace {
    final id = selectedPickupSavedPlaceId.value;
    if (id == null || id == HomeController._currentLocationPlaceId) return null;
    if (savedPlaces.isEmpty) return null;
    for (final p in savedPlaces) {
      if (p.id == id) return p;
    }
    return null;
  }

  LatLng get activePickupLatLng {
    final p = activePickupSavedPlace;
    if (p != null) {
      final ll = _latLngFromSavedPlace(p);
      if (ll != null) return ll;
    }
    return mapCenter.value;
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
    final t = currentMapAddress.value.trim();
    if (t == AppStrings.enableLocationService.tr ||
        t == AppStrings.locationPermissionDenied.tr) {
      return t;
    }
    return null;
  }

  String get activePickupAddress {
    final p = activePickupSavedPlace;
    if (p != null) {
      final a = (p.address ?? p.name ?? '').trim();
      if (a.isNotEmpty) return a;
    }
    final live = currentMapAddress.value;
    if (isNonSelectableMapAddress(live)) return '';
    return live;
  }

  String calculateDistanceKm(double? lat, double? lng) {
    // If coordinates are likely placeholders (0,0) or missing, don't show distance
    if ((lat == 0.0 && lng == 0.0) || lat == null || lng == null) return '';

    final current = deviceGpsLocation.value;
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

  Future<LatLng?> getLatLngFromAddress(String address) async {
    final result = await homeRepository.getGeocode(address: address);
    return result.fold((failure) => null, (response) {
      if (response.results != null && response.results!.isNotEmpty) {
        final loc = response.results!.first.geometry?.location;
        if (loc != null && loc.lat != null && loc.lng != null) {
          return LatLng(loc.lat!, loc.lng!);
        }
      }
      return null;
    });
  }
}
