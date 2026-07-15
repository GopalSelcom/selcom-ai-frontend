import '../user_model.dart';

/// Envelope for `POST go/auth/firebase_login`.
class FirebaseLoginResponseModel {
  final int? statusCode;
  final String? message;
  final FirebaseLoginData? data;

  FirebaseLoginResponseModel({this.statusCode, this.message, this.data});

  factory FirebaseLoginResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'];
    return FirebaseLoginResponseModel(
      statusCode: (json['status_code'] as num?)?.toInt(),
      message: json['message']?.toString(),
      data: payload is Map<String, dynamic>
          ? FirebaseLoginData.fromJson(payload)
          : payload is Map
          ? FirebaseLoginData.fromJson(Map<String, dynamic>.from(payload))
          : null,
    );
  }

  bool get isSuccess => statusCode == 200;
}

/// `data` for `POST go/auth/firebase_login`.
class FirebaseLoginData {
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final bool? isNewUser;
  final bool? walletStatusFlag;
  final String? walletStatus;
  final String? name;
  final String? email;
  final bool? needsPhone;
  final bool? needsName;

  const FirebaseLoginData({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isNewUser,
    this.walletStatusFlag,
    this.walletStatus,
    this.name,
    this.email,
    this.needsPhone,
    this.needsName,
  });

  factory FirebaseLoginData.fromJson(Map<String, dynamic> json) {
    return FirebaseLoginData(
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      accessToken: json['accessToken']?.toString(),
      refreshToken: json['newRefreshToken']?.toString(),
      isNewUser: json['is_new_user'] as bool?,
      walletStatusFlag: json['wallet_status_flag'] as bool?,
      walletStatus: json['wallet_status']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      needsPhone: json['needs_phone'] as bool?,
      needsName: json['needs_name'] as bool?,
    );
  }

  bool? get isUserAlreadyRegistered => isNewUser == null ? null : !isNewUser!;

  bool get isWalletNotCreated => walletStatusFlag == true;

  String get signUpName =>
      (name?.trim().isNotEmpty == true ? name!.trim() : null) ??
      user?.name?.trim() ??
      '';

  String get signUpEmail =>
      (email?.trim().isNotEmpty == true ? email!.trim() : null) ??
      user?.emailId?.trim() ??
      '';
}
