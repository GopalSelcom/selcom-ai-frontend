class SendOtpRequest {
  final String mobileNumber;
  final String countryCode;

  SendOtpRequest({required this.mobileNumber, required this.countryCode});

  factory SendOtpRequest.fromJson(Map<String, dynamic> json) {
    return SendOtpRequest(
      mobileNumber: json['mobile_number'] ?? '',
      countryCode: json['country_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mobile_number': mobileNumber, 'country_code': countryCode};
  }
}
