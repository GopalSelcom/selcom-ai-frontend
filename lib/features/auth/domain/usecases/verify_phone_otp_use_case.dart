import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/go_phone_verify_otp_request.dart';
import '../../../../core/data/models/responses/phone_verify_otp_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpUseCase
    implements
        UseCase<PhoneVerifyOtpResponseModel?, GoPhoneVerifyOtpRequest> {
  VerifyPhoneOtpUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, PhoneVerifyOtpResponseModel?>> call(
    GoPhoneVerifyOtpRequest params,
  ) {
    return repository.verifyPhoneOtp(request: params);
  }
}
