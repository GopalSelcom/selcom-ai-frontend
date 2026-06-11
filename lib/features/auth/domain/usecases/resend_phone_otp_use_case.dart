import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/go_phone_otp_request.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResendPhoneOtpUseCase
    implements UseCase<SendOtpResponseModel?, GoPhoneOtpRequest> {
  ResendPhoneOtpUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, SendOtpResponseModel?>> call(
    GoPhoneOtpRequest params,
  ) {
    return repository.resendPhoneOtp(request: params);
  }
}
