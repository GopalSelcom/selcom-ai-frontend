import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, bool>> sendOtp({
    required String mobileNumber,
    required String countryCode,
    String? email,
  });

  Future<Either<Failure, bool>> resendOtp({
    required String mobileNumber,
    required String countryCode,
  });

  Future<Either<Failure, AuthEntity>> verifyOtp({
    required String mobileNumber,
    required String countryCode,
    required String otp,
  });

  Future<Either<Failure, String>> refreshToken();

  Future<Either<Failure, bool>> saveUserAdditionalDetails({
    required String name,
    required String email,
    required String dob,
    required String gender,
  });

  Future<Either<Failure, bool>> logout();
}
