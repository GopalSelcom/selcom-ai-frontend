class SendOtpRequest {
  final String mobileNumber;
  final String countryCode;

  const SendOtpRequest({required this.mobileNumber, required this.countryCode});

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) {
    return SendOtpRequest(
      mobileNumber: json['mobile_number'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'mobile_number': mobileNumber,
    'country_code': countryCode,
  };
}
