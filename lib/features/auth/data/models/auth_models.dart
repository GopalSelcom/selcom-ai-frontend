import '../../../../core/data/models/user_model.dart';
import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.user,
    required super.accessToken,
    required super.refreshToken,
    required super.isUserAlreadyRegistered,
    required super.isUserAddressAdded,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // Determine if we're looking at the top-level API response or the data object
    final data = json.containsKey('data')
        ? json['data']
        : (json.containsKey('response') ? json['response'] : json);

    return AuthModel(
      user: UserModel.fromJson(data['user'] ?? {}),
      accessToken: (data['access_token'] ?? data['authorization_token'] ?? data['accessToken'] ?? '')
          .toString(),
      refreshToken: (data['refresh_token'] ?? data['refreshToken'] ?? '').toString(),
      isUserAlreadyRegistered: data['is_user_already_registered'] ?? false,
      isUserAddressAdded: data['is_user_address_added'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': (user as UserModel).toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'is_user_already_registered': isUserAlreadyRegistered,
      'is_user_address_added': isUserAddressAdded,
    };
  }
}
