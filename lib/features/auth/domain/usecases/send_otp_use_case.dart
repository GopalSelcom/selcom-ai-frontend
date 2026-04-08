import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SendOtpUseCase implements UseCase<bool, SendOtpParams> {
  final AuthRepository repository;

  SendOtpUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(SendOtpParams params) async {
    return await repository.sendOtp(
      mobileNumber: params.mobileNumber,
      countryCode: params.countryCode,
      email: params.email,
    );
  }
}

class SendOtpParams {
  final String mobileNumber;
  final String countryCode;
  final String? email;

  SendOtpParams({
    required this.mobileNumber,
    required this.countryCode,
    this.email,
  });
}
