import '../../../../core/data/models/user_model.dart';

class AuthModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;

  const AuthModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
  });

  bool get isUserAlreadyRegistered => !isNewUser;

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
      'user': user.toJson(),
      'accessToken': accessToken,
      'newRefreshToken': refreshToken,
      'is_new_user': isNewUser,
    };
  }
}
