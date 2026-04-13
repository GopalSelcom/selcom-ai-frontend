import 'package:dartz/dartz.dart';
import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart';
import '../../../../core/data/models/vehicle_type_model.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/home_models.dart';
import '../../data/models/places_models.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<VehicleTypeModel>>> getVehicleTypes();

  Future<Either<Failure, AutocompletePredictionModel?>> autocomplete({
    required String input,
    required String sessionToken,
  });

  Future<Either<Failure, ReverseGeocodeModel>> reverseGeocode({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, FareEstimateModel>> estimateFare(FareEstimateRequest request);

  Future<Either<Failure, BookRideResponse>> bookRide(BookRideRequest request);
}
