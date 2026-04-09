import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../models/home_models.dart';
import '../models/places_models.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class HomeRemoteDataSource {
  Future<List<VehicleTypeModel>> getVehicleTypes();

  Future<List<AutocompletePredictionModel>> autocomplete({
    required String input,
    required String sessionToken,
  });

  Future<ReverseGeocodeModel> reverseGeocode({
    required double lat,
    required double lng,
  });

  Future<FareEstimateModel> estimateFare({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
  });

  Future<Map<String, dynamic>> bookRide({
    required String vehicleTypeId,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required int fare,
    required String paymentMethod,
    required String idempotencyKey,
  });
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
  Future<List<AutocompletePredictionModel>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.places.autocomplete,
        method: ApiMethod.get,
        queryParams: {
          'input': input,
          'session_token': sessionToken,
        },
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final List data = response.data['response'] ?? [];
      return data.map((e) => AutocompletePredictionModel.fromJson(e)).toList();
    }
    return [];
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
      return ReverseGeocodeModel.fromJson(response.data['response'] ?? {});
    }
    throw Exception('Reverse geocoding failed');
  }

  @override
  Future<FareEstimateModel> estimateFare({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.estimateFare,
        method: ApiMethod.post,
        body: {
          'pickup': pickup,
          'destination': destination,
        },
      ),
    );

    return FareEstimateModel.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> bookRide({
    required String vehicleTypeId,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required int fare,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.bookRide,
        method: ApiMethod.post,
        body: {
          'vehicle_type_id': vehicleTypeId,
          'pickup': pickup,
          'destination': destination,
          'fare': fare,
          'payment_method': paymentMethod,
          'idempotency_key': idempotencyKey,
        },
      ),
    );

    return response.data['data'] ?? response.data['response'] ?? {};
  }
}
