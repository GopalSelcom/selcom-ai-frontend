import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/submit_ride_rating_request.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ride_rating_ride_entity.dart';
import '../../domain/entities/ride_rating_tag_entity.dart';
import '../../domain/repositories/ride_rating_repository.dart';
import '../datasources/ride_rating_remote_data_source.dart';

class RideRatingRepositoryImpl implements RideRatingRepository {
  final RideRatingRemoteDataSource remoteDataSource;

  RideRatingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RideRatingRideEntity?>> getLastCompletedRide() async {
    try {
      final ride = await remoteDataSource.getLastCompletedRide();
      return Right(ride);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RideRatingTagEntity>>> getReviewTags({
    required int rating,
  }) async {
    try {
      final tags = await remoteDataSource.getReviewTags(rating: rating);
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitRideRating(
    SubmitRideRatingRequest request,
  ) async {
    try {
      final ok = await remoteDataSource.submitRideRating(request);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> skipRideRating({required String rideId}) async {
    try {
      final ok = await remoteDataSource.skipRideRating(rideId: rideId);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
