import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/share_link_entity.dart';
import '../repositories/ride_share_repository.dart';

class GenerateShareLinkUseCase {
  final RideShareRepository repository;
  const GenerateShareLinkUseCase(this.repository);

  Future<Either<Failure, ShareLinkEntity>> call(String rideId) {
    return repository.generateShareLink(rideId);
  }
}
