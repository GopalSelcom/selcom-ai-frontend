import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ride_rating_ride_entity.dart';
import '../repositories/ride_rating_repository.dart';

class GetLastCompletedRideUseCase {
  final RideRatingRepository repository;

  GetLastCompletedRideUseCase(this.repository);

  Future<Either<Failure, RideRatingRideEntity?>> call() {
    return repository.getLastCompletedRide();
  }
}
