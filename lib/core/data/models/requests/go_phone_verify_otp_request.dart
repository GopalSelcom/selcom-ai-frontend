import 'go_phone_otp_request.dart';

class GoPhoneVerifyOtpRequest {
  final String mobileNumber;
  final String countryCode;
  final String otp;

  const GoPhoneVerifyOtpRequest({
    required this.mobileNumber,
    required this.countryCode,
    required this.otp,
  });

  Map<String, dynamic> toJson() => {
    ...GoPhoneOtpRequest(
      mobileNumber: mobileNumber,
      countryCode: countryCode,
    ).toJson(),
    'otp': otp,
  };
}
