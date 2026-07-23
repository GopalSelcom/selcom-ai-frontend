import '../../../../core/data/models/requests/submit_ride_rating_request.dart';
import '../../../../core/data/models/responses/rides/review_tags_response.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../models/pending_review_response.dart';

abstract class RideRatingRemoteDataSource {
  Future<PendingReview?> getLastCompletedRide();

  Future<ReviewTagsResponse> getReviewTags({required int rating});

  Future<bool> submitRideRating(SubmitRideRatingRequest request);

  Future<bool> skipRideRating({required String rideId});
}

class RideRatingRemoteDataSourceImpl implements RideRatingRemoteDataSource {
  RideRatingRemoteDataSourceImpl();

  @override
  Future<PendingReview?> getLastCompletedRide() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.pendingReview,
        method: ApiMethod.get,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200) {
      final raw = response.data;
      if (raw is Map) {
        final parsed = PendingReviewResponse.fromMap(
          Map<String, dynamic>.from(raw),
        );
        return parsed.data?.pendingReview;
      }
      return null;
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode) ||
        response.statusCode == 404) {
      return null;
    }

    throw Exception(
      _errorMessageFromResponse(response, 'Unable to load ride.'),
    );
  }

  @override
  Future<ReviewTagsResponse> getReviewTags({required int rating}) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.reviewTags,
        method: ApiMethod.get,
        queryParams: {Params.rating: rating},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    final body = response.data;
    if (body is Map<String, dynamic>) {
      return ReviewTagsResponse.fromJson(body);
    }
    if (body is Map) {
      return ReviewTagsResponse.fromJson(Map<String, dynamic>.from(body));
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return ReviewTagsResponse(statusCode: response.statusCode);
    }

    throw Exception(
      _errorMessageFromResponse(response, 'Unable to load review tags.'),
    );
  }

  @override
  Future<bool> submitRideRating(SubmitRideRatingRequest request) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.rateRide(request.rideId),
        method: ApiMethod.post,
        body: request.toJson(),
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200) {
      return true;
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return false;
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
  Future<bool> skipRideRating({required String rideId}) async {
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

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return false;
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
