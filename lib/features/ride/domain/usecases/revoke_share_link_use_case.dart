import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ride_share_repository.dart';

class RevokeShareLinkUseCase {
  final RideShareRepository repository;
  const RevokeShareLinkUseCase(this.repository);

  Future<Either<Failure, void>> call(String rideId) {
    return repository.revokeShareLink(rideId);
  }
}
