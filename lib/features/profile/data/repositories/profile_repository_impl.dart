import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../core/data/models/user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserModel>> getProfile() async {
    try {
      final result = await remoteDataSource.getProfile();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> updateProfile(Map<String, dynamic> data) async {
    try {
      final result = await remoteDataSource.updateProfile(data);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SavedPlaceModel>>> getSavedPlaces() async {
    try {
      final result = await remoteDataSource.getSavedPlaces();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> addSavedPlace(SavedPlaceModel place) async {
    try {
      final result = await remoteDataSource.addSavedPlace(place);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteSavedPlace(String id) async {
    try {
      final result = await remoteDataSource.deleteSavedPlace(id);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WalletBalanceModel>> getWalletBalance() async {
    try {
      final result = await remoteDataSource.getWalletBalance();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PaymentMethodModel>>> getPaymentMethods() async {
    try {
      final result = await remoteDataSource.getPaymentMethods();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
