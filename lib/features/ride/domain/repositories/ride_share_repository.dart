import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/share_link_entity.dart';

abstract class RideShareRepository {
  Future<Either<Failure, ShareLinkEntity>> generateShareLink(String rideId);
  Future<Either<Failure, void>> revokeShareLink(String rideId);
}
