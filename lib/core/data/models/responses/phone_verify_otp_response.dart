import '../user_model.dart';

/// Envelope for `POST go/auth/phone/verify_otp`.
class PhoneVerifyOtpResponseModel {
  final int? statusCode;
  final String? message;
  final PhoneVerifyOtpData? data;

  PhoneVerifyOtpResponseModel({this.statusCode, this.message, this.data});

  factory PhoneVerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'];
    return PhoneVerifyOtpResponseModel(
      statusCode: (json['status_code'] as num?)?.toInt(),
      message: json['message']?.toString(),
      data: payload is Map<String, dynamic>
          ? PhoneVerifyOtpData.fromJson(payload)
          : payload is Map
          ? PhoneVerifyOtpData.fromJson(Map<String, dynamic>.from(payload))
          : null,
    );
  }

  bool get isSuccess => statusCode == 200;
}

/// `data` for `POST go/auth/phone/verify_otp` (partial user, no tokens).
class PhoneVerifyOtpData {
  final UserModel? user;
  final bool? walletStatusFlag;
  final String? walletStatus;
  final String? name;
  final String? email;
  final bool? needsPhone;

  const PhoneVerifyOtpData({
    this.user,
    this.walletStatusFlag,
    this.walletStatus,
    this.name,
    this.email,
    this.needsPhone,
  });

  factory PhoneVerifyOtpData.fromJson(Map<String, dynamic> json) {
    return PhoneVerifyOtpData(
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      walletStatusFlag: json['wallet_status_flag'] as bool?,
      walletStatus: json['wallet_status']?.toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      needsPhone: json['needs_phone'] as bool?,
    );
  }

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
