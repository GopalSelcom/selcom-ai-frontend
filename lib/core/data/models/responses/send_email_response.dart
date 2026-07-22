import 'dart:convert';

/// Envelope for `POST go/send_email`.
class SendEmailResponse {
  final int? statusCode;
  final String? message;

  const SendEmailResponse({
    this.statusCode,
    this.message,
  });

  factory SendEmailResponse.fromRawJson(String str) =>
      SendEmailResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SendEmailResponse.fromJson(Map<String, dynamic> json) =>
      SendEmailResponse(
        statusCode: json['status_code'] is num
            ? (json['status_code'] as num).toInt()
            : int.tryParse('${json['status_code'] ?? ''}'),
        message: json['message']?.toString(),
      );

  bool get isSuccess => statusCode == 200;

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
  };
}
