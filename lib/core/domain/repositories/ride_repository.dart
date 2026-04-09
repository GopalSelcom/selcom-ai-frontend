import 'package:dartz/dartz.dart';
import '../../data/models/requests/book_ride_request.dart';
import '../../data/models/requests/fare_estimate_request.dart';
import '../../errors/failures.dart';
import '../entities/ride_entity.dart';
import '../entities/vehicle_type_entity.dart';

abstract class RideRepository {
  Future<Either<Failure, List<VehicleTypeEntity>>> getVehicleTypes();
  Future<Either<Failure, int>> getFareEstimate(FareEstimateRequest request);
  Future<Either<Failure, RideEntity>> bookRide(BookRideRequest request);
  Future<Either<Failure, RideEntity>> getRideDetail(String rideId);
  Future<Either<Failure, void>> cancelRide(String rideId, String reason);
  Future<Either<Failure, void>> rateRide(String rideId, double rating, String? feedback);
  Future<Either<Failure, List<RideEntity>>> getRideHistory();
}
