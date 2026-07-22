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
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../profile/data/cache/user_profile_cache.dart';
import '../../../ride/data/models/ride_management_models.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
import '../models/geocode_response_model.dart';
import '../models/places_models.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  /// Session cache for `GET go/vehicles/types` — the catalog rarely changes,
  /// but Home load and every vehicle-selection estimate refresh ask for it.
  /// Static because bindings may create multiple repository instances.
  /// Empty results and failures are not cached, so the next call retries.
  static List<VehicleTypeModel>? _vehicleTypesCache;

  /// Shared in-flight fetch so parallel callers reuse one request.
  static Future<List<VehicleTypeModel>>? _vehicleTypesInFlight;

  /// Drops the cached catalog (logout / session expiry) so the next session
  /// refetches — pricing config may change between users.
  static void invalidateVehicleTypesCache() {
    _vehicleTypesCache = null;
    _vehicleTypesInFlight = null;
  }

  @override
  Future<Either<Failure, List<VehicleTypeModel>>> getVehicleTypes() async {
    final cached = _vehicleTypesCache;
    if (cached != null && cached.isNotEmpty) {
      return Right(cached);
    }
    try {
      final inFlight = _vehicleTypesInFlight ??= _fetchVehicleTypes();
      final result = await inFlight;
      if (result.isNotEmpty) {
        _vehicleTypesCache = result;
      }
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    } finally {
      _vehicleTypesInFlight = null;
    }
  }

  Future<List<VehicleTypeModel>> _fetchVehicleTypes() async {
    final response = await remoteDataSource.getVehicleTypes();
    if (!response.isSuccess) {
      return const [];
    }
    return response.vehicleTypes;
  }

  @override
  Future<Either<Failure, List<RecentDestinationModel>>> getRecentDestinations() async {
    try {
      final result = await remoteDataSource.getRecentDestinations();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GetSavedPlacesResponseModel?>> getSavedPlaces() async {
    try {
      final result = await remoteDataSource.getSavedPlaces();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ActiveRideResponseModel?>> getActiveRide() async {
    try {
      final result = await remoteDataSource.getActiveRide();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> getProfile() async {
    if (UserProfileCache.isLoaded && UserProfileCache.user != null) {
      return Right(UserProfileCache.user!);
    }
    try {
      final result = await remoteDataSource.getProfile();
      UserProfileCache.save(result);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> saveRecentAsFavorite(
    SaveRecentAsFavoriteRequest request,
  ) async {
    try {
      final result = await remoteDataSource.saveRecentAsFavorite(request);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteSavedPlace(String id) async {
    try {
      final result = await remoteDataSource.deleteSavedPlace(id);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RideModel>> getRideDetails(String rideId) async {
    try {
      final result = await remoteDataSource.getRideDetails(rideId);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AutocompletePredictionModel?>> autocomplete({
    required String input,
  }) async {
    try {
      final result = await remoteDataSource.autocomplete(input: input);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReverseGeocodeModel?>> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final result = await remoteDataSource.reverseGeocode(lat: lat, lng: lng);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
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
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FareEstimateResponseModel>> estimateFare(
    FareEstimateRequest request,
  ) async {
    try {
      final response = await remoteDataSource.estimateFare(request);
      if (!response.isSuccess) {
        final msg = (response.message ?? '').trim();
        final display = msg.isEmpty
            ? 'Unable to estimate fare for this route.'
            : msg;
        final code = response.errorCode?.trim();
        final failureMessage = (code != null && code.isNotEmpty)
            ? '$code|$display'
            : display;
        return Left(ServerFailure(failureMessage));
      }
      return Right(response);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
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
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PromoValidateData>> validatePromo({
    required String code,
    required String vehicleTypeId,
    required int fareEstimate,
  }) async {
    try {
      final r = await remoteDataSource.validatePromo(
        code: code,
        vehicleTypeId: vehicleTypeId,
        fareEstimate: fareEstimate,
      );
      if (r.isSuccess && r.data != null) {
        return Right(r.data!);
      }
      final err = r.errorCode?.trim();
      final msg = (r.message ?? '').trim();
      return Left(
        PromoValidationFailure(
          msg.isEmpty ? 'Promo code cannot be applied.' : msg,
          errorCode: (err == null || err.isEmpty) ? null : err,
        ),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AvailablePromoItem>>> getAvailablePromos({
    String? vehicleTypeId,
    int? fareEstimate,
  }) async {
    try {
      final r = await remoteDataSource.getAvailablePromos(
        vehicleTypeId: vehicleTypeId,
        fareEstimate: fareEstimate,
      );
      if (r.isSuccess && r.data != null) {
        return Right(r.data!.promos);
      }
      final msg = (r.message ?? '').trim();
      return Left(
        ServerFailure(msg.isEmpty ? 'Unable to load promo codes.' : msg),
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }
}
