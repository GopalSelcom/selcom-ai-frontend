import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/pending_review_response.dart';
import '../repositories/ride_rating_repository.dart';

class GetLastCompletedRideUseCase {
  final RideRatingRepository repository;

  GetLastCompletedRideUseCase(this.repository);

  Future<Either<Failure, PendingReview?>> call() {
    return repository.getLastCompletedRide();
  }
}
