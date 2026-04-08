import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';

abstract class AuthRepository {
  Future<Either<Failure, SendOtpResponseModel?>> sendOtp({
    required SendOtpRequest request,
  });

  Future<Either<Failure, SendOtpResponseModel?>> resendOtp({
    required SendOtpRequest request,
  });

  Future<Either<Failure, VerifyOtpResponseModel?>> verifyOtp({
    required VerifyOtpRequest request,
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
