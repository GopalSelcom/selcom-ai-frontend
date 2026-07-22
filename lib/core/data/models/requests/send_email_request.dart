/// Request body for `POST go/send_email`.
class SendEmailRequest {
  final String subject;
  final String message;

  const SendEmailRequest({
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'message': message,
  };
}
