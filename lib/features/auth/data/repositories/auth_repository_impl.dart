import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> sendOtp({
    required String mobileNumber,
    required String countryCode,
    String? email,
  }) async {
    try {
      final result = await remoteDataSource.sendOtp(
        mobileNumber: mobileNumber,
        countryCode: countryCode,
        email: email,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resendOtp({
    required String mobileNumber,
    required String countryCode,
  }) async {
    try {
      final result = await remoteDataSource.resendOtp(
        mobileNumber: mobileNumber,
        countryCode: countryCode,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> verifyOtp({
    required String mobileNumber,
    required String countryCode,
    required String otp,
  }) async {
    try {
      final authModel = await remoteDataSource.verifyOtp(
        mobileNumber: mobileNumber,
        countryCode: countryCode,
        otp: otp,
      );
      return Right(authModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final token = await remoteDataSource.refreshToken();
      return Right(token);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> saveUserAdditionalDetails({
    required String name,
    required String email,
    required String dob,
    required String gender,
  }) async {
    try {
      final result = await remoteDataSource.saveUserAdditionalDetails(
        name: name,
        email: email,
        dob: dob,
        gender: gender,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await remoteDataSource.logout();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
