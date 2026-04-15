import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SendOtpResponseModel?>> sendOtp({
    required SendOtpRequest request,
  }) async {
    try {
      final result = await remoteDataSource.sendOtp(request: request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SendOtpResponseModel?>> resendOtp({
    required SendOtpRequest request,
  }) async {
    try {
      final result = await remoteDataSource.resendOtp(request: request);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VerifyOtpResponseModel?>> verifyOtp({
    required VerifyOtpRequest request,
  }) async {
    try {
      final result = await remoteDataSource.verifyOtp(request: request);
      return Right(result);
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
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await remoteDataSource.logout();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
