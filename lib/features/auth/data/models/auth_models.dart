import '../../../../core/data/models/user_model.dart';
import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.user,
    required super.accessToken,
    required super.refreshToken,
    required super.isNewUser,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data')
        ? json['data']
        : (json.containsKey('response') ? json['response'] : json);

    return AuthModel(
      user: UserModel.fromJson(data['user'] ?? {}),
      accessToken: (data['accessToken'] ?? '').toString(),
      refreshToken: (data['newRefreshToken'] ?? '').toString(),
      isNewUser: data['is_new_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': (user as UserModel).toJson(),
      'accessToken': accessToken,
      'newRefreshToken': refreshToken,
      'is_new_user': isNewUser,
    };
  }
}
