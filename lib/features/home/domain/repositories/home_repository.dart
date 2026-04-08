import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/home_models.dart';
import '../../data/models/places_models.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<VehicleTypeModel>>> getVehicleTypes();

  Future<Either<Failure, List<AutocompletePredictionModel>>> autocomplete({
    required String input,
    required String sessionToken,
  });

  Future<Either<Failure, ReverseGeocodeModel>> reverseGeocode({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, FareEstimateModel>> estimateFare({
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
  });

  Future<Either<Failure, Map<String, dynamic>>> bookRide({
    required String vehicleTypeId,
    required Map<String, dynamic> pickup,
    required Map<String, dynamic> destination,
    required int fare,
    required String paymentMethod,
    required String idempotencyKey,
  });
}
