class VerifyOtpRequest {
  final String mobileNumber;
  final String countryCode;
  final String otp;

  VerifyOtpRequest({
    required this.mobileNumber,
    required this.countryCode,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobile_number': mobileNumber,
      'country_code': countryCode,
      'otp': otp,
    };
  }
}
