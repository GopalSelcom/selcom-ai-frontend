import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/submit_ride_rating_request.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ride_rating_repository.dart';

class SubmitRideRatingUseCase {
  final RideRatingRepository repository;

  SubmitRideRatingUseCase(this.repository);

  Future<Either<Failure, bool>> call(SubmitRideRatingRequest request) {
    return repository.submitRideRating(request);
  }
}
