import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../../../../core/data/models/responses/get_saved_places_response.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../../core/data/models/requests/create_saved_place_request.dart';
import '../../../../core/data/models/requests/save_recent_as_favorite_request.dart';
import '../models/contact_us_models.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserModel>> getProfile() async {
    try {
      final result = await remoteDataSource.getProfile();
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateProfile(Map<String, dynamic> data) async {
    try {
      final result = await remoteDataSource.updateProfile(data);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserModel>> saveUserAdditionalDetails({
    required String name,
    required String emailId,
    String? imagePath,
  }) async {
    try {
      final result = await remoteDataSource.saveUserAdditionalDetails(
        name: name,
        emailId: emailId,
        imagePath: imagePath,
      );
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
  Future<Either<Failure, bool>> addSavedPlace(
    CreateSavedPlaceRequest request,
  ) async {
    try {
      final result = await remoteDataSource.addSavedPlace(request);
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
  Future<Either<Failure, WalletBalanceModel>> getWalletBalance() async {
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

  @override
  Future<Either<Failure, GetSavedPlacesResponseModel?>>
  getFavoritePlaces() async {
    try {
      final res = await remoteDataSource.getFavoritePlaces();
      return Right(res);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleFavorite(
    String id,
    bool isFavorite,
  ) async {
    try {
      final result = await remoteDataSource.toggleFavorite(id, isFavorite);
      return Right(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return Left(ServerFailure(e.toString()));
    }
  }
}
