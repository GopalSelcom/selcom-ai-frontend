import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/responses/rides/active_ride_response.dart'
    as active_ride_api;
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/domain/entities/location_entity.dart';
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
import '../../../ride/data/models/recent_destinations_response.dart';
import '../../../ride_rating/presentation/controllers/ride_rating_controller.dart';
import '../../data/models/places_models.dart';
import '../../domain/repositories/home_repository.dart';
import '../screens/recent_locations_screen.dart';
import 'estimate_validation_outcome.dart';
import 'location_selection_controller.dart';

export 'estimate_validation_outcome.dart';

// ── Concern splits (same library via `part`; keep fields/lifecycle here) ──
// map ................ GPS, camera, reverse geocode, pickup markers
// sheet .............. draggable home sheet sizing / snaps
// active_rides ....... poll, stack UI, open active ride
// booking_navigation . fare gate → vehicle / location selection
// places ............. recent destinations, saved places, chips
// location_selection . helpers used by LocationSelectionController
part 'parts/home_controller_map.dart';
part 'parts/home_controller_sheet.dart';
part 'parts/home_controller_active_rides.dart';
part 'parts/home_controller_booking_navigation.dart';
part 'parts/home_controller_places.dart';
part 'parts/home_controller_location_selection.dart';

/// Home map + bottom sheet orchestration (SCR-06).
///
/// Owns shared state and lifecycle. Behavior is split into `parts/` extensions
/// so map, sheet, active rides, booking, and places can change independently.
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

  final AnalyticsService analyticsService;

  final NotificationService notificationService;

  final RideRatingController rideRatingController;

  HomeController({
    required this.homeRepository,
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
  final vehicleTypes = <VehicleType>[].obs;

  final recentDestinations = <RecentDestination>[].obs;

  final recentDestinationsScreen = <RecentDestination>[].obs;

  final savedPlaces = <SavedPlace>[].obs;

  final activeRide = Rxn<RideModel>();

  final activeRides = <RideModel>[].obs;

  final isActiveRidesExpanded = false.obs;

  /// Home chips only: last tapped chip before leaving home (highlight on return).
  final RxnString recentHomeChipKey = RxnString();

  /// Picked saved address for pickup (header dropdown). Map + chips use this when set.
  final selectedPickupSavedPlaceId = Rxn<String>(_currentLocationPlaceId);

  final isSavedPlacesExpanded = false.obs;

  final isLoadingHomeData = false.obs;

  Future<void>? _loadHomeDataInFlight;

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

  final fareEstimate = Rxn<FareEstimateResponse>();

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

  Future<void> _loadHomeData() async {
    if (SessionExpiryService.isHandling) return;
    if (_loadHomeDataInFlight != null) {
      return _loadHomeDataInFlight!;
    }

    final load = _performLoadHomeData();
    _loadHomeDataInFlight = load;
    try {
      await load;
    } finally {
      if (identical(_loadHomeDataInFlight, load)) {
        _loadHomeDataInFlight = null;
      }
    }
  }

  Future<void> _performLoadHomeData() async {
    isLoadingHomeData.value = true;
    try {
      // Fetch vehicle types, recent destinations, saved places, and profile in parallel.
      final results = await Future.wait([
        homeRepository.getVehicleTypes(),
        homeRepository.getRecentDestinations(),
        homeRepository.getSavedPlaces(),
        homeRepository.getActiveRide(),
        homeRepository.getProfile(),
      ]);

      // Handle Vehicle Types
      results[0].fold(
        (_) => null,
        (types) => vehicleTypes.assignAll(types as List<VehicleType>),
      );

      // Handle Recent Destinations
      results[1].fold((_) => null, (destinations) {
        if (destinations is List<RecentDestination>) {
          recentDestinations.assignAll(destinations);
        }
      });

      // Handle Saved Places
      results[2].fold((_) => null, (response) {
        final res = response as SavedPlacesResponse?;
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
    if (isLoadingHomeData.value || _loadHomeDataInFlight != null) return;
    if (_activeRideRefreshQueued) return;
    _activeRideRefreshQueued = true;
    Future.microtask(() async {
      _activeRideRefreshQueued = false;
      await refreshActiveRide();
    });
  }

  /// Clears active-ride UI/state when the session is no longer valid.
  void onSessionExpired() {
    stopActiveRidePolling();
    activeRide.value = null;
    activeRides.clear();
    isActiveRidesExpanded.value = false;
    _socketService.leaveJoinedRideRoom();
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
}
