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
    data = payload is Map<String, dynamic> ? VerifyOtpData.fromJson(payload) : null;
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

  VerifyOtpData({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isUserAlreadyRegistered,
    this.isUserAddressAdded,
  });

  VerifyOtpData.fromJson(Map<String, dynamic> json) {
    user = json['user'] != null ? UserModel.fromJson(json['user']) : null;
    accessToken = (json['access_token'] ?? json['authorization_token'] ?? json['accessToken'])
        ?.toString();
    refreshToken = (json['refresh_token'] ?? json['refreshToken'])?.toString();
    isUserAlreadyRegistered = json['is_user_already_registered'];
    isUserAddressAdded = json['is_user_address_added'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['access_token'] = accessToken;
    data['refresh_token'] = refreshToken;
    data['is_user_already_registered'] = isUserAlreadyRegistered;
    data['is_user_address_added'] = isUserAddressAdded;
    return data;
  }
}
