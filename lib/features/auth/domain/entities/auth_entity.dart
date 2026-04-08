import '../../../../core/domain/entities/user_entity.dart';

class AuthEntity {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;
  final bool isUserAlreadyRegistered;
  final bool isUserAddressAdded;

  const AuthEntity({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.isUserAlreadyRegistered,
    required this.isUserAddressAdded,
  });
}
