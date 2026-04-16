import '../models/ride_rating_ride_model.dart';
import '../models/ride_rating_tag_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';

abstract class RideRatingRemoteDataSource {
  Future<RideRatingRideModel?> getLastCompletedRide();

  Future<List<RideRatingTagModel>> getReviewTags({
    required int rating,
  });

  Future<bool> submitRideRating({
    required String rideId,
    required int rating,
    required List<String> tags,
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
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.pendingReview,
        method: ApiMethod.get,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final payload = data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>?)
          : null;
      final pendingReview = payload?['pending_review'];
      if (pendingReview is Map<String, dynamic>) {
        return RideRatingRideModel.fromPendingReviewJson(pendingReview);
      }
      return null;
    }

    throw Exception(_errorMessageFromResponse(response, 'Unable to load ride.'));
  }

  @override
  Future<List<RideRatingTagModel>> getReviewTags({
    required int rating,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.reviewTags,
        method: ApiMethod.get,
        queryParams: {'rating': rating},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final payload = data is Map<String, dynamic>
          ? (data['data'] as Map<String, dynamic>?)
          : null;
      final tags = payload?['tags'];
      if (tags is List) {
        final parsed = tags
            .whereType<Map>()
            .map((item) => RideRatingTagModel.fromJson(item.cast<String, dynamic>()))
            .toList();
        parsed.sort((a, b) => a.order.compareTo(b.order));
        return parsed;
      }
      return const <RideRatingTagModel>[];
    }

    throw Exception(
      _errorMessageFromResponse(response, 'Unable to load review tags.'),
    );
  }

  @override
  Future<bool> submitRideRating({
    required String rideId,
    required int rating,
    required List<String> tags,
    required String comment,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.rateRide(rideId),
        method: ApiMethod.post,
        body: {
          'rating': rating,
          'tags': tags,
          if (comment.isNotEmpty) 'comment': comment,
        },
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200) {
      return true;
    }

    final errorCode = _errorCodeFromResponse(response);
    final message = _errorMessageFromResponse(
      response,
      'Unable to submit rating.',
    );
    if (errorCode.isNotEmpty) {
      throw Exception('$errorCode|$message');
    }
    throw Exception(message);
  }

  @override
  Future<bool> skipRideRating({
    required String rideId,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.skipRideRating(rideId),
        method: ApiMethod.put,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200) {
      return true;
    }

    final errorCode = _errorCodeFromResponse(response);
    final message = _errorMessageFromResponse(
      response,
      'Unable to skip rating.',
    );
    if (errorCode.isNotEmpty) {
      throw Exception('$errorCode|$message');
    }
    throw Exception(message);
  }

  String _errorCodeFromResponse(dynamic response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['error_code'] as String?)?.trim() ?? '';
    }
    return '';
  }

  String _errorMessageFromResponse(dynamic response, String fallback) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['error_message']?.toString() ??
          fallback;
    }
    return fallback;
  }
}
