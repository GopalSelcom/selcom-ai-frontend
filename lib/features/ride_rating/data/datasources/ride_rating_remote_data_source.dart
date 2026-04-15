import '../models/ride_rating_ride_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class RideRatingRemoteDataSource {
  Future<RideRatingRideModel?> getLastCompletedRide();

  Future<bool> submitRideRating({
    required String rideId,
    required int rating,
    required String comment,
  });

  Future<bool> skipRideRating({
    required String rideId,
  });
}

class RideRatingRemoteDataSourceImpl implements RideRatingRemoteDataSource {
  RideRatingRemoteDataSourceImpl();

  @override
  Future<RideRatingRideModel?> getLastCompletedRide() async {
    // TODO(api): enable once backend endpoint is ready.
    // GET /v4/go/rides/last-completed
    // final response = await ApiService().call(
    //   request: ApiRequest(
    //     endpoint: 'go/rides/last-completed',
    //     method: ApiMethod.get,
    //   ),
    // );
    // if (response.statusCode == 200) {
    //   return RideRatingRideModel.fromJson(response.data['data'] ?? {});
    // }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return RideRatingRideModel.mock();
  }

  @override
  Future<bool> submitRideRating({
    required String rideId,
    required int rating,
    required String comment,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.rateRide(rideId),
        method: ApiMethod.post,
        body: {'rating': rating, 'comment': comment},
      ),
    );

    if (response.statusCode == 200) {
      return true;
    }

    final data = response.data;
    final message = data is Map<String, dynamic>
        ? (data['message']?.toString() ??
              data['error']?.toString() ??
              data['error_message']?.toString() ??
              'Unable to submit rating.')
        : 'Unable to submit rating.';
    throw Exception(message);
  }

  @override
  Future<bool> skipRideRating({
    required String rideId,
  }) async {
    // TODO(api): enable when skip-rating endpoint is confirmed and ready.
    // POST /v4/go/rides/{{rideId}}/skip-rating
    // final response = await ApiService().call(
    //   request: ApiRequest(
    //     endpoint: URLS.ride.skipRideRating(rideId),
    //     method: ApiMethod.post,
    //   ),
    // );
    // if (response.statusCode == 200) {
    //   return true;
    // }
    // final data = response.data;
    // final message = data is Map<String, dynamic>
    //     ? (data['message']?.toString() ??
    //           data['error']?.toString() ??
    //           data['error_message']?.toString() ??
    //           'Unable to skip rating.')
    //     : 'Unable to skip rating.';
    // throw Exception(message);

    await Future<void>.delayed(const Duration(milliseconds: 250));
    return true;
  }
}
