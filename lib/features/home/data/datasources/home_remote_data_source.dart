import 'package:selcom_rides_frontend/core/data/models/responses/rides/book_rides_response.dart';

import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/responses/rides/promo_validate_response.dart';
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

  Future<ReverseGeocodeModel?> reverseGeocode({
    required double lat,
    required double lng,
  });

  Future<GeocodeResponse> getGeocode({required String address});

  Future<FareEstimateResponseModel> estimateFare(FareEstimateRequest request);

  Future<BookRideResponse> bookRide(BookRideRequest request);

  /// `POST go/promo/validate` — does not show global error dialogs on 4xx.
  Future<PromoValidateResponse> validatePromo({
    required String code,
    required String vehicleTypeId,
    required int fareEstimate,
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
  Future<ReverseGeocodeModel?> reverseGeocode({
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
    if (response.statusCode == 400) {
      return null;
    }
    throw Exception('Reverse geocoding failed');
  }

  @override
  Future<GeocodeResponse> getGeocode({required String address}) async {
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

    final raw = response.data;
    Map<String, dynamic>? map;
    if (raw is Map<String, dynamic>) {
      map = Map<String, dynamic>.from(raw);
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    }

    if (map != null) {
      final httpStatus = response.statusCode;
      if (httpStatus != null && !map.containsKey('status_code')) {
        map['status_code'] = httpStatus;
      }
      late final FareEstimateResponseModel model;
      try {
        model = FareEstimateResponseModel.fromJson(map);
      } catch (_) {
        final code = map['error_code']?.toString().trim();
        if (code == 'VALID_DISTANCE_EXCEEDED') {
          final sc = map['status_code'];
          final int? parsedStatus = switch (sc) {
            null => httpStatus,
            final int i => i,
            final num n => n.toInt(),
            final String s => int.tryParse(s.trim()),
            _ => int.tryParse(sc.toString()),
          };
          model = FareEstimateResponseModel(
            statusCode: parsedStatus ?? httpStatus ?? 400,
            message: map['message']?.toString(),
            errorCode: code,
            data: null,
          );
        } else {
          rethrow;
        }
      }
      if (!model.isSuccess) {
        if (model.errorCode?.trim() == 'VALID_DISTANCE_EXCEEDED') {
          return model;
        }
        final msg = (model.message ?? '').trim();
        throw Exception(
          msg.isEmpty ? 'Unable to estimate fare for this route.' : msg,
        );
      }
      return model;
    }

    throw Exception('Unable to estimate fare for this route.');
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

    if (response.statusCode == 200 && response.data != null) {
      return BookRideResponse.fromJson(response.data);
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = (data['message'] as String?)?.trim();
      if (message != null && message.isNotEmpty) {
        throw Exception(message);
      }
    }

    throw Exception('Unable to complete your booking at this time.');
  }

  @override
  Future<PromoValidateResponse> validatePromo({
    required String code,
    required String vehicleTypeId,
    required int fareEstimate,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.promoValidate,
        method: ApiMethod.post,
        body: {
          'code': code.trim().toUpperCase(),
          'vehicle_type_id': vehicleTypeId,
          'fare_estimate': fareEstimate,
        },
        errorPresentationType: ErrorPresentationType.none,
        showLoader: false,
      ),
    );

    final body = response.data;
    return PromoValidateResponse.fromHttpResponse(
      httpStatus: response.statusCode,
      body: body,
    );
  }
}
