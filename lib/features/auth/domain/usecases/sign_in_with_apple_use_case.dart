import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/social_auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithAppleUseCase implements UseCase<SocialAuthUser, NoParams> {
  SignInWithAppleUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, SocialAuthUser>> call(NoParams params) {
    return repository.signInWithApple();
  }
}
