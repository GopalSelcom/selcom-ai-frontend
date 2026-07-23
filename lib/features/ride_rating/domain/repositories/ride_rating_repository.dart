import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/submit_ride_rating_request.dart';
import '../../../../core/data/models/responses/rides/review_tags_response.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/pending_review_response.dart';

abstract class RideRatingRepository {
  Future<Either<Failure, PendingReview?>> getLastCompletedRide();

  Future<Either<Failure, List<ReviewTagModel>>> getReviewTags({
    required int rating,
  });

  Future<Either<Failure, bool>> submitRideRating(
    SubmitRideRatingRequest request,
  );

  Future<Either<Failure, bool>> skipRideRating({required String rideId});
}
