import 'package:dartz/dartz.dart';

import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ExchangeFirebaseSessionParams {
  const ExchangeFirebaseSessionParams({
    this.name,
    this.latitude,
    this.longitude,
  });

  final String? name;
  final double? latitude;
  final double? longitude;
}

class ExchangeFirebaseSessionUseCase
    implements
        UseCase<VerifyOtpResponseModel?, ExchangeFirebaseSessionParams> {
  ExchangeFirebaseSessionUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, VerifyOtpResponseModel?>> call(
    ExchangeFirebaseSessionParams params,
  ) {
    return repository.exchangeFirebaseSession(
      name: params.name,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}
