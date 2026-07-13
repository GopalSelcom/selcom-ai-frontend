import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../wallet/data/models/go_card_balance_response.dart';
import '../../domain/repositories/profile_repository.dart';
import '../cache/user_profile_cache.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/contact_us_models.dart';
import '../models/request/update_profile_request.dart';
import '../models/update_profile_response.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  /// Coalesces parallel [getProfile] callers (e.g. Home + Profile on cold start).
  Future<Either<Failure, UserModel>>? _profileLoadInFlight;

  @override
  void invalidateProfileCache() {
    UserProfileCache.clear();
    _profileLoadInFlight = null;
  }

  @override
  Future<Either<Failure, UserModel>> getProfile({
    bool forceRefresh = false,
  }) async {
    // Session cache: one network fetch per login unless [forceRefresh].
    if (!forceRefresh &&
        UserProfileCache.isLoaded &&
        UserProfileCache.user != null) {
      return Right(UserProfileCache.user!);
    }

    if (!forceRefresh && _profileLoadInFlight != null) {
      return _profileLoadInFlight!;
    }

    final future = _fetchProfileFromNetwork();
    _profileLoadInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_profileLoadInFlight, future)) {
        _profileLoadInFlight = null;
      }
    }
  }

  Future<Either<Failure, UserModel>> _fetchProfileFromNetwork() async {
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
  Future<Either<Failure, UserProfileUpdateResponse>> updateProfile(
    UserProfileUpdateRequest profileRequest,
  ) async {
    try {
      final result = await remoteDataSource.updateProfile(profileRequest);
      // edit_profile returns the updated user — refresh cache; no follow-up GET.
      final updatedUser = result.data?.toUserModel(
        preserveUserId: UserProfileCache.user?.id,
      );
      if (updatedUser != null) {
        UserProfileCache.save(updatedUser);
        UserProfileCache.markChanged();
      }
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
  Future<Either<Failure, GoCardBalanceResponseModel>> getWalletBalance() async {
    try {
      final result = await remoteDataSource.getWalletBalance();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentMethodModel>>> getPaymentMethods() async {
    try {
      final result = await remoteDataSource.getPaymentMethods();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EmailSubjectResponseModel>> getEmailSubjects() async {
    try {
      final result = await remoteDataSource.getEmailSubjects();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SendEmailResponseModel>> sendEmail(
    SendEmailRequestModel request,
  ) async {
    try {
      final result = await remoteDataSource.sendEmail(request);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }
}
