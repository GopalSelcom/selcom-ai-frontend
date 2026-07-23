import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart'
    hide Destination;
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/responses/rides/promo_available_response.dart';
import '../../../../core/data/models/responses/rides/promo_validate_response.dart';
import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/config/ride_payment_endpoints.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../models/geocode_response_model.dart';
import '../models/places_models.dart';

import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/create_saved_place_response.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/responses/rides/active_ride_response.dart'
    hide Destination;
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../profile/data/models/profile_response_model.dart';
import '../../../ride/data/models/recent_destinations_response.dart';

abstract class HomeRemoteDataSource {
  Future<VehicleTypesResponse> getVehicleTypes();

  Future<List<Destination>> getRecentDestinations();

  Future<GetSavedPlacesResponseModel?> getSavedPlaces();

  Future<ActiveRideResponseModel?> getActiveRide();

  Future<UserModel> getProfile();

  Future<bool> saveRecentAsFavorite(SaveRecentAsFavoriteRequest request);

  Future<bool> deleteSavedPlace(String id);

  Future<RideModel> getRideDetails(String rideId);

  Future<AutocompletePredictionModel?> autocomplete({required String input});

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

  /// `GET go/promo/available` — rider-facing promo list (not admin CRUD).
  Future<PromoAvailableResponse> getAvailablePromos({
    String? vehicleTypeId,
    int? fareEstimate,
  });
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  HomeRemoteDataSourceImpl();

  @override
  Future<VehicleTypesResponse> getVehicleTypes() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.getVehicleTypes,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final raw = response.data;
      if (raw is Map) {
        return VehicleTypesResponse.fromMap(Map<String, dynamic>.from(raw));
      }
    }

    return VehicleTypesResponse(
      statusCode: response.statusCode,
      message: null,
    );
  }

  @override
  Future<List<Destination>> getRecentDestinations() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.recentDestinations,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final body = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      final parsed = RecentDestinationsResponse.fromMap(body);
      return parsed.data?.destinations ?? [];
    }
    return [];
  }

  @override
  Future<GetSavedPlacesResponseModel?> getSavedPlaces() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.savedPlaces,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return GetSavedPlacesResponseModel.fromJson(
        response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map),
      );
    }
    return null;
  }

  @override
  Future<ActiveRideResponseModel?> getActiveRide() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.activeRide,
        method: ApiMethod.get,
        errorPresentationType: ErrorPresentationType.none
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return ActiveRideResponseModel.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.getProfile,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final profileResponse = UserProfileResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      return profileResponse.data.toUserModel();
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return const UserModel(id: '');
    }
    throw Exception('Failed to get profile');
  }

  @override
  Future<bool> saveRecentAsFavorite(SaveRecentAsFavoriteRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.saveRecentAsFavorite,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.data != null) {
      final createResponse = CreateSavedPlaceResponseModel.fromJson(
        response.data,
      );
      return createResponse.isSuccess;
    }
    return response.statusCode == 200;
  }

  @override
  Future<bool> deleteSavedPlace(String id) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.address.deleteSavedPlace(id),
        method: ApiMethod.delete,
      ),
    );
    return response.statusCode == 200;
  }

  @override
  Future<RideModel> getRideDetails(String rideId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.rideDetails(rideId),
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final rideData =
          response.data['data']?['ride'] ?? response.data['data'] ?? {};
      return RideModel.fromJson(rideData);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return RideModel.fromJson({'_id': rideId});
    }
    throw Exception('Failed to get ride details');
  }

  @override
  Future<AutocompletePredictionModel?> autocomplete({
    required String input,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.places.autocomplete,
        method: ApiMethod.get,
        queryParams: {Params.input: input},
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
        queryParams: {Params.lat: lat, Params.lng: lng},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return ReverseGeocodeModel.fromJson(response.data);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
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
        queryParams: {Params.address: address},
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return GeocodeResponse.fromJson(response.data);
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return GeocodeResponse(results: const [], status: 'ZERO_RESULTS');
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
            message: map['message'].toString(),
          );
        } else {
          rethrow;
        }
      }
      if (!model.isSuccess) {
        if (model.errorCode?.trim() == 'VALID_DISTANCE_EXCEEDED') {
          return model;
        }
        if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
          return model;
        }
        final msg = (model.message ?? '').trim();
        throw Exception(
          msg.isEmpty ? 'Unable to estimate fare for this route.' : msg,
        );
      }
      return model;
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return FareEstimateResponseModel(
        statusCode: response.statusCode,
        message: null,
        errorCode: null,
        data: null,
      );
    }
    throw Exception('Unable to estimate fare for this route.');
  }

  @override
  Future<BookRideResponse> bookRide(BookRideRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: RidePaymentEndpoints.bookRide,
        method: ApiMethod.post,
        body: request.toJson(),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return BookRideResponse.fromJson(response.data);
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        try {
          return BookRideResponse.fromJson(raw);
        } catch (_) {}
      }
      if (raw is Map) {
        try {
          return BookRideResponse.fromJson(Map<String, dynamic>.from(raw));
        } catch (_) {}
      }
      return BookRideResponse(
        statusCode: response.statusCode,
        message: null,
        data: null,
      );
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
          Params.code: code.trim().toUpperCase(),
          Params.vehicleTypeID: vehicleTypeId,
          Params.flareEstimate: fareEstimate,
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

  @override
  Future<PromoAvailableResponse> getAvailablePromos({
    String? vehicleTypeId,
    int? fareEstimate,
  }) async {
    final query = <String, dynamic>{};
    final vid = vehicleTypeId?.trim();
    if (vid != null && vid.isNotEmpty) {
      query[Params.vehicleTypeID] = vid;
    }
    if (fareEstimate != null && fareEstimate > 0) {
      query[Params.flareEstimate] = fareEstimate;
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.promoAvailable,
        method: ApiMethod.get,
        queryParams: query.isEmpty ? null : query,
        errorPresentationType: ErrorPresentationType.none,
        showLoader: false,
      ),
    );

    return PromoAvailableResponse.fromHttpResponse(
      httpStatus: response.statusCode,
      body: response.data,
    );
  }
}
