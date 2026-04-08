import 'package:dartz/dartz.dart';
import '../../errors/failures.dart';
import '../entities/user_entity.dart';
import '../../data/models/requests/auth_requests.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> sendOtp(SendOtpRequest request);
  Future<Either<Failure, UserEntity>> verifyOtp(VerifyOtpRequest request);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, String>> refreshToken();
}
