import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/book_ride_request.dart';
import '../../../../core/data/models/requests/fare_estimate_request.dart';
import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/responses/rides/active_ride_response.dart';
import '../../../../core/data/models/responses/rides/book_rides_response.dart';
import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';
import '../../../../core/data/models/responses/rides/promo_available_response.dart';
import '../../../../core/data/models/responses/rides/promo_validate_response.dart';
import '../../../../core/data/models/responses/rides/vehicle_types_response.dart';
import '../../../../core/data/models/ride_model.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../ride/data/models/recent_destinations_response.dart';
import '../../data/models/geocode_response_model.dart';
import '../../data/models/places_models.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<VehicleType>>> getVehicleTypes();

  Future<Either<Failure, List<RecentDestination>>> getRecentDestinations();

  Future<Either<Failure, GetSavedPlacesResponseModel?>> getSavedPlaces();

  Future<Either<Failure, ActiveRideResponseModel?>> getActiveRide();

  Future<Either<Failure, UserModel>> getProfile();

  Future<Either<Failure, bool>> saveRecentAsFavorite(
    SaveRecentAsFavoriteRequest request,
  );

  Future<Either<Failure, bool>> deleteSavedPlace(String id);

  Future<Either<Failure, RideModel>> getRideDetails(String rideId);

  Future<Either<Failure, AutocompletePredictionModel?>> autocomplete({
    required String input,
  });

  Future<Either<Failure, ReverseGeocodeModel?>> reverseGeocode({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, GeocodeResponse>> getGeocode({
    required String address,
  });

  Future<Either<Failure, FareEstimateResponseModel>> estimateFare(
    FareEstimateRequest request,
  );

  Future<Either<Failure, BookRideResponse>> bookRide(BookRideRequest request);

  Future<Either<Failure, PromoValidateData>> validatePromo({
    required String code,
    required String vehicleTypeId,
    required int fareEstimate,
  });

  Future<Either<Failure, List<AvailablePromoItem>>> getAvailablePromos({
    String? vehicleTypeId,
    int? fareEstimate,
  });
}
