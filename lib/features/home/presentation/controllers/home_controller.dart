import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/responses/rides/active_ride_response.dart'
    as active_ride_api;
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/domain/entities/location_entity.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/live_activity/live_activity_manager.dart';
import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/map_marker_utils.dart';
import '../../../../shared/utils/active_rides_parser.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/distance_display.dart';
import '../../../../shared/utils/saved_places_ordering.dart';
import '../../../../shared/utils/ride_active_navigation.dart';
import '../../../../shared/utils/active_ride_vehicle_image_resolver.dart';
import '../../../../shared/utils/vehicle_image_utils.dart';
import '../../../../shared/widgets/add_favorite_location_sheet.dart';
import '../../../../shared/widgets/favorite_location_chips_row.dart';
import '../../../profile/data/cache/user_profile_cache.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../../ride_rating/presentation/controllers/ride_rating_controller.dart';
import '../../data/models/home_models.dart';
import '../../data/models/places_models.dart';
import '../../domain/repositories/home_repository.dart';
import '../screens/recent_locations_screen.dart';
import 'location_selection_controller.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  static const String _currentLocationPlaceId = '__current_location__';

  /// Maximum draggable height (fraction of screen).
  static const double homeSheetMaxSize = 0.9;

  /// Default height when recent destinations are available.
  static const double homeSheetWithRecentDefaultSize = 0.7;

  /// Floor for collapsed sheet peek.
  static const double homeSheetCollapsedPeekMin = 0.28;

  static bool _didCheckPendingReviewOnHomeLaunch = false;

  final HomeRepository homeRepository;
  final RideRepository rideRepository;
  final ProfileRepository profileRepository;
  final AnalyticsService analyticsService;
  final NotificationService notificationService;
  final RideRatingController rideRatingController;

  HomeController({
    required this.homeRepository,
    required this.rideRepository,
    required this.profileRepository,
    required this.analyticsService,
    required this.notificationService,
    required this.rideRatingController,
  });

  // ── States ──
  final searchQuery = ''.obs;
  final List<Prediction> suggestions = <Prediction>[].obs;
  final recentSearches = <String>[].obs;
  final isSearching = false.obs;
  final isSavingPlace = false.obs;
  final isProceedingToBooking = false.obs;

  // Home Data
  final vehicleTypes = <VehicleTypeModel>[].obs;
  final recentDestinations = <RecentDestinationModel>[].obs;
  final recentDestinationsScreen = <RecentDestinationModel>[].obs;
  final savedPlaces = <SavedPlace>[].obs;
  final activeRide = Rxn<RideModel>();
  final activeRides = <RideModel>[].obs;
  final isActiveRidesExpanded = false.obs;

  int get additionalActiveRidesCount =>
      activeRides.length > 1 ? activeRides.length - 1 : 0;

  bool get hasMultipleActiveRides => activeRides.length > 1;

  /// Home chips only: last tapped chip before leaving home (highlight on return).
  final RxnString recentHomeChipKey = RxnString();

  /// Picked saved address for pickup (header dropdown). Map + chips use this when set.
  final selectedPickupSavedPlaceId = Rxn<String>(_currentLocationPlaceId);
  final isSavedPlacesExpanded = false.obs;
  final isLoadingHomeData = false.obs;

  /// True after the first [_loadHomeData] attempt finishes (success or partial).
  /// Location selection uses this to reuse in-memory recent/saved places.
  bool hasCompletedInitialHomeLoad = false;

  final isLoadingRecentLocationsScreen = false.obs;
  final profileImageUrl = ''.obs;
  final mapCenter = const LatLng(-6.7924, 39.2083).obs;
  final currentMapAddress = AppStrings.locating.tr.obs;
  final isMapReady = false.obs;
  final isResolvingAddress = false.obs;
  final hasLocationPermission = false.obs;

  /// Draggable home bottom sheet size (fraction of screen height).
  final sheetSize = homeSheetCollapsedPeekMin.obs;
  final DraggableScrollableController homeSheetController =
      DraggableScrollableController();

  /// Measured sheet content height in px (from layout); drives max/initial sizes.
  final measuredSheetContentHeightPx = RxnDouble();

  /// Screen height used with [measuredSheetContentHeightPx] for sheet fractions.
  final measuredSheetLayoutHeightPx = RxnDouble();

  /// Last device GPS fix — used for 1 km radius overlay (does not follow map pan).
  final Rxn<LatLng> deviceGpsLocation = Rxn<LatLng>();

  final selectedVehicle = ''.obs;
  final fareEstimate = Rxn<FareEstimateModel>();
  GoogleMapController? _mapController;
  final AppSocketService _socketService = AppSocketService();
  bool _ignoreSelectionReset = false;
  Timer? _activeRidePollingTimer;
  bool _isRefreshingActiveRide = false;
  bool _activeRideRefreshQueued = false;
  bool _skipNextVisibleRefresh = true;
  DateTime? _lastActiveRideRefreshAt;
  bool _isResolvingLocationPermission = false;
  double _cachedMapZoom = 16;
  Timer? _sheetCameraSettleTimer;
  bool _isClosed = false;

  final pickupMarkerIcon = Rxn<BitmapDescriptor>();

  final RxBool isPickupSelected = false.obs;
  final RxBool isDestinationSelected = false.obs;

  @override
  void onInit() {
    super.onInit();
    homeSheetController.addListener(_onHomeSheetChanged);
    WidgetsBinding.instance.addObserver(this);
    analyticsService.logEvent('home_screen_viewed');
    _loadMapIcons();
    _initSequentialPermissions();
    _addMockDrivers();
    _startActiveRidePolling();
    _loadHomeData().whenComplete(() async {
      // Product rule: call pending-review API only once when app session
      // first opens Home, not on subsequent returns to Home.
      if (_didCheckPendingReviewOnHomeLaunch) {
        return;
      }
      _didCheckPendingReviewOnHomeLaunch = true;
      try {
        await rideRatingController.tryOpenRatingSheetAfterHomeLoad();
      } catch (e, stackTrace) {
        AppLogger.e(
          'Pending review prompt failed: $e',
          tag: 'HomeController',
          stackTrace: stackTrace,
        );
      }
    });

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

  Future<void> _initSequentialPermissions() async {
    // 1. Run notification & call permissions flow (sequential system dialogs)
    await notificationService.runHomePermissionFlow();
    // 2. Request location permission immediately after notification flow completes
    await _getCurrentLocation(requestPermissionIfDenied: true);
  }

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
      selectedPickupSavedPlaceId.value = _currentLocationPlaceId;
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
      selectedPickupSavedPlaceId.value == _currentLocationPlaceId;

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
        selectedPickupSavedPlaceId.value != _currentLocationPlaceId) {
      selectedPickupSavedPlaceId.value = _currentLocationPlaceId;
    }
    mapCenter.value = position.target;
  }

  Future<void> onCameraIdle() async {
    _ignoreSelectionReset = false;
    await _reverseGeocodeAtCenter();
  }

  Future<void> _loadHomeData() async {
    if (SessionExpiryService.isHandling) return;
    isLoadingHomeData.value = true;
    try {
      // Fetch vehicle types, recent destinations, saved places, and profile in parallel.
      final results = await Future.wait([
        homeRepository.getVehicleTypes(),
        rideRepository.getRecentDestinations(),
        profileRepository.getSavedPlaces(),
        rideRepository.getActiveRide(),
        profileRepository.getProfile(),
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
        savedPlaces.assignAll(
          SavedPlacesOrdering.sortForDisplay(
            res?.data?.savedPlaces ?? const [],
          ),
        );
        _syncSelectedPickupAfterSavedPlacesLoad();
      });

      // Handle Active Ride
      results[3].fold((_) => null, (response) {
        final activeRideResponse =
            response as active_ride_api.ActiveRideResponseModel?;
        _applyActiveRideResponse(activeRideResponse);
      });

      // Handle Profile (header avatar)
      if (!SessionExpiryService.isHandling) {
        results[4].fold((_) => null, (user) {
          _applyProfileImage(user as UserModel);
        });
      }
    } finally {
      hasCompletedInitialHomeLoad = true;
      if (!SessionExpiryService.isHandling) {
        isLoadingHomeData.value = false;
        invalidateHomeSheetMeasurement();
      }
    }
  }

  /// Reloads recent destinations into the Home list (not the dedicated screen list).
  Future<void> reloadRecentDestinations() async {
    final result = await rideRepository.getRecentDestinations();
    result.fold((_) => null, (destinations) {
      recentDestinations.assignAll(destinations);
      invalidateHomeSheetMeasurement();
    });
  }

  List<RecentDestinationModel> get recentDestinationsPreview {
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
      final result = await rideRepository.getRecentDestinations();
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

  void invalidateHomeSheetMeasurement() {
    measuredSheetContentHeightPx.value = null;
    measuredSheetLayoutHeightPx.value = null;
  }

  void reportHomeSheetContentHeight({
    required double contentHeightPx,
    required double layoutHeightPx,
  }) {
    // Shimmer layout must not drive sheet size; real content measures after load.
    if (isLoadingHomeData.value) return;
    if (contentHeightPx <= 0 || layoutHeightPx <= 0) return;
    final previous = measuredSheetContentHeightPx.value;
    if (previous != null && (previous - contentHeightPx).abs() < 1) return;

    final isFirstMeasure = previous == null;
    measuredSheetContentHeightPx.value = contentHeightPx;
    measuredSheetLayoutHeightPx.value = layoutHeightPx;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncHomeSheetToDefault(animated: !isFirstMeasure);
    });
  }

  void onHomeVisible() {
    if (SessionExpiryService.isHandling) return;
    // HomeScreen can stay mounted under ongoing-ride routes; only release the
    // ride room when Home is actually the active route.
    if (Get.currentRoute != AppRoutes.home) return;
    // Release ride socket room when user is on Home (one room at a time).
    _socketService.leaveJoinedRideRoom();
    if (_skipNextVisibleRefresh) {
      _skipNextVisibleRefresh = false;
      return;
    }
    if (_activeRideRefreshQueued) return;
    _activeRideRefreshQueued = true;
    Future.microtask(() async {
      _activeRideRefreshQueued = false;
      await refreshActiveRide();
    });
  }

  /// Stops periodic active-ride polling (e.g. after session revoked on another device).
  void stopActiveRidePolling() {
    _activeRidePollingTimer?.cancel();
    _activeRidePollingTimer = null;
  }

  /// Clears active-ride UI/state when the session is no longer valid.
  void onSessionExpired() {
    stopActiveRidePolling();
    activeRide.value = null;
    activeRides.clear();
    isActiveRidesExpanded.value = false;
    _socketService.leaveJoinedRideRoom();
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
    final result = await rideRepository.getActiveRide();
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

    final detailsResult = await rideRepository.getRideDetails(rideId);
    detailsResult.fold(
      (failure) => AppDialogs.showErrorDialog(message: failure.message),
      (freshRide) async {
        final freshId = freshRide.id.trim();
        if (freshId.isEmpty || freshId != rideId) {
          AppDialogs.showErrorDialog(
            message: AppStrings.failedToLoadRideDetails.tr,
          );
          return;
        }
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
        navigateToOngoingRide(freshRide);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (SessionExpiryService.isHandling) return;
    Future.microtask(() async {
      if (!hasLocationPermission.value) {
        await _getCurrentLocation();
      }
      await refreshActiveRide(force: true);
    });
  }

  void updateHomeSheetSize(double size) {
    final previousSize = sheetSize.value;
    if ((size - previousSize).abs() < 0.0001) return;
    sheetSize.value = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nudgeCameraForSheetDelta(previousSize, size);
    });
  }

  void _onHomeSheetChanged() {
    if (_isClosed) return;
    if (!homeSheetController.isAttached) return;
    final size = homeSheetController.size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isClosed) return;
      if (!homeSheetController.isAttached) return;
      // Avoid map/sheet relayout fighting with modal sheets (e.g. add favourite).
      if (Get.isDialogOpen ?? false) return;
      updateHomeSheetSize(size);
    });
  }

  bool get hasRecentLocationsForSheet =>
      !isLoadingHomeData.value && recentDestinations.isNotEmpty;

  /// Smallest drag height: handle + search + chips only (recents/vehicles collapse).
  double get homeSheetMinSize {
    final fraction = _homeSheetCollapsedPeekHeight() / _homeSheetScreenHeight;
    final max = homeSheetMaxChildSize;
    if (max <= homeSheetCollapsedPeekMin + 0.02) {
      return (max - 0.02).clamp(0.15, max);
    }
    return fraction.clamp(homeSheetCollapsedPeekMin, max - 0.02);
  }

  double get _sheetLayoutScreenHeight =>
      measuredSheetLayoutHeightPx.value ?? _homeSheetScreenHeight;

  /// Uncapped content height as a fraction of the screen (measured when available).
  double get homeSheetRawContentFraction {
    final measured = measuredSheetContentHeightPx.value;
    if (measured != null) {
      return measured / _sheetLayoutScreenHeight;
    }
    return _homeSheetContentHeight(
          includeRecent: isLoadingHomeData.value
              ? shouldShowRecentSection
              : hasRecentLocationsForSheet,
        ) /
        _homeSheetScreenHeight;
  }

  bool get homeSheetHasMeasuredContent =>
      measuredSheetContentHeightPx.value != null;

  /// True when content exceeds 90% — inner list scrolls; sheet max stays at 90%.
  bool get homeSheetNeedsInnerScroll =>
      homeSheetRawContentFraction > homeSheetMaxSize + 0.01;

  /// Natural content height including optional recent block (capped at 90%).
  double get homeSheetContentSizeFraction {
    return homeSheetRawContentFraction.clamp(
      homeSheetCollapsedPeekMin,
      homeSheetMaxSize,
    );
  }

  /// Max drag: content height when it fits; otherwise 90% with inner scroll.
  double get homeSheetMaxChildSize {
    if (homeSheetNeedsInnerScroll) return homeSheetMaxSize;
    return homeSheetContentSizeFraction;
  }

  /// Keeps sheet draggable up/down; inner list scrolls only when content overflows.
  ScrollPhysics get homeSheetScrollPhysics =>
      const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());

  /// True when recents need at least the 70% default (enough measured content).
  bool get homeSheetShouldUseExpandedDefault =>
      hasRecentLocationsForSheet &&
      homeSheetHasMeasuredContent &&
      homeSheetContentSizeFraction >= homeSheetWithRecentDefaultSize - 0.02;

  /// Resting height: content-sized when small; 70% only after measure proves it fits.
  double get homeSheetInitialSize {
    final content = homeSheetContentSizeFraction;
    final clamped = content.clamp(homeSheetMinSize, homeSheetMaxChildSize);

    if (!hasRecentLocationsForSheet) return clamped;

    if (!homeSheetHasMeasuredContent) return clamped;

    if (!homeSheetShouldUseExpandedDefault) return clamped;

    return homeSheetWithRecentDefaultSize.clamp(
      homeSheetMinSize,
      homeSheetMaxChildSize,
    );
  }

  List<double> get homeSheetSnapSizes {
    final max = homeSheetMaxChildSize;
    final snaps = <double>[homeSheetMinSize];
    if (homeSheetShouldUseExpandedDefault) {
      final expandedSnap = homeSheetWithRecentDefaultSize.clamp(
        homeSheetMinSize,
        max,
      );
      if (expandedSnap > snaps.last + 0.05) {
        snaps.add(expandedSnap);
      }
    }
    if (max > snaps.last + 0.05) {
      snaps.add(max);
    }
    return _dedupeAscendingSnapSizes(snaps);
  }

  bool get homeSheetShouldSnap => homeSheetSnapSizes.length > 1;

  void syncHomeSheetToDefault({bool animated = false}) {
    if (_isClosed) return;
    final max = homeSheetMaxChildSize;
    var target = homeSheetInitialSize;
    if (homeSheetController.isAttached) {
      final current = homeSheetController.size;
      if (current > max) {
        target = max;
      }
    }
    sheetSize.value = target;
    if (!homeSheetController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isClosed) return;
        syncHomeSheetToDefault(animated: animated);
      });
      return;
    }
    if (animated) {
      homeSheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      homeSheetController.jumpTo(target);
    }
  }

  double get _homeSheetScreenHeight => 1.sh > 0 ? 1.sh : 812;

  double _homeSheetCollapsedPeekHeight() {
    return 80.h + 68.h + 12.h + 16.h;
  }

  double get _estimatedBottomPadding {
    final context = Get.context;
    if (context == null) return 16.h;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return bottomPadding > 0
        ? (GetPlatform.isIOS ? 0.0 : 8.h) + bottomPadding
        : 16.h;
  }

  double _homeSheetContentHeight({required bool includeRecent}) {
    double contentHeight = 78.h;
    contentHeight += 64.h;

    if (includeRecent && shouldShowRecentSection) {
      contentHeight += 28.h;
      final count = isLoadingHomeData.value
          ? 3
          : recentDestinationsPreview.length;
      contentHeight += count * 64.h;
      if (count > 1) {
        contentHeight += (count - 1) * 25.h;
      }
    }

    if (shouldShowVehicleSection) {
      contentHeight += 12.h;
      contentHeight += 28.h;
      contentHeight += 72.h;
    }

    contentHeight += _estimatedBottomPadding;
    return contentHeight;
  }

  List<double> _dedupeAscendingSnapSizes(List<double> sizes) {
    final sorted = sizes.toList()..sort();
    final out = <double>[];
    for (final size in sorted) {
      final clamped = size.clamp(homeSheetMinSize, homeSheetMaxChildSize);
      if (out.isEmpty || clamped > out.last + 0.05) {
        out.add(clamped);
      }
    }
    return out;
  }

  @override
  void onClose() {
    _isClosed = true;
    _sheetCameraSettleTimer?.cancel();
    homeSheetController.removeListener(_onHomeSheetChanged);
    // Don't call homeSheetController.dispose() here because the old HomeScreen widget
    // might still be in the widget tree (e.g. animating out) during a route transition,
    // and disposing it now would crash the animating-out sheet.
    // Instead, removing the listener above is sufficient, and the controller will be
    // garbage-collected when the view is unmounted.
    WidgetsBinding.instance.removeObserver(this);
    stopActiveRidePolling();
    _socketService.dispose();
    super.onClose();
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
    required RecentDestinationModel loc,
    required String label,
  }) async {
    if (isSavingPlace.value) return;
    isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final request = SaveRecentAsFavoriteRequest(
          label: label.toLowerCase(),
          name: loc.address.split(',').first,
          address: loc.address,
          lat: loc.lat,
          lng: loc.lng,
        );

        final result = await profileRepository.saveRecentAsFavorite(request);
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

  Future<void> toggleFavoriteForRecent(RecentDestinationModel loc) async {
    final saved = getSavedPlaceFor(loc.address, null);
    if (saved?.id != null) {
      await _confirmAndDeleteSavedPlace(saved!);
      return;
    }
    await toggleAddAddressBottomSheetForRecent(loc);
  }

  void _addMockDrivers() {
    // Removed map driver markers
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
    RecentDestinationModel loc,
  ) async {
    await _openLocationSelectionWithDestination(
      destAddr: loc.address,
      destLat: loc.lat,
      destLng: loc.lng,
      analyticsEvent: 'home_recent_item_location_selection',
      analyticsParams: {'address': loc.address.trim()},
    );
  }

  /// Pickup = current map center; destination = [RecentDestinationModel].
  ///
  /// When GPS/location is unavailable, opens location selection so the user can
  /// pick pickup; [loc] is pre-filled as destination.
  ///
  /// Set [showHomeFareEstimateLoader] when the tap originates from the home
  /// sheet so the home overlay can run during fare estimate.
  Future<void> navigateToVehicleSelectionForRecentDestination(
    RecentDestinationModel loc, {
    bool showHomeFareEstimateLoader = false,
  }) async {
    final destAddr = loc.address.trim();
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
        lat: loc.lat,
        lng: loc.lng,
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

  /// Reload from `GET go/user/saved-places`; always applies API list including `[]`.
  Future<void> loadSavedPlaces() async {
    final result = await profileRepository.getSavedPlaces();
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
    await loadSavedPlaces();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await loadSavedPlaces();
  }

  void _syncSelectedPickupAfterSavedPlacesLoad() {
    if (savedPlaces.isEmpty &&
        selectedPickupSavedPlaceId.value != _currentLocationPlaceId) {
      selectedPickupSavedPlaceId.value = null;
      return;
    }
    final current = selectedPickupSavedPlaceId.value;
    if (current == _currentLocationPlaceId) return;
    final stillValid =
        current != null && savedPlaces.any((p) => p.id == current);
    if (!stillValid) {
      selectedPickupSavedPlaceId.value = savedPlaces.isNotEmpty
          ? savedPlaces.first.id
          : _currentLocationPlaceId;
    }
  }

  SavedPlace get currentLocationHeaderPlace => SavedPlace(
    id: _currentLocationPlaceId,
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
    if (id == null || id == _currentLocationPlaceId) return null;
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

  Future<void> selectSavedPlaceAsPickup(SavedPlace place) async {
    if (place.id == _currentLocationPlaceId) {
      selectedPickupSavedPlaceId.value = _currentLocationPlaceId;
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

  // ── Home screen UI orchestration (keep branching / navigation out of widgets) ──

  /// Collapsed: active pickup only; expanded: all saved places (tap one to set pickup).
  List<SavedPlace> get addressHeaderPlacesToShow {
    final current = currentLocationHeaderPlace;
    final active = activePickupSavedPlace;
    if (isSavedPlacesExpanded.value) {
      return <SavedPlace>[current, ...savedPlaces];
    }
    if (selectedPickupSavedPlaceId.value == _currentLocationPlaceId) {
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

  /// Opens location flow with current [activePickupAddress] / [activePickupLatLng].
  /// Optional [preferredVehicle] is forwarded to booking → vehicle selection.
  Future<void> openLocationSelection({
    VehicleTypeModel? preferredVehicle,
  }) async {
    await analyticsService.logEvent('search_opened');
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
    if (Get.isRegistered<LocationSelectionController>()) {
      Get.delete<LocationSelectionController>();
    }
    Get.toNamed(AppRoutes.locationSelection, arguments: args);
  }

  Future<void> openLocationSelectionWithPreferredVehicle(
    VehicleTypeModel vehicle,
  ) {
    return openLocationSelection(preferredVehicle: vehicle);
  }

  Future<void> openProfile() async {
    await Get.toNamed(AppRoutes.profile);
    if (SessionExpiryService.isHandling) return;
    // No GET on return — avatar syncs from cache only after profile edit.
    _syncProfileImageFromCacheIfChanged();
  }

  /// Updates the home header avatar from session cache after profile edit only.
  void _syncProfileImageFromCacheIfChanged() {
    if (!UserProfileCache.consumeChanged()) return;
    final user = UserProfileCache.user;
    if (user != null) _applyProfileImage(user);
  }

  void _applyProfileImage(UserModel user) {
    profileImageUrl.value = user.image?.trim() ?? '';
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

  /// Chip subtitle; Home falls back to current map address when saved line is empty.
  String? chipSubtitleFor(String label) {
    final s = getSavedPlaceSubtitle(label);
    if (s != null && s.trim().isNotEmpty) return s;
    if (label.toLowerCase() == 'home') return currentMapAddress.value;
    return null;
  }

  String vehicleExploreImageAsset(String vehicleName) {
    return VehicleImageUtils.imageAssetForVehicleType(vehicleName);
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
      getLatLngFromAddress(description).then((latLng) {
        if (latLng != null) {
          routePickupLat.value = latLng.latitude;
          routePickupLng.value = latLng.longitude;
        }
      });
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

      // Async resolve coordinates to avoid faulty fallbacks later
      getLatLngFromAddress(description).then((latLng) {
        if (latLng != null) {
          routeDestinationLat.value = latLng.latitude;
          routeDestinationLng.value = latLng.longitude;
        }
      });
      return;
    }

    final i = activeSegmentIndex - 2;
    if (i >= 0 && i < extraDestinationControllers.length) {
      final c = extraDestinationControllers[i];
      c.text = description;
      c.selection = TextSelection.fromPosition(
        TextPosition(offset: c.text.length),
      );

      // Also resolve for extra stops if needed
      getLatLngFromAddress(description).then((latLng) {
        if (latLng != null && activeSegmentIndex == (i + 2)) {
          // We don't have reactive lat/lng list for extra stops yet in this controller state,
          // but we can at least resolve if we add them later.
        }
      });
    }
  }

  bool applySavedPlaceToLocationSelection({
    required SavedPlace savedPlace,
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
    final saved = savedPlace.address?.trim();
    if (saved == null || saved.isEmpty) return false;

    final coords = savedPlace.location?.coordinates;
    final lat =
        savedPlace.lat ??
        ((coords != null && coords.length >= 2) ? coords[1] : null);
    final lng =
        savedPlace.lng ??
        ((coords != null && coords.length >= 2) ? coords[0] : null);

    applyLocationSelectionTextToSegment(
      activeSegmentIndex: activeSegmentIndex,
      text: saved,
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

    if (lat != null && lng != null) {
      if (activeSegmentIndex == 0) {
        routePickupLat.value = lat;
        routePickupLng.value = lng;
      } else if (activeSegmentIndex == 1) {
        routeDestinationLat.value = lat;
        routeDestinationLng.value = lng;
        destinationPlaceId.value = null;
      }
    }

    searchQuery.value = '';
    return true;
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
      onSave: (label) => saveAddressFromPrediction(item: item, label: label),
    );
  }

  Future<void> toggleAddAddressBottomSheetForRecent(
    RecentDestinationModel loc,
  ) async {
    final saved = getSavedPlaceFor(loc.address, null);
    if (saved?.id != null) {
      await _confirmAndDeleteSavedPlace(saved!);
      return;
    }
    await _openAddFavoriteBottomSheet(
      address: loc.address.trim(),
      onSave: (label) => saveAddressFromRecentLocation(loc: loc, label: label),
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
      onSave: (label) => saveAddressFromAddress(
        address: address,
        label: label,
        lat: lat,
        lng: lng,
      ),
    );
  }

  Future<void> _openAddFavoriteBottomSheet({
    required String address,
    required Future<void> Function(String label) onSave,
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
      onSave: (label) async {
        await onSave(label);
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
        final result = await profileRepository.deleteSavedPlace(savedPlaceId);
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
  }) async {
    final normalizedLabel = label.trim();
    final address = (item.description ?? '').trim();
    if (normalizedLabel.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterLabel.tr);
      return;
    }
    if (address.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.noLocationsFound.tr);
      return;
    }
    if (isSavingPlace.value) return;

    isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final latLng = await getLatLngFromAddress(address);
        final lat = latLng?.latitude ?? mapCenter.value.latitude;
        final lng = latLng?.longitude ?? mapCenter.value.longitude;
        final name = address.split(',').first.trim().isEmpty
            ? address
            : address.split(',').first.trim();

        final request = SaveRecentAsFavoriteRequest(
          label: normalizedLabel.toLowerCase(),
          name: name,
          address: address,
          lat: lat,
          lng: lng,
        );

        final result = await profileRepository.saveRecentAsFavorite(request);
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
    required RecentDestinationModel loc,
    required String label,
  }) async {
    final normalizedLabel = label.trim();
    final address = loc.address.trim();
    if (normalizedLabel.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.pleaseEnterLabel.tr);
      return;
    }
    if (address.isEmpty) {
      AppDialogs.showErrorDialog(message: AppStrings.noLocationsFound.tr);
      return;
    }
    if (isSavingPlace.value) return;

    isSavingPlace.value = true;
    try {
      await Loader.run(() async {
        final request = SaveRecentAsFavoriteRequest(
          label: normalizedLabel.toLowerCase(),
          name: address.split(',').first.trim().isEmpty
              ? address
              : address.split(',').first.trim(),
          address: address,
          lat: loc.lat,
          lng: loc.lng,
        );

        final result = await profileRepository.saveRecentAsFavorite(request);
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

        final result = await profileRepository.saveRecentAsFavorite(request);
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

class EstimateValidationOutcome {
  const EstimateValidationOutcome._({
    required this.canProceed,
    this.errorMessage,
    this.errorCode,
    this.estimate,
    this.estimatedAt,
  });

  final bool canProceed;
  final String? errorMessage;
  final String? errorCode;

  /// Fare estimate returned by the validation call; passed to vehicle
  /// selection so the same route is not estimated twice.
  final FareEstimateModel? estimate;
  final DateTime? estimatedAt;

  factory EstimateValidationOutcome.success({FareEstimateModel? estimate}) {
    return EstimateValidationOutcome._(
      canProceed: true,
      estimate: estimate,
      estimatedAt: estimate != null ? DateTime.now() : null,
    );
  }

  factory EstimateValidationOutcome.failure({
    required String message,
    String? errorCode,
  }) {
    return EstimateValidationOutcome._(
      canProceed: false,
      errorMessage: message,
      errorCode: errorCode,
    );
  }
}
