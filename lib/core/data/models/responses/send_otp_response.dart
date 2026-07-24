import 'dart:convert';

/// Envelope for `POST go/auth/phone/send_otp` and `resend_otp`.
///
/// API payload key is historically `response` (not `data`).
class SendOtpResponse {
  int? statusCode;
  String? message;
  SendOtpData? data;

  SendOtpResponse({this.statusCode, this.message, this.data});

  factory SendOtpResponse.fromJson(String str) =>
      SendOtpResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SendOtpResponse.fromMap(Map<String, dynamic> json) {
    final payload = json["response"] ?? json["data"];
    Map<String, dynamic>? payloadMap;
    if (payload is Map<String, dynamic>) {
      payloadMap = payload;
    } else if (payload is Map) {
      payloadMap = Map<String, dynamic>.from(payload);
    }
    return SendOtpResponse(
      statusCode: json["status_code"],
      message: json["message"],
      data: payloadMap == null ? null : SendOtpData.fromMap(payloadMap),
    );
  }

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "response": data?.toMap(),
  };
}

class SendOtpData {
  String? otp;

  SendOtpData({this.otp});

  factory SendOtpData.fromJson(String str) =>
      SendOtpData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SendOtpData.fromMap(Map<String, dynamic> json) => SendOtpData(
    otp: json["otp"]?.toString(),
  );

  Map<String, dynamic> toMap() => {
    "otp": otp,
  };
}
