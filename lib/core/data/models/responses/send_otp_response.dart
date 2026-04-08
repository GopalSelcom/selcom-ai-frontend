class SendOtpResponseModel {
  final int? statusCode;
  final String? message;
  final SendOtpData? response;

  SendOtpResponseModel({this.statusCode, this.message, this.response});

  factory SendOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return SendOtpResponseModel(
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      response: json['response'] != null
          ? SendOtpData.fromJson(json['response'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'message': message,
      'response': response?.toJson(),
    };
  }

  bool get isSuccess => statusCode == 200;
}

class SendOtpData {
  final String? otp;

  SendOtpData({this.otp});

  factory SendOtpData.fromJson(Map<String, dynamic> json) {
    return SendOtpData(otp: json['otp']?.toString());
  }

  Map<String, dynamic> toJson() {
    return {'otp': otp};
  }
}
