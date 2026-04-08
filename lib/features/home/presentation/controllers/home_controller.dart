import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../domain/repositories/home_repository.dart';
import '../../data/models/home_models.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';

class HomeController extends GetxController {
  final HomeRepository homeRepository;
  final RideRepository rideRepository;
  final ProfileRepository profileRepository;

  HomeController({
    required this.homeRepository,
    required this.rideRepository,
    required this.profileRepository,
  });

  // ── States ──
  final searchQuery = ''.obs;
  final suggestions = <Map<String, dynamic>>[].obs;
  final isSearching = false.obs;
  
  // Home Data
  final vehicleTypes = <VehicleTypeModel>[].obs;
  final recentDestinations = <RecentDestinationModel>[].obs;
  final savedPlaces = <SavedPlace>[].obs;
  final isSavedPlacesExpanded = false.obs;
  final isLoadingHomeData = false.obs;

  final selectedVehicle = ''.obs;
  final fareEstimate = Rxn<FareEstimateModel>();

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
    _addMockDrivers();
    _loadHomeData();

    // 1-second delay (debounce) for search logic
    debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        _searchPlaces(query);
      } else {
        suggestions.clear();
      }
    }, time: const Duration(seconds: 1));
  }

  void recenterMap() {
    // map implementation removed
  }

  Future<void> _loadHomeData() async {
    isLoadingHomeData.value = true;
    
    // Fetch Vehicle Types, Recent Destinations, & Saved Places in parallel
    final results = await Future.wait([
      homeRepository.getVehicleTypes(),
      rideRepository.getRecentDestinations(),
      profileRepository.getSavedPlaces(),
    ]);

    // Handle Vehicle Types
    results[0].fold(
      (failure) => null, // Handle error silently or show snackbar
      (types) => vehicleTypes.assignAll(types as List<VehicleTypeModel>),
    );

    // Handle Recent Destinations
    results[1].fold(
      (failure) => null,
      (destinations) {
        if (destinations is List<RecentDestinationModel>) {
          recentDestinations.assignAll(destinations);
        }
      },
    );

    // Handle Saved Places
    results[2].fold(
      (failure) => null,
      (response) {
        final res = response as GetSavedPlacesResponseModel?;
        if (res?.data?.savedPlaces != null) {
          savedPlaces.assignAll(res?.data!.savedPlaces! as List<SavedPlace>);
        }
      },
    );

    isLoadingHomeData.value = false;
  }

  Future<void> _searchPlaces(String input) async {
    isSearching.value = true;
    final result = await homeRepository.autocomplete(
      input: input,
      sessionToken: 'session_token_123',
    );
    result.fold(
      (failure) => suggestions.clear(),
      (list) => suggestions.assignAll(list.map((e) => {
            'description': e.description,
            'place_id': e.placeId,
          }).toList()),
    );
    isSearching.value = false;
  }

  Future<void> selectPlace(Map<String, dynamic> place) async {
    // Map / location selection UI stub
  }

  void _addMockDrivers() {
    // Removed map driver markers
  }

  Future<void> _getCurrentLocation() async {
    // Removed geolocation logic tied to map centering
  }
}
