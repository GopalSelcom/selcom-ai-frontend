import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/social_auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithFacebookUseCase implements UseCase<SocialAuthUser, NoParams> {
  SignInWithFacebookUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Either<Failure, SocialAuthUser>> call(NoParams params) {
    return repository.signInWithFacebook();
  }
}
