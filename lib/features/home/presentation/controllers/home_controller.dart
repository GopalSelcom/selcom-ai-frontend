import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/home_repository.dart';
import '../../data/models/home_models.dart';
import '../../../ride/domain/repositories/ride_repository.dart';
import '../../../ride/data/models/ride_management_models.dart';

class HomeController extends GetxController {
  final HomeRepository homeRepository;
  final RideRepository rideRepository;

  HomeController({
    required this.homeRepository,
    required this.rideRepository,
  });

  // ── States ──
  final currentPosition = const LatLng(-6.7924, 39.2083).obs;
  final markers = <Marker>{}.obs;
  final polylines = <Polyline>{}.obs;

  final searchQuery = ''.obs;
  final suggestions = <Map<String, dynamic>>[].obs;
  final isSearching = false.obs;
  
  // Home Data
  final vehicleTypes = <VehicleTypeModel>[].obs;
  final recentDestinations = <RecentDestinationModel>[].obs;
  final isLoadingHomeData = false.obs;

  final selectedVehicle = ''.obs;
  final fareEstimate = Rxn<FareEstimateModel>();

  GoogleMapController? mapController;

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

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _loadHomeData() async {
    isLoadingHomeData.value = true;
    
    // Fetch Vehicle Types & Recent Destinations in parallel
    final results = await Future.wait([
      homeRepository.getVehicleTypes(),
      rideRepository.getRecentDestinations(),
    ]);

    // Handle Vehicle Types
    results[0].fold(
      (failure) => null, // Handle error silently or show snackbar
      (types) => vehicleTypes.assignAll(types as List<VehicleTypeModel>),
    );

    // Handle Recent Destinations
    results[1].fold(
      (failure) => null,
      (destinations) => recentDestinations.assignAll(destinations as List<RecentDestinationModel>),
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
    // For demo, we just simulate a destination selection
    final destination = {'lat': -6.8000, 'lng': 39.2100};

    // Fetch Fare Estimate
    final result = await homeRepository.estimateFare(
      pickup: {'lat': currentPosition.value.latitude, 'lng': currentPosition.value.longitude},
      destination: destination,
    );

    result.fold(
      (failure) => fareEstimate.value = null,
      (estimate) {
        fareEstimate.value = estimate;
        _updateMapWithRoute(destination);
      },
    );
  }

  void _updateMapWithRoute(Map<String, dynamic> dest) {
    final destLatLng = LatLng(dest['lat'], dest['lng']);
    markers.clear();
    markers.add(Marker(markerId: const MarkerId('pickup'), position: currentPosition.value));
    markers.add(Marker(markerId: const MarkerId('destination'), position: destLatLng));

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: currentPosition.value.latitude < destLatLng.latitude ? currentPosition.value : destLatLng,
          northeast: currentPosition.value.latitude > destLatLng.latitude ? currentPosition.value : destLatLng,
        ),
        50.0,
      ),
    );
  }

  void _addMockDrivers() {
    final base = currentPosition.value;
    markers.addAll([
      Marker(
        markerId: const MarkerId('driver1'),
        position: LatLng(base.latitude + 0.002, base.longitude + 0.002),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('driver2'),
        position: LatLng(base.latitude - 0.001, base.longitude + 0.003),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
      Marker(
        markerId: const MarkerId('driver3'),
        position: LatLng(base.latitude + 0.003, base.longitude - 0.001),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
    ]);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    currentPosition.value = LatLng(position.latitude, position.longitude);

    mapController?.animateCamera(
      CameraUpdate.newLatLng(currentPosition.value),
    );
  }
}
