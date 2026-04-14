import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:selcom_rides_frontend/features/home/data/models/places_models.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/data/models/requests/create_saved_place_request.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../domain/repositories/home_repository.dart';
import '../../data/models/home_models.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeController extends GetxController {
  final HomeRepository homeRepository;
  final RideRepository rideRepository;
  final ProfileRepository profileRepository;
  final AnalyticsService analyticsService;

  HomeController({
    required this.homeRepository,
    required this.rideRepository,
    required this.profileRepository,
    required this.analyticsService,
  });

  // ── States ──
  final searchQuery = ''.obs;
  final List<Prediction> suggestions = <Prediction>[].obs;
  final recentSearches = <String>[].obs;
  final isSearching = false.obs;
  final isSavingPlace = false.obs;

  // Home Data
  final vehicleTypes = <VehicleTypeModel>[].obs;
  final recentDestinations = <RecentDestinationModel>[].obs;
  final savedPlaces = <SavedPlace>[].obs;

  /// Picked saved address for pickup (header dropdown). Map + chips use this when set.
  final Rxn<String> selectedPickupSavedPlaceId = Rxn<String>();
  final isSavedPlacesExpanded = false.obs;
  final isLoadingHomeData = false.obs;
  final mapCenter = const LatLng(-6.7924, 39.2083).obs;
  final currentMapAddress = 'Locating...'.obs;
  final isMapReady = false.obs;
  final isResolvingAddress = false.obs;
  final hasLocationPermission = false.obs;

  /// Last device GPS fix — used for 1 km radius overlay (does not follow map pan).
  final Rxn<LatLng> deviceGpsLocation = Rxn<LatLng>();

  final selectedVehicle = ''.obs;
  final fareEstimate = Rxn<FareEstimateModel>();
  GoogleMapController? _mapController;

  final pickupMarkerIcon = Rxn<BitmapDescriptor>();

  @override
  void onInit() {
    super.onInit();
    analyticsService.logEvent('home_screen_viewed');
    _loadMapIcons();
    _getCurrentLocation();
    _addMockDrivers();
    _loadHomeData();

    // 300ms debounce with 2-char threshold for location autocomplete.
    debounce(searchQuery, (query) {
      final normalized = query.trim();
      if (normalized.length >= 2) {
        _searchPlaces(normalized);
      } else {
        suggestions.clear();
      }
    }, time: const Duration(milliseconds: 300));
  }

  Future<void> _loadMapIcons() async {
    pickupMarkerIcon.value = await MapMarkerUtils.createCustomCircleMarker(
      color: const Color(0xFF4FA3FF),
      // Match the blue used in vehicle selection
      size: 60,
    );
  }

  void recenterMap() {
    if (_mapController == null) return;
    final target = deviceGpsLocation.value ?? mapCenter.value;
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
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
        fillColor: AppColors.inputBorderActive.withOpacity(0.08),
        strokeColor: AppColors.inputBorderActive.withOpacity(0.4),
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
          title: savedPlaces.isEmpty ? 'Location' : 'Pickup',
          snippet: snippet.isEmpty ? 'Selected address' : snippet,
        ),
        icon:
            pickupMarkerIcon.value ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  Future<void> onSearchTapped() async {
    await analyticsService.logEvent('search_opened');
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    isMapReady.value = true;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(mapCenter.value, 16),
    );
  }

  void onCameraMove(CameraPosition position) {
    mapCenter.value = position.target;
  }

  Future<void> onCameraIdle() async {
    await _reverseGeocodeAtCenter();
  }

  Future<void> _loadHomeData() async {
    isLoadingHomeData.value = true;
    try {
      // Fetch vehicle types, recent destinations, and saved places in parallel.
      final results = await Future.wait([
        homeRepository.getVehicleTypes(),
        rideRepository.getRecentDestinations(),
        profileRepository.getSavedPlaces(),
      ]);

      // Handle Vehicle Types
      results[0].fold(
        (_) => null,
        (types) => vehicleTypes.assignAll(types as List<VehicleTypeModel>),
      );

      // Handle Recent Destinations
      results[1].fold((_) => null, (destinations) {
        if (destinations is List<RecentDestinationModel>) {
          recentDestinations.assignAll(destinations);
        }
      });

      // Handle Saved Places
      results[2].fold((_) => null, (response) {
        final res = response as GetSavedPlacesResponseModel?;
        if (res?.data?.savedPlaces != null) {
          savedPlaces.assignAll(res!.data!.savedPlaces!);
          _syncSelectedPickupAfterSavedPlacesLoad();
        }
      });
    } finally {
      isLoadingHomeData.value = false;
    }
  }

  Future<void> _searchPlaces(String input) async {
    isSearching.value = true;
    final result = await homeRepository.autocomplete(
      input: input,
      sessionToken: 'session_token_123',
    );
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

  Future<void> savePlace({
    required String label,
    required String name,
    required String placeId,
  }) async {
    if (isSavingPlace.value) return;
    isSavingPlace.value = true;
    final request = CreateSavedPlaceRequest(
      label: label,
      name: name,
      placeId: placeId,
      lat: mapCenter.value.latitude,
      lng: mapCenter.value.longitude,
    );

    final result = await profileRepository.addSavedPlace(request);
    result.fold(
      (_) => Get.snackbar(
        'Unable to save',
        'Could not save this location right now.',
        snackPosition: SnackPosition.BOTTOM,
      ),
      (ok) async {
        if (!ok) {
          Get.snackbar(
            'Unable to save',
            'Could not save this location right now.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          await loadSavedPlaces();
          Get.snackbar(
            'Saved',
            '$label location has been saved.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
    isSavingPlace.value = false;
  }

  Future<void> refreshCurrentLocationAddress() async {
    await _getCurrentLocation();
  }

  void _addMockDrivers() {
    // Removed map driver markers
  }

  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      hasLocationPermission.value = false;
      deviceGpsLocation.value = null;
      currentMapAddress.value = 'Enable location service';
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      hasLocationPermission.value = false;
      deviceGpsLocation.value = null;
      currentMapAddress.value = 'Location permission denied';
      return;
    }

    hasLocationPermission.value = true;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final target = LatLng(position.latitude, position.longitude);
    deviceGpsLocation.value = target;
    mapCenter.value = target;

    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(target, 16),
      );
    }

    await _reverseGeocodeAtCenter();
  }

  Future<void> _reverseGeocodeAtCenter() async {
    if (isResolvingAddress.value) return;

    isResolvingAddress.value = true;
    final target = mapCenter.value;
    final result = await homeRepository.reverseGeocode(
      lat: target.latitude,
      lng: target.longitude,
    );

    result.fold((_) => null, (data) {
      if ((data.data?.results ?? []).isNotEmpty &&
          (data.data?.results?.first.formattedAddress ?? "")
              .trim()
              .isNotEmpty) {
        currentMapAddress.value =
            data.data?.results?.first.formattedAddress ?? "";
      }
    });
    isResolvingAddress.value = false;
  }

  SavedPlace? getSavedPlaceByLabel(String label) {
    for (final place in savedPlaces) {
      if ((place.label ?? '').toLowerCase() == label.toLowerCase()) {
        return place;
      }
    }
    return null;
  }

  String? getSavedPlaceSubtitle(String label) {
    final place = getSavedPlaceByLabel(label);
    final value = place?.address?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Pickup = current map center; destination = saved place for [label] (Home / Office / Work / Other).
  Future<void> navigateToVehicleSelectionForSavedLabel(String label) async {
    final place = getSavedPlaceByLabel(label);
    if (place == null) {
      Get.snackbar(
        'Add a saved place',
        'Save this address first, then you can book from here.',
        snackPosition: SnackPosition.BOTTOM,
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
      Get.snackbar(
        'Location unavailable',
        'This saved place is missing coordinates. Try saving it again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final destAddr = (place.address ?? place.name ?? label).trim();
    if (destAddr.isEmpty) {
      Get.snackbar(
        'Address missing',
        'This saved place has no address.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await analyticsService.logEvent(
      'home_saved_chip_vehicle_selection',
      parameters: {'label': label},
    );

    final pickupAddr = activePickupAddress;
    final pickupLL = activePickupLatLng;

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
      Get.snackbar(
        'Location unavailable',
        'This saved place is missing coordinates.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final destAddr = (place.address ?? place.name ?? 'Saved Place').trim();
    if (destAddr.isEmpty) {
      Get.snackbar(
        'Address missing',
        'This saved place has no address.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await analyticsService.logEvent(
      'home_saved_item_vehicle_selection',
      parameters: {'id': place.id},
    );

    final pickupAddr = activePickupAddress;
    final pickupLL = activePickupLatLng;

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
      },
    );
  }

  /// Pickup = current map center; destination = [RecentDestinationModel].
  Future<void> navigateToVehicleSelectionForRecentDestination(
    RecentDestinationModel loc,
  ) async {
    final destAddr = loc.address.trim();
    if (destAddr.isEmpty) return;

    await analyticsService.logEvent(
      'home_recent_item_vehicle_selection',
      parameters: {'address': destAddr},
    );

    final pickupAddr = activePickupAddress;
    final pickupLL = activePickupLatLng;

    Get.toNamed(
      AppRoutes.booking,
      arguments: {
        'pickup': pickupAddr,
        'pickupLat': pickupLL.latitude,
        'pickupLng': pickupLL.longitude,
        'destination': destAddr,
        'destinationLat': loc.lat,
        'destinationLng': loc.lng,
      },
    );
  }

  Future<void> loadSavedPlaces() async {
    final result = await profileRepository.getSavedPlaces();
    result.fold((_) => null, (response) {
      if (response?.data?.savedPlaces != null) {
        savedPlaces.assignAll(response!.data!.savedPlaces!);
        _syncSelectedPickupAfterSavedPlacesLoad();
      }
    });
  }

  void _syncSelectedPickupAfterSavedPlacesLoad() {
    if (savedPlaces.isEmpty) {
      selectedPickupSavedPlaceId.value = null;
      return;
    }
    final current = selectedPickupSavedPlaceId.value;
    final stillValid =
        current != null && savedPlaces.any((p) => p.id == current);
    if (!stillValid) {
      selectedPickupSavedPlaceId.value = savedPlaces.first.id;
    }
  }

  LatLng? _latLngFromSavedPlace(SavedPlace p) {
    if (p.lat != null && p.lng != null) return LatLng(p.lat!, p.lng!);
    final c = p.location?.coordinates;
    if (c != null && c.length >= 2) return LatLng(c[1], c[0]);
    return null;
  }

  SavedPlace? get activePickupSavedPlace {
    if (savedPlaces.isEmpty) return null;
    final id = selectedPickupSavedPlaceId.value;
    if (id != null) {
      for (final p in savedPlaces) {
        if (p.id == id) return p;
      }
    }
    return savedPlaces.first;
  }

  LatLng get activePickupLatLng {
    final p = activePickupSavedPlace;
    if (p != null) {
      final ll = _latLngFromSavedPlace(p);
      if (ll != null) return ll;
    }
    return mapCenter.value;
  }

  String get activePickupAddress {
    final p = activePickupSavedPlace;
    if (p != null) {
      final a = (p.address ?? p.name ?? '').trim();
      if (a.isNotEmpty) return a;
    }
    return currentMapAddress.value;
  }

  Future<void> selectSavedPlaceAsPickup(SavedPlace place) async {
    selectedPickupSavedPlaceId.value = place.id;
    isSavedPlacesExpanded.value = false;

    final latLng = _latLngFromSavedPlace(place);
    final addr = (place.address ?? place.name ?? '').trim();
    if (addr.isNotEmpty) currentMapAddress.value = addr;

    if (latLng != null) {
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
    if (km < 0.1) return '0.1 KM';
    if (km > 999) return '>999 KM';
    return '${km.toStringAsFixed(1)} KM';
  }

  // ── Home screen UI orchestration (keep branching / navigation out of widgets) ──

  /// Collapsed: active pickup only; expanded: all saved places (tap one to set pickup).
  List<SavedPlace> get addressHeaderPlacesToShow {
    if (savedPlaces.isEmpty) return const [];
    final active = activePickupSavedPlace;
    if (active == null) return const [];
    return isSavedPlacesExpanded.value
        ? savedPlaces.toList()
        : <SavedPlace>[active];
  }

  void toggleAddressHeaderExpansion() {
    isSavedPlacesExpanded.toggle();
  }

  double get addressHeaderChevronTurns =>
      isSavedPlacesExpanded.value ? 0.5 : 0.0;

  /// Opens location flow with current [activePickupAddress] / [activePickupLatLng].
  /// Optional [preferredVehicle] is forwarded to booking → vehicle selection.
  Future<void> openLocationSelection({
    VehicleTypeModel? preferredVehicle,
  }) async {
    await onSearchTapped();
    final args = <String, dynamic>{
      'pickup': activePickupAddress,
      'pickupLat': activePickupLatLng.latitude,
      'pickupLng': activePickupLatLng.longitude,
    };
    if (preferredVehicle != null) {
      if (preferredVehicle.id.isNotEmpty) {
        args['preferredVehicleTypeId'] = preferredVehicle.id;
      }
      if (preferredVehicle.name.isNotEmpty) {
        args['preferredVehicleName'] = preferredVehicle.name;
      }
      if (preferredVehicle.key.isNotEmpty) {
        args['preferredVehicleKey'] = preferredVehicle.key;
      }
    }
    Get.toNamed(AppRoutes.locationSelection, arguments: args);
  }

  Future<void> openLocationSelectionWithPreferredVehicle(
    VehicleTypeModel vehicle,
  ) {
    return openLocationSelection(preferredVehicle: vehicle);
  }

  void openProfile() {
    Get.to(() => ProfileScreen());
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
    final pid = destinationPlaceId?.trim();
    if (pid != null && pid.isNotEmpty) {
      await savePlace(
        label: 'Destination',
        name: destinations.first,
        placeId: pid,
      );
    }

    final pLat = routePickupLat ?? mapCenter.value.latitude;
    final pLng = routePickupLng ?? mapCenter.value.longitude;
    final dLat = routeDestinationLat ?? (pLat - 0.018);
    final dLng = routeDestinationLng ?? (pLng + 0.014);

    Get.toNamed(
      AppRoutes.booking,
      arguments: {
        'pickup': pickup,
        'destination': destinations.first,
        'destinations': destinations,
        'pickupLat': pLat,
        'pickupLng': pLng,
        'destinationLat': dLat,
        'destinationLng': dLng,
        if (preferredVehicleTypeId != null && preferredVehicleTypeId.isNotEmpty)
          'preferredVehicleTypeId': preferredVehicleTypeId,
        if (preferredVehicleName != null && preferredVehicleName.isNotEmpty)
          'preferredVehicleName': preferredVehicleName,
      },
    );
  }

  /// Chip subtitle; Home falls back to current map address when saved line is empty.
  String? chipSubtitleFor(String label) {
    final s = getSavedPlaceSubtitle(label);
    if (s != null && s.trim().isNotEmpty) return s;
    if (label.toLowerCase() == 'home') return currentMapAddress.value;
    return null;
  }

  String vehicleExploreImageAsset(String vehicleName) {
    final name = vehicleName.toLowerCase();
    if (name.contains('bike') || name.contains('boda')) {
      return AppAssets.imgBoda;
    }
    if (name.contains('auto') ||
        name.contains('wheeler') ||
        name.contains('bajaj')) {
      return AppAssets.imgBajaji;
    }
    return AppAssets.imgCab;
  }

  String recentDestinationTitleLine(RecentDestinationModel loc) {
    final parts = loc.address.split(',');
    if (parts.isEmpty) return loc.address;
    final first = parts.first.trim();
    return first.isEmpty ? loc.address : first;
  }

  bool get shouldShowRecentSection =>
      isLoadingHomeData.value || recentDestinations.isNotEmpty;

  bool get shouldShowVehicleSection =>
      isLoadingHomeData.value || vehicleTypes.isNotEmpty;

  // Location selection screen orchestration helpers.
  void applyLocationSelectionTextToSegment({
    required int activeSegmentIndex,
    required String text,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    if (activeSegmentIndex == 0) {
      pickupEditedByUser.value = true;
      routePickupLat.value = null;
      routePickupLng.value = null;
      pickupController.text = text;
      return;
    }

    if (activeSegmentIndex == 1) {
      destinationController.text = text;
      routeDestinationLat.value = null;
      routeDestinationLng.value = null;
      destinationPlaceId.value = null;
      return;
    }

    final i = activeSegmentIndex - 2;
    if (i >= 0 && i < extraDestinationControllers.length) {
      extraDestinationControllers[i].text = text;
    }
  }

  void applySuggestionToLocationSelection({
    required Prediction prediction,
    required int activeSegmentIndex,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    final description = prediction.description ?? '';
    if (activeSegmentIndex == 0) {
      pickupEditedByUser.value = true;
      routePickupLat.value = null;
      routePickupLng.value = null;
      pickupController.text = description;
      pickupController.selection = TextSelection.fromPosition(
        TextPosition(offset: pickupController.text.length),
      );
      return;
    }

    if (activeSegmentIndex == 1) {
      destinationController.text = description;
      routeDestinationLat.value = null;
      routeDestinationLng.value = null;
      destinationPlaceId.value = prediction.placeId?.trim();
      destinationController.selection = TextSelection.fromPosition(
        TextPosition(offset: destinationController.text.length),
      );
      return;
    }

    final i = activeSegmentIndex - 2;
    if (i >= 0 && i < extraDestinationControllers.length) {
      final c = extraDestinationControllers[i];
      c.text = description;
      c.selection = TextSelection.fromPosition(
        TextPosition(offset: c.text.length),
      );
    }
  }

  void applySavedLabelToLocationSelection({
    required String label,
    required TextEditingController destinationController,
    required RxInt activeSegmentIndex,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    final savedPlace = getSavedPlaceByLabel(label);
    final saved = savedPlace?.address?.trim();
    if (saved == null || saved.isEmpty) return;
    final coords = savedPlace?.location?.coordinates;
    final lat =
        savedPlace?.lat ??
        ((coords != null && coords.length >= 2) ? coords[1] : null);
    final lng =
        savedPlace?.lng ??
        ((coords != null && coords.length >= 2) ? coords[0] : null);

    destinationController.text = saved;
    routeDestinationLat.value = lat;
    routeDestinationLng.value = lng;
    destinationPlaceId.value = null;
    activeSegmentIndex.value = 1;
    searchQuery.value = '';
  }

  void applyRecentDestinationToLocationSelection({
    required RecentDestinationModel destination,
    required int activeSegmentIndex,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    applyLocationSelectionTextToSegment(
      activeSegmentIndex: activeSegmentIndex,
      text: destination.address,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    if (activeSegmentIndex == 1) {
      routeDestinationLat.value = destination.lat;
      routeDestinationLng.value = destination.lng;
    }
    searchQuery.value = '';
  }

  void applyRecentSearchToLocationSelection({
    required String recentText,
    required int activeSegmentIndex,
    required TextEditingController pickupController,
    required TextEditingController destinationController,
    required List<TextEditingController> extraDestinationControllers,
    required RxBool pickupEditedByUser,
    required RxnDouble routePickupLat,
    required RxnDouble routePickupLng,
    required RxnDouble routeDestinationLat,
    required RxnDouble routeDestinationLng,
    required RxnString destinationPlaceId,
  }) {
    applyLocationSelectionTextToSegment(
      activeSegmentIndex: activeSegmentIndex,
      text: recentText,
      pickupController: pickupController,
      destinationController: destinationController,
      extraDestinationControllers: extraDestinationControllers,
      pickupEditedByUser: pickupEditedByUser,
      routePickupLat: routePickupLat,
      routePickupLng: routePickupLng,
      routeDestinationLat: routeDestinationLat,
      routeDestinationLng: routeDestinationLng,
      destinationPlaceId: destinationPlaceId,
    );
    searchQuery.value = '';
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

  SavedPlace? getSavedPlaceFor(String address, String? placeId) {
    if (savedPlaces.isEmpty) return null;
    return savedPlaces.firstWhereOrNull(
      (s) =>
          (placeId != null && s.id == placeId) ||
          s.address?.trim().toLowerCase() == address.trim().toLowerCase(),
    );
  }

  bool isPlaceFavorite(String address, String? placeId) {
    final saved = getSavedPlaceFor(address, placeId);
    return saved?.isFavourite ?? false;
  }

  Future<void> toggleFavorite(String address, String? placeId) async {
    final saved = getSavedPlaceFor(address, placeId);
    if (saved == null || saved.id == null) {
      Get.snackbar('Note', 'Only saved places can be favourited.');
      return;
    }

    final newStatus = !(saved.isFavourite ?? false);

    // Optimistic UI update
    final index = savedPlaces.indexWhere((p) => p.id == saved.id);
    if (index != -1) {
      savedPlaces[index] = savedPlaces[index].copyWith(isFavourite: newStatus);
      savedPlaces.refresh();
    }

    final result = await profileRepository.toggleFavorite(saved.id!, newStatus);

    result.fold(
      (failure) {
        // Rollback
        if (index != -1) {
          savedPlaces[index] = savedPlaces[index].copyWith(
            isFavourite: !newStatus,
          );
          savedPlaces.refresh();
        }
        Get.snackbar('Error', 'Could not update favorite status');
      },
      (success) {
        if (!success) {
          // Rollback
          if (index != -1) {
            savedPlaces[index] = savedPlaces[index].copyWith(
              isFavourite: !newStatus,
            );
            savedPlaces.refresh();
          }
        }
      },
    );
  }
}
