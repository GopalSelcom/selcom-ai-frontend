import 'dart:io';

class PassportDataModel {
  final String fullName;
  final String surname;
  final String givenNames;
  final String passportNumber;
  final String issuingCountry;
  final String nationality;
  final String placeOfBirth;
  final String dateOfBirth; // formatted YYYY-MM-DD
  final String expiryDate; // formatted YYYY-MM-DD
  final String gender;
  final String personalNumber;
  final String mrzLine1;
  final String mrzLine2;
  final File? faceImage;

  PassportDataModel({
    required this.fullName,
    required this.surname,
    required this.givenNames,
    required this.passportNumber,
    required this.issuingCountry,
    required this.nationality,
    required this.placeOfBirth,
    required this.dateOfBirth,
    required this.expiryDate,
    required this.gender,
    required this.personalNumber,
    required this.mrzLine1,
    required this.mrzLine2,
    this.faceImage,
  });

  PassportDataModel copyWith({
    String? fullName,
    String? surname,
    String? givenNames,
    String? passportNumber,
    String? issuingCountry,
    String? nationality,
    String? placeOfBirth,
    String? dateOfBirth,
    String? expiryDate,
    String? gender,
    String? personalNumber,
    String? mrzLine1,
    String? mrzLine2,
    File? faceImage,
  }) {
    return PassportDataModel(
      fullName: fullName ?? this.fullName,
      surname: surname ?? this.surname,
      givenNames: givenNames ?? this.givenNames,
      passportNumber: passportNumber ?? this.passportNumber,
      issuingCountry: issuingCountry ?? this.issuingCountry,
      nationality: nationality ?? this.nationality,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      expiryDate: expiryDate ?? this.expiryDate,
      gender: gender ?? this.gender,
      personalNumber: personalNumber ?? this.personalNumber,
      mrzLine1: mrzLine1 ?? this.mrzLine1,
      mrzLine2: mrzLine2 ?? this.mrzLine2,
      faceImage: faceImage ?? this.faceImage,
    );
  }
}
