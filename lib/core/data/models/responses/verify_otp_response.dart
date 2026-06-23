import '../user_model.dart';

class VerifyOtpResponseModel {
  int? statusCode;
  String? message;
  VerifyOtpData? data;

  VerifyOtpResponseModel({this.statusCode, this.message, this.data});

  VerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['status_code'];
    message = json['message'];
    final payload = json['data'] ?? json['response'];
    data = payload is Map<String, dynamic>
        ? VerifyOtpData.fromJson(payload)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status_code'] = statusCode;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }

  bool get isSuccess => statusCode == 200;
  VerifyOtpData? get response => data;
}

class VerifyOtpData {
  UserModel? user;
  String? accessToken;
  String? refreshToken;
  bool? isUserAlreadyRegistered;
  bool? isUserAddressAdded;
  /// `true` when wallet is not created; `false` when wallet exists.
  bool? walletStatusFlag;
  String? walletStatus;
  String? name;
  String? email;
  bool? needsPhone;
  bool? isNewUser;

  VerifyOtpData({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isUserAlreadyRegistered,
    this.isUserAddressAdded,
    this.walletStatusFlag,
    this.walletStatus,
    this.name,
    this.email,
    this.needsPhone,
    this.isNewUser,
  });

  VerifyOtpData.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? UserModel.fromJson(json['user']) : null;
    accessToken =
        (json['access_token'] ??
                json['authorization_token'] ??
                json['accessToken'])
            ?.toString();
    refreshToken =
        (json['refresh_token'] ??
                json['refreshToken'] ??
                json['newRefreshToken'])
            ?.toString();
    isNewUser = json['is_new_user'] as bool?;
    isUserAlreadyRegistered =
        json['is_user_already_registered'] as bool? ??
        (isNewUser != null ? !isNewUser! : null);
    isUserAddressAdded = json['is_user_address_added'];
    walletStatusFlag = json['wallet_status_flag'];
    walletStatus = json['wallet_status']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    needsPhone = json['needs_phone'] as bool?;
  }

  /// Wallet is missing when API sets [walletStatusFlag] to `true`.
  bool get isWalletNotCreated => walletStatusFlag == true;

  String get signUpName =>
      (name?.trim().isNotEmpty == true ? name!.trim() : null) ??
      user?.name?.trim() ??
      '';

  String get signUpEmail =>
      (email?.trim().isNotEmpty == true ? email!.trim() : null) ??
      user?.emailId?.trim() ??
      '';

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['access_token'] = accessToken;
    data['refresh_token'] = refreshToken;
    data['is_user_already_registered'] = isUserAlreadyRegistered;
    data['is_user_address_added'] = isUserAddressAdded;
    data['wallet_status_flag'] = walletStatusFlag;
    data['wallet_status'] = walletStatus;
    data['name'] = name;
    data['email'] = email;
    data['needs_phone'] = needsPhone;
    data['is_new_user'] = isNewUser;
    return data;
  }
}
