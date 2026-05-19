// JSON models for `/v4/go/auth/pin/*` responses.

/// `GET pin/status` data: whether user has login PIN and biometric flag.
class LoginPinStatusModel {
  final bool pinSet;
  final bool biometricEnabled;
  final DateTime? lockedUntil;

  const LoginPinStatusModel({
    required this.pinSet,
    required this.biometricEnabled,
    this.lockedUntil,
  });

  factory LoginPinStatusModel.fromJson(Map<String, dynamic> json) {
    DateTime? locked;
    final rawLocked = json['locked_until'];
    if (rawLocked != null && rawLocked.toString().isNotEmpty) {
      locked = DateTime.tryParse(rawLocked.toString());
    }
    return LoginPinStatusModel(
      pinSet: json['pin_set'] == true,
      biometricEnabled: json['biometric_enabled'] == true,
      lockedUntil: locked,
    );
  }
}

/// `POST pin/verify` tokens + optional user payload (persisted in repository).
class LoginPinVerifyResultModel {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic>? userJson;

  const LoginPinVerifyResultModel({
    required this.accessToken,
    required this.refreshToken,
    this.userJson,
  });

  factory LoginPinVerifyResultModel.fromJson(Map<String, dynamic> json) {
    return LoginPinVerifyResultModel(
      accessToken:
          (json['accessToken'] ??
                  json['access_token'] ??
                  json['authorization_token'] ??
                  '')
              .toString(),
      refreshToken:
          (json['newRefreshToken'] ??
                  json['refresh_token'] ??
                  json['refreshToken'] ??
                  '')
              .toString(),
      userJson: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : json['user'] is Map
          ? Map<String, dynamic>.from(json['user'] as Map)
          : null,
    );
  }
}
