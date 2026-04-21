import 'package:dartz/dartz.dart';
import 'dart:developer' as developer;
import '../../../../core/data/models/responses/rides/active_ride_response.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_data_source.dart';
import '../../../../core/data/models/ride_model.dart';
import '../models/ride_management_models.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDataSource remoteDataSource;

  RideRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ActiveRideResponseModel?>> getActiveRide() async {
    try {
      final result = await remoteDataSource.getActiveRide();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentDestinationModel>>>
  getRecentDestinations() async {
    try {
      final result = await remoteDataSource.getRecentDestinations();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RideModel>>> getRideHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getRideHistory(
        page: page,
        limit: limit,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideModel>> getRideDetails(String rideId) async {
    try {
      final result = await remoteDataSource.getRideDetails(rideId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelRide(String rideId, String reason) async {
    try {
      final result = await remoteDataSource.cancelRide(rideId, reason);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateDestination(
    String rideId,
    Map<String, dynamic> destination,
  ) async {
    try {
      final result = await remoteDataSource.updateDestination(
        rideId,
        destination,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updatePickup(
    String rideId,
    Map<String, dynamic> pickup,
  ) async {
    try {
      final result = await remoteDataSource.updatePickup(rideId, pickup);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> increaseFare(String rideId, int newFare) async {
    try {
      final result = await remoteDataSource.increaseFare(rideId, newFare);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReceiptModel>> getReceipt(String rideId) async {
    try {
      final result = await remoteDataSource.getReceipt(rideId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> rateDriver(
    String rideId,
    int rating,
    String comment,
  ) async {
    try {
      final result = await remoteDataSource.rateDriver(rideId, rating, comment);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> submitFeedback(
    String rideId,
    String category,
    String message,
  ) async {
    try {
      final result = await remoteDataSource.submitFeedback(
        rideId,
        category,
        message,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> validateRidePayment(
    ValidateRidePaymentRequest request,
  ) async {
    try {
      final result = await remoteDataSource.validateRidePayment(request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> walletDummyPaymentRequest(
    DummyPaymentRequest request,
  ) async {
    try {
      final result = await remoteDataSource.walletDummyPaymentRequest(request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateActivityToken(
    String rideId,
    String token,
  ) async {
    try {
      final result = await remoteDataSource.updateActivityToken(rideId, token);
      return Right(result);
    } catch (e) {
      developer.log(
        "❌ Repository Error during updateActivityToken: $e",
        name: 'ORDER_TRACKING',
      );
      return Left(ServerFailure(e.toString()));
    }
  }
}
