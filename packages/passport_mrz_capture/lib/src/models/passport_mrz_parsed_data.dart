/// Parsed TD3 MRZ fields from OCR (no host app coupling).
class PassportMrzParsedData {
  const PassportMrzParsedData({
    required this.fullName,
    required this.surname,
    required this.givenNames,
    required this.passportNumber,
    required this.issuingCountry,
    required this.nationality,
    required this.dateOfBirth,
    required this.expiryDate,
    required this.gender,
    required this.personalNumber,
    required this.mrzLine1,
    required this.mrzLine2,
  });

  final String fullName;
  final String surname;
  final String givenNames;
  final String passportNumber;
  final String issuingCountry;
  final String nationality;
  final String dateOfBirth;
  final String expiryDate;
  final String gender;
  final String personalNumber;
  final String mrzLine1;
  final String mrzLine2;
}
