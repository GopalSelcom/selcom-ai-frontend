import '../../../../core/domain/entities/user_entity.dart';

class AuthEntity {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;

  const AuthEntity({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
  });

  bool get isUserAlreadyRegistered => !isNewUser;
}
