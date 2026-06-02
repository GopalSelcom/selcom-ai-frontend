class VerifyOtpRequest {
  final String mobileNumber;
  final String countryCode;
  final String otp;

  const VerifyOtpRequest({
    required this.mobileNumber,
    required this.countryCode,
    required this.otp,
  });

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) {
    return VerifyOtpRequest(
      mobileNumber: json['mobile_number'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      otp: json['otp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'mobile_number': mobileNumber,
    'country_code': countryCode,
    'otp': otp,
  };
}
