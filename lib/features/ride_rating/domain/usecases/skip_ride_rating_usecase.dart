import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ride_rating_repository.dart';

class SkipRideRatingUseCase {
  final RideRatingRepository repository;

  SkipRideRatingUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String rideId,
  }) {
    return repository.skipRideRating(rideId: rideId);
  }
}
