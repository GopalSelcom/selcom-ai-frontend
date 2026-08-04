import 'dart:convert';

/// Envelope for `GET go/get_email_subject`.
/// Note: subjects are under `response` (not `data`).
class EmailSubjectResponseModel {
  final int? statusCode;
  final String? message;
  final List<String>? subjects;
  final String? supportNumber;
  final String? supportEmail;
  final String? whatsAppText;
  final String? emailText;

  const EmailSubjectResponseModel({
    this.statusCode,
    this.message,
    this.subjects,
    this.supportNumber,
    this.supportEmail,
    this.whatsAppText,
    this.emailText,
  });

  factory EmailSubjectResponseModel.fromRawJson(String str) =>
      EmailSubjectResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory EmailSubjectResponseModel.fromJson(Map<String, dynamic> json) {
    final raw = json['response'];
    final list = <String>[];
    if (raw is List) {
      for (final item in raw) {
        final s = item?.toString().trim();
        if (s != null && s.isNotEmpty) list.add(s);
      }
    }

    return EmailSubjectResponseModel(
      statusCode: json['status_code'] is num
          ? (json['status_code'] as num).toInt()
          : int.tryParse('${json['status_code'] ?? ''}'),
      message: json['message']?.toString(),
      subjects: list,
      supportNumber: json['support_number']?.toString(),
      supportEmail: json['support_email']?.toString(),
      whatsAppText: json['whats_app_text']?.toString(),
      emailText: json['email_text']?.toString(),
    );
  }

  bool get isSuccess => statusCode == 200;

  List<String> get subjectList => subjects ?? const [];

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
    'response': subjects,
    'support_number': supportNumber,
    'support_email': supportEmail,
    'whats_app_text': whatsAppText,
    'email_text': emailText,
  };
}
