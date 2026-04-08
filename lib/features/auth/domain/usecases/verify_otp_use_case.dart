import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase implements UseCase<AuthEntity, VerifyOtpParams> {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthEntity>> call(VerifyOtpParams params) async {
    return await repository.verifyOtp(
      mobileNumber: params.mobileNumber,
      countryCode: params.countryCode,
      otp: params.otp,
    );
  }
}

class VerifyOtpParams {
  final String mobileNumber;
  final String countryCode;
  final String otp;

  VerifyOtpParams({
    required this.mobileNumber,
    required this.countryCode,
    required this.otp,
  });
}
