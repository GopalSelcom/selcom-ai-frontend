import 'package:dartz/dartz.dart';

import '../../../../core/data/models/requests/firebase_login_request.dart';
import '../../../../core/data/models/responses/verify_otp_response.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class FirebaseLoginUseCase
    implements UseCase<VerifyOtpResponseModel?, FirebaseLoginRequest> {
  final AuthRepository repository;

  FirebaseLoginUseCase(this.repository);

  @override
  Future<Either<Failure, VerifyOtpResponseModel?>> call(
    FirebaseLoginRequest params,
  ) async {
    return repository.firebaseLogin(request: params);
  }
}
