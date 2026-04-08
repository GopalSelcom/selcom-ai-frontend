class SendOtpRequest {
  final String countryCode;
  final String mobileNumber;

  const SendOtpRequest({
    required this.countryCode,
    required this.mobileNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'country_code': countryCode,
      'mobile_number': mobileNumber,
    };
  }
}

class VerifyOtpRequest {
  final String countryCode;
  final String mobileNumber;
  final String otp;

  const VerifyOtpRequest({
    required this.countryCode,
    required this.mobileNumber,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'country_code': countryCode,
      'mobile_number': mobileNumber,
      'otp': otp,
    };
  }
}
