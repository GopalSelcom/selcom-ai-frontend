import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/data/models/requests/send_otp_request.dart';
import '../../../../core/data/models/responses/send_otp_response.dart';
import '../repositories/auth_repository.dart';

class ResendOtpUseCase
    implements UseCase<SendOtpResponseModel?, SendOtpRequest> {
  final AuthRepository repository;

  ResendOtpUseCase(this.repository);

  @override
  Future<Either<Failure, SendOtpResponseModel?>> call(
    SendOtpRequest params,
  ) async {
    return await repository.resendOtp(request: params);
  }
}
