import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/ride_repository.dart';
import '../datasources/ride_remote_data_source.dart';
import '../../../../core/data/models/ride_model.dart';
import '../models/ride_management_models.dart';
import '../../../../core/data/models/requests/validate_ride_payment_request.dart';
import '../../../../core/domain/entities/ride_entity.dart';

class RideRepositoryImpl implements RideRepository {
  final RideRemoteDataSource remoteDataSource;

  RideRepositoryImpl({required this.remoteDataSource});

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
      // TODO: Skip API call for now
      // Return static data for now, skipping the API call as requested
      await Future.delayed(const Duration(milliseconds: 600));

      final mockRides = [
        RideModel(
          id: '1',
          riderId: 'rider_123',
          vehicleTypeId: 'boda_id',
          status: RideStatus.rideCompleted,
          pickup: const LocationModel(
            lat: -6.7924,
            lng: 39.2083,
            address: 'Larchmont Hotel, 27 W 11th St, New your, NY 10011 Tanzania',
          ),
          destination: const LocationModel(
            lat: -6.7724,
            lng: 39.2283,
            address: 'Public School, 27 W 11th St, New your, NY 10011 Tanzania',
          ),
          stops: const [],
          fareEstimate: 100,
          finalFare: 100,
          distanceKm: 2.5,
          durationMinutes: 15,
          pinCode: '1234',
          paymentMethod: PaymentMethod.selcomPesa,
          paymentStatus: PaymentStatus.completed,
          createdAt: DateTime.parse('2026-03-05T20:08:00'),
          driverSnapshot: const DriverSnapshotModel(
            name: 'John Doe',
            phone: '+255 123 456 789',
            rating: 4.5,
          ),
          vehicleSnapshot: const VehicleSnapshotModel(
            vehicleType: 'Boda',
            vehicleMake: 'Bajaj',
            vehicleModel: 'RE',
            vehicleColor: 'White',
            plateNumber: 'T 123 ABC',
          ),
        ),
        RideModel(
          id: '2',
          riderId: 'rider_123',
          vehicleTypeId: 'boda_id',
          status: RideStatus.rideCompleted,
          pickup: const LocationModel(
            lat: -6.8234,
            lng: 39.2695,
            address: 'Ubungo Plaza, Morogoro Road, Dar es salaam Tanzania',
          ),
          destination: const LocationModel(
            lat: -6.7724,
            lng: 39.2283,
            address: 'Mlimani City Mall, Sam Nujoma Road, Dar es salaam Tanzania',
          ),
          stops: const [],
          fareEstimate: 12500,
          finalFare: 12500,
          distanceKm: 5.2,
          durationMinutes: 25,
          pinCode: '5678',
          paymentMethod: PaymentMethod.wallet,
          paymentStatus: PaymentStatus.completed,
          createdAt: DateTime.parse('2026-12-01T10:15:00'),
          driverSnapshot: const DriverSnapshotModel(
            name: 'Jane Smith',
            phone: '+255 987 654 321',
            rating: 5.0,
          ),
          vehicleSnapshot: const VehicleSnapshotModel(
            vehicleType: 'Boda',
            vehicleMake: 'TVS',
            vehicleModel: 'HLX',
            vehicleColor: 'White',
            plateNumber: 'T 456 DEF',
          ),
        ),
      ];

      return Right(mockRides);

      /*
      final result = await remoteDataSource.getRideHistory(
        page: page,
        limit: limit,
      );
      return Right(result);
      */
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
}
