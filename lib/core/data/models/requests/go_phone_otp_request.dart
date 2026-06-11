class GoPhoneOtpRequest {
  final String mobileNumber;
  final String countryCode;

  const GoPhoneOtpRequest({
    required this.mobileNumber,
    required this.countryCode,
  });

  Map<String, dynamic> toJson() => {
    'mobile_number': mobileNumber,
    'country_code': _formatCountryCode(countryCode),
  };

  static String _formatCountryCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.startsWith('+') ? trimmed : '+$trimmed';
  }
}
