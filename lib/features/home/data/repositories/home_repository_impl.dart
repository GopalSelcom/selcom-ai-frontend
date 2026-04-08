import 'package:dartz/dartz.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/home_models.dart';
import '../models/places_models.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getVehicleTypes() async {
    try {
      final result = await remoteDataSource.getVehicleTypes();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AutocompletePredictionModel>>> autocomplete({
    required String input,
    required String sessionToken,
  }) async {
    try {
      final result = await remoteDataSource.autocomplete(
        input: input,
        sessionToken: sessionToken,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReverseGeocodeModel>> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final result = await remoteDataSource.reverseGeocode(lat: lat, lng: lng);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FareEstimateModel>> estimateFare({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
  }) async {
    try {
      final result = await remoteDataSource.estimateFare(
        pickup: pickup,
        destination: destination,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> bookRide({
    required String vehicleTypeId,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required int fare,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    try {
      final result = await remoteDataSource.bookRide(
        vehicleTypeId: vehicleTypeId,
        pickup: pickup,
        destination: destination,
        fare: fare,
        paymentMethod: paymentMethod,
        idempotencyKey: idempotencyKey,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
