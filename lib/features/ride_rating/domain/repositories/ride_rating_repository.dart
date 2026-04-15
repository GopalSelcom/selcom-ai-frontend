import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ride_rating_ride_entity.dart';

abstract class RideRatingRepository {
  Future<Either<Failure, RideRatingRideEntity?>> getLastCompletedRide();

  Future<Either<Failure, bool>> submitRideRating({
    required String rideId,
    required int rating,
    required String comment,
  });

  Future<Either<Failure, bool>> skipRideRating({
    required String rideId,
  });
}
