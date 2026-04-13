import 'package:dartz/dartz.dart';
import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/geocode_response_model.dart';
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
  Future<Either<Failure, AutocompletePredictionModel?>> autocomplete({
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
  Future<Either<Failure, GeocodeResponse>> getGeocode({
    required String address,
  }) async {
    try {
      final result = await remoteDataSource.getGeocode(address: address);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FareEstimateModel>> estimateFare(
    FareEstimateRequest request,
  ) async {
    try {
      final response = await remoteDataSource.estimateFare(request);
      return Right(FareEstimateModel.fromResponse(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookRideResponse>> bookRide(
    BookRideRequest request,
  ) async {
    try {
      final result = await remoteDataSource.bookRide(request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
