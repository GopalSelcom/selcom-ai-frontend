class EmailSubjectResponseModel {
  final int? statusCode;
  final String? message;
  final List<String>? subjects;
  final String? supportNumber;
  final String? supportEmail;
  final String? whatsAppText;
  final String? emailText;

  EmailSubjectResponseModel({
    this.statusCode,
    this.message,
    this.subjects,
    this.supportNumber,
    this.supportEmail,
    this.whatsAppText,
    this.emailText,
  });

  factory EmailSubjectResponseModel.fromJson(Map<String, dynamic> json) {
    return EmailSubjectResponseModel(
      statusCode: json['status_code'],
      message: json['message'],
      subjects: json['response'] != null
          ? List<String>.from(json['response'])
          : null,
      supportNumber: json['support_number'],
      supportEmail: json['support_email'],
      whatsAppText: json['whats_app_text'],
      emailText: json['email_text'],
    );
  }
}

class SendEmailRequestModel {
  final String subject;
  final String message;

  SendEmailRequestModel({required this.subject, required this.message});

  Map<String, dynamic> toJson() {
    return {'subject': subject, 'message': message};
  }
}

class SendEmailResponseModel {
  final int statusCode;
  final String message;

  SendEmailResponseModel({required this.statusCode, required this.message});

  factory SendEmailResponseModel.fromJson(Map<String, dynamic> json) {
    return SendEmailResponseModel(
      statusCode: json['status_code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
