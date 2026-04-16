import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ride_rating_ride_entity.dart';
import '../entities/ride_rating_tag_entity.dart';

abstract class RideRatingRepository {
  Future<Either<Failure, RideRatingRideEntity?>> getLastCompletedRide();

  Future<Either<Failure, List<RideRatingTagEntity>>> getReviewTags({
    required int rating,
  });

  Future<Either<Failure, bool>> submitRideRating({
    required String rideId,
    required int rating,
    required List<String> tags,
    required String comment,
  });

  Future<Either<Failure, bool>> skipRideRating({
    required String rideId,
  });
}
