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
import '../../../../core/services/app_map_service.dart';
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

// ── Concern splits (same library via `part`; helpers access private fields) ──
// mapHelper ................ GPS, camera, reverse geocode, pickup markers
// sheetHelper .............. draggable home sheet sizing / snaps
// activeRidesHelper ........ poll, stack UI, open active ride
// bookingNavigationHelper .. fare gate → vehicle / location selection
// placesHelper ............. recent destinations, saved places, chips
// locationSelectionHelper .. helpers used by LocationSelectionController
part 'parts/home_controller_map.dart';
part 'parts/home_controller_sheet.dart';
part 'parts/home_controller_active_rides.dart';
part 'parts/home_controller_booking_navigation.dart';
part 'parts/home_controller_places.dart';
part 'parts/home_controller_location_selection.dart';

/// Home map + bottom sheet orchestration (SCR-06).
///
/// Owns shared state and lifecycle. Behavior is split into `parts/` helper
/// classes (same library) so map, sheet, active rides, booking, and places
/// can change independently.
class HomeController extends GetxController with WidgetsBindingObserver {
  /// Sentinel id for the synthetic "Current location" saved-place row.
  static const String _currentLocationPlaceId = '__current_location__';

  /// Maximum draggable height (fraction of screen).
  static const double homeSheetMaxSize = 0.9;

  /// Default height when recent destinations are available.
  static const double homeSheetWithRecentDefaultSize = 0.7;

  /// Floor for collapsed sheet peek.
  static const double homeSheetCollapsedPeekMin = 0.28;

  /// Ensures pending-review sheet runs only once per app session on Home.
  static bool _didCheckPendingReviewOnHomeLaunch = false;

  /// Home feature repository (places, fare, active rides, profile).
  final HomeRepository homeRepository;

  /// Product analytics (screen views and home-flow events).
  final AnalyticsService analyticsService;

  /// Notification / call permission flow run when Home opens.
  final NotificationService notificationService;

  /// Pending ride-rating sheet after first Home load.
  final RideRatingController rideRatingController;

  HomeController({
    required this.homeRepository,
    required this.analyticsService,
    required this.notificationService,
    required this.rideRatingController,
  });

  // ── States ──

  /// Autocomplete query bound to location-selection / saved-location search.
  final searchQuery = ''.obs;

  /// Autocomplete prediction results for [searchQuery].
  final List<Prediction> suggestions = <Prediction>[].obs;

  /// Recent search strings for location selection.
  final recentSearches = <String>[].obs;

  /// True while autocomplete is in flight.
  final isSearching = false.obs;

  /// True while a save-favorite API call is in flight.
  final isSavingPlace = false.obs;

  /// True while location-selection → booking navigation is in progress.
  final isProceedingToBooking = false.obs;

  /// Vehicle types for the home explore row.
  final vehicleTypes = <VehicleType>[].obs;

  /// Recent destinations shown on the home sheet.
  final recentDestinations = <RecentDestination>[].obs;

  /// Recent destinations for the dedicated recent-locations screen.
  final recentDestinationsScreen = <RecentDestination>[].obs;

  /// User saved places (favorites / Home / Office / …).
  final savedPlaces = <SavedPlace>[].obs;

  /// Primary (first) active ride for the home overlay card.
  final activeRide = Rxn<RideModel>();

  /// All in-progress rides for the stack UI.
  final activeRides = <RideModel>[].obs;

  /// Whether the multi-ride stack is expanded.
  final isActiveRidesExpanded = false.obs;

  /// Home chips only: last tapped chip before leaving home (highlight on return).
  final RxnString recentHomeChipKey = RxnString();

  /// Picked saved address for pickup (header dropdown). Map + chips use this when set.
  final selectedPickupSavedPlaceId = Rxn<String>(_currentLocationPlaceId);

  /// Whether the address-header saved-places list is expanded.
  final isSavedPlacesExpanded = false.obs;

  /// True while the parallel home bootstrap fetch is running.
  final isLoadingHomeData = false.obs;

  /// In-flight [_loadHomeData] future used to coalesce concurrent callers.
  Future<void>? _loadHomeDataInFlight;

  /// True after the first [_loadHomeData] attempt finishes (success or partial).
  /// Location selection uses this to reuse in-memory recent/saved places.
  bool hasCompletedInitialHomeLoad = false;

  /// True while the recent-locations screen list is loading.
  final isLoadingRecentLocationsScreen = false.obs;

  /// Profile avatar URL for the home header.
  final profileImageUrl = ''.obs;

  /// Current map camera target (may differ from GPS when panned).
  final mapCenter = const LatLng(-6.7924, 39.2083).obs;

  /// Reverse-geocoded (or placeholder) address for [mapCenter].
  final currentMapAddress = AppStrings.locating.tr.obs;

  /// True once [onMapCreated] has run.
  final isMapReady = false.obs;

  /// Gates embedding the native GoogleMap. Opens synchronously in [onInit]
  /// so Home never sticks on the gray placeholder waiting for permissions.
  final homeMapSurfaceReady = false.obs;

  /// Bumped on every forced remount so [_HomeMapHost] can use a fresh [ValueKey]
  /// (AndroidViews under a long ride stack often stay blank if the key is reused).
  final homeMapMountGeneration = 0.obs;

  /// Until this time, sheet-drag camera nudges are skipped so map create can settle.
  DateTime? _suppressSheetCameraNudgesUntil;

  /// True while reverse geocode for the map center is in flight.
  final isResolvingAddress = false.obs;

  /// True when location permission + services allow GPS features.
  final hasLocationPermission = false.obs;

  /// Draggable home bottom sheet size (fraction of screen height).
  final sheetSize = homeSheetCollapsedPeekMin.obs;

  /// Controller for the home [DraggableScrollableSheet].
  final DraggableScrollableController homeSheetController =
      DraggableScrollableController();

  /// Measured sheet content height in px (from layout); drives max/initial sizes.
  final measuredSheetContentHeightPx = RxnDouble();

  /// Screen height used with [measuredSheetContentHeightPx] for sheet fractions.
  final measuredSheetLayoutHeightPx = RxnDouble();

  /// Last device GPS fix — used for 1 km radius overlay (does not follow map pan).
  final Rxn<LatLng> deviceGpsLocation = Rxn<LatLng>();

  /// Selected vehicle type name (legacy / explore; booking may override).
  final selectedVehicle = ''.obs;

  /// Cached fare estimate when navigated with an initial estimate.
  final fareEstimate = Rxn<FareEstimateResponse>();

  /// Native Google Map controller for camera moves.
  GoogleMapController? _mapController;

  /// Shared socket client (leave ride room on Home; join when opening a ride).
  final AppSocketService _socketService = AppSocketService();

  /// Suppresses pickup-reset-on-pan while programmatically moving the camera.
  bool _ignoreSelectionReset = false;

  /// Periodic timer for active-ride polling.
  Timer? _activeRidePollingTimer;

  /// Guards concurrent [refreshActiveRide] calls.
  bool _isRefreshingActiveRide = false;

  /// Coalesces rapid [onHomeVisible] refresh requests.
  bool _activeRideRefreshQueued = false;

  /// Skips the first [onHomeVisible] refresh right after [onInit].
  bool _skipNextVisibleRefresh = true;

  /// Throttle timestamp for [refreshActiveRide].
  DateTime? _lastActiveRideRefreshAt;

  /// Guards concurrent GPS recenter / permission resolution.
  bool _isResolvingLocationPermission = false;

  /// Last known map zoom (kept across sheet nudges).
  double _cachedMapZoom = 16;

  /// Debounces full GPS recenter after sheet drag.
  Timer? _sheetCameraSettleTimer;

  /// True after [onClose] — sheet listeners must no-op.
  bool _isClosed = false;

  /// Custom blue pickup pin for the home map.
  final pickupMarkerIcon = Rxn<BitmapDescriptor>();

  /// Location-selection: pickup segment is the active editing target.
  final RxBool isPickupSelected = false.obs;

  /// Location-selection: destination segment is the active editing target.
  final RxBool isDestinationSelected = false.obs;

  /// GPS, camera, reverse geocode, pickup markers.
  late final HomeMapHelper mapHelper;

  /// Draggable home sheet sizing / snaps.
  late final HomeSheetHelper sheetHelper;

  /// Active-ride poll, stack UI, open active ride.
  late final HomeActiveRidesHelper activeRidesHelper;

  /// Fare gate → vehicle / location selection navigation.
  late final HomeBookingNavigationHelper bookingNavigationHelper;

  /// Recent destinations, saved places, chips.
  late final HomePlacesHelper placesHelper;

  /// Helpers used by [LocationSelectionController].
  late final HomeLocationSelectionHelper locationSelectionHelper;

  /// Builds concern helpers once before any bootstrap / permission work.
  void _initHelpers() {
    mapHelper = HomeMapHelper(this);
    sheetHelper = HomeSheetHelper(this);
    activeRidesHelper = HomeActiveRidesHelper(this);
    bookingNavigationHelper = HomeBookingNavigationHelper(this);
    placesHelper = HomePlacesHelper(this);
    locationSelectionHelper = HomeLocationSelectionHelper(this);
  }

  // ── Public API delegates (screens / LocationSelectionController / others) ──

  /// Recenter on device GPS; requests permission and may open settings.
  Future<void> recenterMap() => mapHelper.recenterMap();

  /// 200 m radius around device GPS (not map drag position).
  Set<Circle> get nearbyPickupRadiusCircles =>
      mapHelper.nearbyPickupRadiusCircles;

  /// Pin for the pickup implied by the header dropdown.
  Set<Marker> get selectedPickupMarkers => mapHelper.selectedPickupMarkers;

  /// Called when the home map is ready.
  void onMapCreated(GoogleMapController controller) =>
      mapHelper.onMapCreated(controller);

  /// Caches zoom after the home map camera stops moving.
  void onHomeMapCameraIdle() => mapHelper.onHomeMapCameraIdle();

  /// Updates map center while dragging.
  void onCameraMove(CameraPosition position) =>
      mapHelper.onCameraMove(position);

  /// Reverse-geocodes after the camera settles.
  Future<void> onCameraIdle() => mapHelper.onCameraIdle();

  /// Synthetic "Current location" row for the address header.
  SavedPlace get currentLocationHeaderPlace =>
      mapHelper.currentLocationHeaderPlace;

  /// Saved place currently selected as pickup, or null when using GPS.
  SavedPlace? get activePickupSavedPlace => mapHelper.activePickupSavedPlace;

  /// Coordinates for booking / chips: saved pickup or live map center.
  LatLng get activePickupLatLng => mapHelper.activePickupLatLng;

  /// GPS / permission placeholders — not real addresses for text fields.
  bool isNonSelectableMapAddress(String address) =>
      mapHelper.isNonSelectableMapAddress(address);

  /// Hint when GPS is off or denied (location selection).
  String? get mapAddressSetupHint => mapHelper.mapAddressSetupHint;

  /// Human-readable pickup address for booking.
  String get activePickupAddress => mapHelper.activePickupAddress;

  /// Distance from device GPS to [lat]/[lng] for list rows.
  String calculateDistanceKm(double? lat, double? lng) =>
      mapHelper.calculateDistanceKm(lat, lng);

  /// Geocodes [address]; failures resolve to `null`.
  Future<LatLng?> getLatLngFromAddress(String address) =>
      mapHelper.getLatLngFromAddress(address);

  /// Geocodes [address] for booking / stop flows.
  Future<LatLng?> resolveAddressCoordinates(
    String address, {
    void Function(String message)? onFailure,
  }) =>
      mapHelper.resolveAddressCoordinates(address, onFailure: onFailure);

  /// Clears measured sheet content so the next layout re-drives sizing.
  void invalidateHomeSheetMeasurement() =>
      sheetHelper.invalidateHomeSheetMeasurement();

  /// Records sheet content height from layout.
  void reportHomeSheetContentHeight({
    required double contentHeightPx,
    required double layoutHeightPx,
  }) =>
      sheetHelper.reportHomeSheetContentHeight(
        contentHeightPx: contentHeightPx,
        layoutHeightPx: layoutHeightPx,
      );

  /// Updates reactive sheet size and nudges the map camera.
  void updateHomeSheetSize(double size) =>
      sheetHelper.updateHomeSheetSize(size);

  /// True when recent destinations should influence sheet default height.
  bool get hasRecentLocationsForSheet =>
      sheetHelper.hasRecentLocationsForSheet;

  /// Smallest drag height for the home sheet.
  double get homeSheetMinSize => sheetHelper.homeSheetMinSize;

  /// Uncapped content height as a fraction of the screen.
  double get homeSheetRawContentFraction =>
      sheetHelper.homeSheetRawContentFraction;

  /// True after the sheet has reported a real content height.
  bool get homeSheetHasMeasuredContent =>
      sheetHelper.homeSheetHasMeasuredContent;

  /// True when content exceeds 90% and needs inner scroll.
  bool get homeSheetNeedsInnerScroll => sheetHelper.homeSheetNeedsInnerScroll;

  /// Natural content height capped at 90%.
  double get homeSheetContentSizeFraction =>
      sheetHelper.homeSheetContentSizeFraction;

  /// Max drag size for the home sheet.
  double get homeSheetMaxChildSize => sheetHelper.homeSheetMaxChildSize;

  /// Scroll physics for the home sheet body.
  ScrollPhysics get homeSheetScrollPhysics =>
      sheetHelper.homeSheetScrollPhysics;

  /// True when the 70% expanded default should be used.
  bool get homeSheetShouldUseExpandedDefault =>
      sheetHelper.homeSheetShouldUseExpandedDefault;

  /// Resting / initial sheet fraction.
  double get homeSheetInitialSize => sheetHelper.homeSheetInitialSize;

  /// Snap points for the draggable sheet.
  List<double> get homeSheetSnapSizes => sheetHelper.homeSheetSnapSizes;

  /// Whether snap-to points should be enabled.
  bool get homeSheetShouldSnap => sheetHelper.homeSheetShouldSnap;

  /// Jumps or animates the sheet to its default size.
  void syncHomeSheetToDefault({bool animated = false}) =>
      sheetHelper.syncHomeSheetToDefault(animated: animated);

  /// Count of extra active rides beyond the primary card.
  int get additionalActiveRidesCount =>
      activeRidesHelper.additionalActiveRidesCount;

  /// True when more than one in-progress ride should be stacked.
  bool get hasMultipleActiveRides => activeRidesHelper.hasMultipleActiveRides;

  /// Stops periodic active-ride polling.
  void stopActiveRidePolling() => activeRidesHelper.stopActiveRidePolling();

  /// Fetches the latest active-ride list (throttled unless [force]).
  Future<void> refreshActiveRide({bool force = false}) =>
      activeRidesHelper.refreshActiveRide(force: force);

  /// Whether the stacked active-rides UI can expand.
  bool get canExpandActiveRides => activeRidesHelper.canExpandActiveRides;

  /// Expands the multi-ride stack on Home.
  void expandActiveRidesStack() => activeRidesHelper.expandActiveRidesStack();

  /// Collapses the multi-ride stack on Home.
  void collapseActiveRidesStack() =>
      activeRidesHelper.collapseActiveRidesStack();

  /// Title line for an active-ride card.
  String activeRideRouteTitle(RideModel ride) =>
      activeRidesHelper.activeRideRouteTitle(ride);

  /// Remaining-time label for an active-ride card.
  String activeRideRemainingLabel(RideModel ride) =>
      activeRidesHelper.activeRideRemainingLabel(ride);

  /// Vehicle image asset path for an active-ride card.
  String activeRideVehicleImageAsset(RideModel ride) =>
      activeRidesHelper.activeRideVehicleImageAsset(ride);

  /// Opens the ongoing-ride screen for [ride] (or the primary active ride).
  Future<void> openActiveRide([RideModel? ride]) =>
      activeRidesHelper.openActiveRide(ride);

  /// Fare estimate gate for location / booking flows.
  Future<EstimateValidationOutcome> validateEstimateForRoute({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required LocationEntity destination,
    List<LocationEntity> stops = const [],
  }) =>
      bookingNavigationHelper.validateEstimateForRoute(
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destination: destination,
        stops: stops,
      );

  /// Surfaces a failed estimate validation after the loader dismisses.
  Future<void> presentEstimateValidationError(
    EstimateValidationOutcome outcome,
  ) =>
      bookingNavigationHelper.presentEstimateValidationError(outcome);

  /// Books from a preset saved-place chip label.
  Future<void> navigateToVehicleSelectionForSavedLabel(String label) =>
      bookingNavigationHelper.navigateToVehicleSelectionForSavedLabel(label);

  /// Books from a specific [SavedPlace].
  Future<void> navigateToVehicleSelectionForSavedPlace(SavedPlace place) =>
      bookingNavigationHelper.navigateToVehicleSelectionForSavedPlace(place);

  /// Opens location selection with [loc] as destination (GPS off path).
  Future<void> openLocationSelectionForRecentDestination(
    RecentDestination loc,
  ) =>
      bookingNavigationHelper.openLocationSelectionForRecentDestination(loc);

  /// Books from a recent destination (or location selection if GPS off).
  Future<void> navigateToVehicleSelectionForRecentDestination(
    RecentDestination loc, {
    bool showHomeFareEstimateLoader = false,
  }) =>
      bookingNavigationHelper.navigateToVehicleSelectionForRecentDestination(
        loc,
        showHomeFareEstimateLoader: showHomeFareEstimateLoader,
      );

  /// Opens location selection with current active pickup.
  Future<void> openLocationSelection({VehicleType? preferredVehicle}) =>
      bookingNavigationHelper.openLocationSelection(
        preferredVehicle: preferredVehicle,
      );

  /// Opens location selection with a preferred vehicle from the explore row.
  Future<void> openLocationSelectionWithPreferredVehicle(VehicleType vehicle) =>
      bookingNavigationHelper.openLocationSelectionWithPreferredVehicle(
        vehicle,
      );

  /// Pops the location selection route.
  void closeLocationSelection() =>
      bookingNavigationHelper.closeLocationSelection();

  /// Validates the route then navigates to booking from location selection.
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
  }) =>
      bookingNavigationHelper.proceedToBookingFromLocationSelection(
        pickup: pickup,
        destinations: destinations,
        destinationPlaceId: destinationPlaceId,
        routePickupLat: routePickupLat,
        routePickupLng: routePickupLng,
        routeDestinationLat: routeDestinationLat,
        routeDestinationLng: routeDestinationLng,
        preferredVehicleTypeId: preferredVehicleTypeId,
        preferredVehicleName: preferredVehicleName,
      );

  /// Explore-row vehicle image asset for [vehicleName].
  String vehicleExploreImageAsset(String vehicleName) =>
      bookingNavigationHelper.vehicleExploreImageAsset(vehicleName);

  /// Reloads recent destinations into the Home list.
  Future<void> reloadRecentDestinations() =>
      placesHelper.reloadRecentDestinations();

  /// Up to three recent destinations for the home sheet preview.
  List<RecentDestination> get recentDestinationsPreview =>
      placesHelper.recentDestinationsPreview;

  /// True when Home should show a "View more" link for recent destinations.
  bool get canViewMoreRecentLocations =>
      placesHelper.canViewMoreRecentLocations;

  /// Opens the full recent-locations screen.
  Future<void> openRecentLocationsScreen() =>
      placesHelper.openRecentLocationsScreen();

  /// Fetches recent destinations for the dedicated screen.
  Future<void> loadRecentLocationsScreen() =>
      placesHelper.loadRecentLocationsScreen();

  /// Reloads the recent-locations screen list.
  Future<void> refreshRecentDestinations() =>
      placesHelper.refreshRecentDestinations();

  /// Selects an autocomplete prediction as the current map address.
  Future<void> selectPlace(Prediction place) => placesHelper.selectPlace(place);

  /// Saves a recent destination as a labeled favorite.
  Future<void> saveRecentAsFavorite({
    required RecentDestination loc,
    required String label,
  }) =>
      placesHelper.saveRecentAsFavorite(loc: loc, label: label);

  /// Toggles favorite for a recent row.
  Future<void> toggleFavoriteForRecent(RecentDestination loc) =>
      placesHelper.toggleFavoriteForRecent(loc);

  /// Finds a saved place matching the preset [label].
  SavedPlace? getSavedPlaceByLabel(String label) =>
      placesHelper.getSavedPlaceByLabel(label);

  /// Saved places beyond the four preset chip slots.
  List<SavedPlace> get savedPlacesBeyondPresetSlots =>
      placesHelper.savedPlacesBeyondPresetSlots;

  /// Address subtitle for a preset chip.
  String? getSavedPlaceSubtitle(String label) =>
      placesHelper.getSavedPlaceSubtitle(label);

  /// Remembers which home chip was last tapped.
  void markRecentHomeChip(String key) => placesHelper.markRecentHomeChip(key);

  /// Handles tap on a preset favorite chip.
  void onHomePresetChipTap(String canonical, SavedPlace? place) =>
      placesHelper.onHomePresetChipTap(canonical, place);

  /// Handles tap on an extra saved-place chip.
  void onHomeExtraChipTap(SavedPlace place) =>
      placesHelper.onHomeExtraChipTap(place);

  /// Long-press on a preset chip.
  void onHomePresetChipLongPress(String canonical) =>
      placesHelper.onHomePresetChipLongPress(canonical);

  /// Long-press on an extra chip.
  void onHomeExtraChipLongPress(SavedPlace place) =>
      placesHelper.onHomeExtraChipLongPress(place);

  /// Reloads saved places from the API.
  Future<void> loadSavedPlaces() => placesHelper.loadSavedPlaces();

  /// Refreshes saved places after a save/delete mutation.
  Future<void> refreshSavedPlacesAfterMutation() =>
      placesHelper.refreshSavedPlacesAfterMutation();

  /// Sets pickup from a saved place (or GPS).
  Future<void> selectSavedPlaceAsPickup(SavedPlace place) =>
      placesHelper.selectSavedPlaceAsPickup(place);

  /// Whether [placeId] is the currently selected pickup.
  bool isSavedPlaceSelectedAsPickup(String? placeId) =>
      placesHelper.isSavedPlaceSelectedAsPickup(placeId);

  /// Places shown in the address-header dropdown.
  List<SavedPlace> get addressHeaderPlacesToShow =>
      placesHelper.addressHeaderPlacesToShow;

  /// Toggles the address-header saved-places dropdown.
  void toggleAddressHeaderExpansion() =>
      placesHelper.toggleAddressHeaderExpansion();

  /// Chevron rotation for the address-header expand affordance.
  double get addressHeaderChevronTurns =>
      placesHelper.addressHeaderChevronTurns;

  /// Chip subtitle with Home fallback to map address.
  String? chipSubtitleFor(String label) => placesHelper.chipSubtitleFor(label);

  /// First line of a recent destination address for list titles.
  String recentDestinationTitleLine(RecentDestination loc) =>
      placesHelper.recentDestinationTitleLine(loc);

  /// Whether the recent-destinations block should render.
  bool get shouldShowRecentSection => placesHelper.shouldShowRecentSection;

  /// Whether the vehicle explore row should render.
  bool get shouldShowVehicleSection => placesHelper.shouldShowVehicleSection;

  /// Finds a saved place by id or matching address.
  SavedPlace? getSavedPlaceFor(String address, String? placeId) =>
      placesHelper.getSavedPlaceFor(address, placeId);

  /// Whether the address is already a saved place (favourite).
  bool isPlaceFavorite(String address, String? placeId) =>
      placesHelper.isPlaceFavorite(address, placeId);

  /// Toggles add/remove favorite for an autocomplete prediction.
  Future<void> toggleAddAddressBottomSheet(Prediction item) =>
      placesHelper.toggleAddAddressBottomSheet(item);

  /// Toggles add/remove favorite for a recent destination.
  Future<void> toggleAddAddressBottomSheetForRecent(RecentDestination loc) =>
      placesHelper.toggleAddAddressBottomSheetForRecent(loc);

  /// Toggles add/remove favorite for a free-form address.
  Future<void> toggleAddAddressBottomSheetForAddress({
    required String address,
    double? lat,
    double? lng,
  }) =>
      placesHelper.toggleAddAddressBottomSheetForAddress(
        address: address,
        lat: lat,
        lng: lng,
      );

  /// Saves an autocomplete prediction as a labeled favorite.
  Future<void> saveAddressFromPrediction({
    required Prediction item,
    required String label,
    required String address,
  }) =>
      placesHelper.saveAddressFromPrediction(
        item: item,
        label: label,
        address: address,
      );

  /// Saves a recent destination as a labeled favorite.
  Future<void> saveAddressFromRecentLocation({
    required RecentDestination loc,
    required String label,
    required String address,
  }) =>
      placesHelper.saveAddressFromRecentLocation(
        loc: loc,
        label: label,
        address: address,
      );

  /// Saves a free-form address as a labeled favorite.
  Future<void> saveAddressFromAddress({
    required String address,
    required String label,
    double? lat,
    double? lng,
  }) =>
      placesHelper.saveAddressFromAddress(
        address: address,
        label: label,
        lat: lat,
        lng: lng,
      );

  /// Writes free-text into the active location-selection segment.
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
  }) =>
      locationSelectionHelper.applyLocationSelectionTextToSegment(
        activeSegmentIndex: activeSegmentIndex,
        text: text,
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

  /// Applies an autocomplete prediction to the active segment.
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
  }) =>
      locationSelectionHelper.applySuggestionToLocationSelection(
        prediction: prediction,
        activeSegmentIndex: activeSegmentIndex,
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

  /// Applies a saved place to the active segment.
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
  }) =>
      locationSelectionHelper.applySavedPlaceToLocationSelection(
        savedPlace: savedPlace,
        activeSegmentIndex: activeSegmentIndex,
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

  /// Applies a recent destination to the active segment.
  void applyRecentDestinationToLocationSelection({
    required RecentDestination destination,
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
  }) =>
      locationSelectionHelper.applyRecentDestinationToLocationSelection(
        destination: destination,
        activeSegmentIndex: activeSegmentIndex,
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

  /// Applies a recent-search string to the active segment.
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
  }) =>
      locationSelectionHelper.applyRecentSearchToLocationSelection(
        recentText: recentText,
        activeSegmentIndex: activeSegmentIndex,
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

  @override
  void onInit() {
    super.onInit();
    _initHelpers();
    homeSheetController.addListener(sheetHelper._onHomeSheetChanged);
    WidgetsBinding.instance.addObserver(this);
    analyticsService.logEvent('home_screen_viewed');
    // Open the map gate immediately — do not wait on permissions/lists or the
    // first build shows only the gray placeholder (broken after ride → home).
    homeMapSurfaceReady.value = true;
    // Warm map style cache before the platform view mounts (avoids a style
    // setState rebuild right after GoogleMap create).
    unawaited(AppMapService.loadBrandMapStyle());
    // Defer GPS/permission dialogs until after the first frames.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapHomeMapSurface());
    });
    activeRidesHelper._startActiveRidePolling();
    _loadHomeData().whenComplete(() {
      unawaited(_maybeOpenPendingRatingAfterHomeSettle());
    });

    // 300ms debounce with 2-char threshold for location autocomplete.
    debounce(searchQuery, (query) {
      final normalized = query.trim();
      if (normalized.length >= 2) {
        placesHelper._searchPlaces(normalized);
      } else {
        suggestions.clear();
      }
    }, time: const Duration(milliseconds: 300));
  }

  /// Opens pending-review only after map create has had time to settle.
  Future<void> _maybeOpenPendingRatingAfterHomeSettle() async {
    // Product rule: call pending-review API only once when app session
    // first opens Home, not on subsequent returns to Home.
    if (_didCheckPendingReviewOnHomeLaunch) return;
    _didCheckPendingReviewOnHomeLaunch = true;
    try {
      // Wait until the native map reports ready (or give up after a timeout so
      // rating is not blocked forever if the map fails to mount).
      final readyDeadline = DateTime.now().add(const Duration(seconds: 20));
      while (!isMapReady.value &&
          !_isClosed &&
          DateTime.now().isBefore(readyDeadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (_isClosed || SessionExpiryService.isHandling) return;

      // Extra calm window after map create — longer than the map "quiet"
      // period so rating does not overlap circle/padding unfreeze.
      await Future<void>.delayed(const Duration(milliseconds: 2800));
      if (_isClosed || SessionExpiryService.isHandling) return;

      await rideRatingController.tryOpenRatingSheetAfterHomeLoad();
    } catch (e, stackTrace) {
      AppLogger.e(
        'Pending review prompt failed: $e',
        tag: 'HomeController',
        stackTrace: stackTrace,
      );
    }
  }

  /// Runs permissions/GPS after first paint. Map gate is already open in [onInit].
  Future<void> _bootstrapHomeMapSurface() async {
    if (!_isClosed && !homeMapSurfaceReady.value) {
      homeMapSurfaceReady.value = true;
    }

    try {
      await _initSequentialPermissions().timeout(
        const Duration(seconds: 12),
        onTimeout: () {},
      );
    } catch (_) {
      // Map already visible; GPS/permission can settle afterward.
    } finally {
      if (!_isClosed) {
        unawaited(mapHelper._loadMapIcons());
      }
    }
  }

  /// Runs notification permissions then requests location.
  Future<void> _initSequentialPermissions() async {
    // 1. Run notification & call permissions flow (sequential system dialogs)
    await notificationService.runHomePermissionFlow();
    // 2. Request location permission immediately after notification flow completes
    await mapHelper._getCurrentLocation(requestPermissionIfDenied: true);
  }

  /// Coalesced bootstrap load of vehicles, places, active ride, and profile.
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

  /// Parallel home bootstrap fetch; updates reactive lists.
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

      // Apply all results synchronously before clearing the loading flag so the
      // UI transitions shimmer → content in one frame instead of five.
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
        placesHelper._syncSelectedPickupAfterSavedPlacesLoad();
      });

      // Handle Active Ride
      results[3].fold((_) => null, (response) {
        final activeRideResponse =
            response as active_ride_api.ActiveRideResponseModel?;
        activeRidesHelper._applyActiveRideResponse(activeRideResponse);
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
        // Invalidate before flipping loading so the first non-loading rebuild
        // measures real content (not the shimmer layout).
        invalidateHomeSheetMeasurement();
        isLoadingHomeData.value = false;
      }
    }
  }

  /// Called when Home becomes the active route — refresh active rides + map.
  void onHomeVisible() {
    if (SessionExpiryService.isHandling) return;

    // Map first — never gate remount on [Get.currentRoute]. After
    // [Get.offAllNamed] the route name can lag RouteAware [didPush], which
    // previously skipped ensure and left the gray placeholder forever.
    final isReturnToHome = !_skipNextVisibleRefresh;
    _ensureHomeMapSurfaceReady(forceRemount: isReturnToHome);

    if (_skipNextVisibleRefresh) {
      _skipNextVisibleRefresh = false;
      return;
    }

    // HomeScreen can stay mounted under ongoing-ride routes; only release the
    // ride room / refresh when Home is actually the active route.
    if (Get.currentRoute != AppRoutes.home) return;
    // Release ride socket room when user is on Home (one room at a time).
    _socketService.leaveJoinedRideRoom();

    if (isLoadingHomeData.value || _loadHomeDataInFlight != null) return;
    if (_activeRideRefreshQueued) return;
    _activeRideRefreshQueued = true;
    Future.microtask(() async {
      _activeRideRefreshQueued = false;
      await refreshActiveRide();
    });
  }

  /// Opens (or remounts) the home GoogleMap surface.
  void _ensureHomeMapSurfaceReady({bool forceRemount = false}) {
    if (_isClosed) return;

    if (forceRemount) {
      // Always pulse on return — AndroidView under a long ride stack is
      // frequently invalid even when we still hold a controller reference.
      homeMapMountGeneration.value++;
      homeMapSurfaceReady.value = false;
      isMapReady.value = false;
      _mapController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isClosed) return;
        homeMapSurfaceReady.value = true;
      });
      return;
    }

    if (!homeMapSurfaceReady.value) {
      homeMapSurfaceReady.value = true;
    }
  }

  /// Safety for [_HomeMapHost]: open the gate if a race left it closed.
  void ensureHomeMapSurfaceOpen() {
    if (_isClosed) return;
    if (!homeMapSurfaceReady.value) {
      homeMapSurfaceReady.value = true;
    }
  }

  /// Clears native map handles when the platform view is disposed.
  void onHomeMapDisposed() {
    _mapController = null;
    if (isMapReady.value) {
      isMapReady.value = false;
    }
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
        await mapHelper._getCurrentLocation();
      }
      await refreshActiveRide(force: true);
    });
  }

  @override
  void onClose() {
    _isClosed = true;
    _sheetCameraSettleTimer?.cancel();
    homeSheetController.removeListener(sheetHelper._onHomeSheetChanged);
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

  /// Opens profile and syncs avatar from cache on return.
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

  /// Writes [user.image] into [profileImageUrl].
  void _applyProfileImage(UserModel user) {
    profileImageUrl.value = user.image?.trim() ?? '';
  }
}
