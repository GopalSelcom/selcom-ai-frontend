class WalletOtherPaymentTopupResponse {
  const WalletOtherPaymentTopupResponse({
    this.statusCode,
    this.message,
    this.response,
  });

  final int? statusCode;
  final String? message;
  final Map<String, dynamic>? response;

  factory WalletOtherPaymentTopupResponse.fromJson(Map<String, dynamic> json) {
    final rawResponse = json['response'];
    return WalletOtherPaymentTopupResponse(
      statusCode: json['status_code'] as int?,
      message: json['message'] as String?,
      response: rawResponse is Map<String, dynamic> ? rawResponse : null,
    );
  }
}
