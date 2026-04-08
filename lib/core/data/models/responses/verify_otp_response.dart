import '../user_model.dart';

class VerifyOtpResponseModel {
  int? statusCode;
  String? message;
  VerifyOtpData? response;

  VerifyOtpResponseModel({this.statusCode, this.message, this.response});

  VerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['status_code'];
    message = json['message'];
    response = json['response'] != null ? VerifyOtpData.fromJson(json['response']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status_code'] = statusCode;
    data['message'] = message;
    if (response != null) {
      data['response'] = response!.toJson();
    }
    return data;
  }

  bool get isSuccess => statusCode == 200;
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
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
    isUserAlreadyRegistered = json['is_user_already_registered'];
    isUserAddressAdded = json['is_user_address_added'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (user != null) {
      data['user'] = user!.toJson();
    }
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    data['is_user_already_registered'] = isUserAlreadyRegistered;
    data['is_user_address_added'] = isUserAddressAdded;
    return data;
  }
}
