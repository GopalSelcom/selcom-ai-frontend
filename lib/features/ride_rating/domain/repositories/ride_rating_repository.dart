import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/submit_ride_rating_request.dart';
import '../../../../core/data/models/responses/rides/review_tags_response.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ride_rating_ride_entity.dart';

abstract class RideRatingRepository {
  Future<Either<Failure, RideRatingRideEntity?>> getLastCompletedRide();

  Future<Either<Failure, List<ReviewTagModel>>> getReviewTags({
    required int rating,
  });

  Future<Either<Failure, bool>> submitRideRating(
    SubmitRideRatingRequest request,
  );

  Future<Either<Failure, bool>> skipRideRating({required String rideId});
}
