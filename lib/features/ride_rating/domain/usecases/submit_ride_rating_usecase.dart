import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/ride_rating_repository.dart';

class SubmitRideRatingUseCase {
  final RideRatingRepository repository;

  SubmitRideRatingUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String rideId,
    required int rating,
    required String comment,
  }) {
    return repository.submitRideRating(
      rideId: rideId,
      rating: rating,
      comment: comment,
    );
  }
}
