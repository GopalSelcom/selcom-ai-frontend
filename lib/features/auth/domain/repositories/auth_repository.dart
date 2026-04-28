import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/requests/save_user_additional_details_request.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../../../core/data/models/user_model.dart';

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

  Future<Either<Failure, UserModel>> saveUserAdditionalDetails({
    required SaveUserAdditionalDetailsRequest request,
  });

  Future<Either<Failure, String>> refreshToken();

  Future<Either<Failure, bool>> logout();
}
