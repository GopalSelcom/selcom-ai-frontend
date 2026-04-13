import 'package:selcom_rides_frontend/core/data/models/responses/rides/book_rides_response.dart';

import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../models/geocode_response_model.dart';
import '../models/places_models.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class HomeRemoteDataSource {
  Future<List<VehicleTypeModel>> getVehicleTypes();

  Future<AutocompletePredictionModel?> autocomplete({
    required String input,
    required String sessionToken,
  });

  Future<ReverseGeocodeModel> reverseGeocode({
    required double lat,
    required double lng,
  });

  Future<GeocodeResponse> getGeocode({
    required String address,
  });

  Future<FareEstimateResponseModel> estimateFare(FareEstimateRequest request);

  Future<BookRideResponse> bookRide(BookRideRequest request);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl();

  @override
  Future<List<VehicleTypeModel>> getVehicleTypes() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.getVehicleTypes,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final vehicleResponse = VehicleTypesResponseModel.fromJson(response.data);
      return vehicleResponse.data?.vehicleTypes ?? [];
    }
    return [];
  }

  @override
  Future<AutocompletePredictionModel?> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.places.autocomplete,
        method: ApiMethod.get,
        queryParams: {'input': input, 'session_token': sessionToken},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return AutocompletePredictionModel.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<ReverseGeocodeModel> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.places.reverseGeocode,
        method: ApiMethod.get,
        queryParams: {'lat': lat, 'lng': lng},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return ReverseGeocodeModel.fromJson(response.data);
    }
    throw Exception('Reverse geocoding failed');
  }

  @override
  Future<GeocodeResponse> getGeocode({
    required String address,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.places.geocode,
        method: ApiMethod.get,
        queryParams: {'address': address},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return GeocodeResponse.fromJson(response.data);
    }
    throw Exception('Geocoding failed');
  }

  @override
  Future<FareEstimateResponseModel> estimateFare(
    FareEstimateRequest request,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.estimateFare,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    return FareEstimateResponseModel.fromJson(response.data);
  }

  @override
  Future<BookRideResponse> bookRide(BookRideRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.bookRide,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    return BookRideResponse.fromJson(response.data);
  }
}
