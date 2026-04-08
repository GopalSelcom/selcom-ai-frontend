import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/data/models/requests/verify_otp_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase
    implements UseCase<VerifyOtpResponseModel?, VerifyOtpRequest> {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, VerifyOtpResponseModel?>> call(
    VerifyOtpRequest params,
  ) async {
    return await repository.verifyOtp(request: params);
  }
}
