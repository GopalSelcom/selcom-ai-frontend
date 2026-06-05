// To parse this JSON data, do
//
//     final addUserToSelcomIdResponseModel = addUserToSelcomIdResponseModelFromJson(jsonString);

import 'dart:convert';

AddUserToSelcomIdResponseModel addUserToSelcomIdResponseModelFromJson(
  String str,
) => AddUserToSelcomIdResponseModel.fromJson(json.decode(str));

String addUserToSelcomIdResponseModelToJson(
  AddUserToSelcomIdResponseModel data,
) => json.encode(data.toJson());

class AddUserToSelcomIdResponseModel {
  String? message;
  AddUserToSelcomIdResponseModelResponse? response;

  AddUserToSelcomIdResponseModel({this.message, this.response});

  AddUserToSelcomIdResponseModel copyWith({
    String? message,
    AddUserToSelcomIdResponseModelResponse? response,
  }) => AddUserToSelcomIdResponseModel(
    message: message ?? this.message,
    response: response ?? this.response,
  );

  factory AddUserToSelcomIdResponseModel.fromJson(Map<String, dynamic> json) =>
      AddUserToSelcomIdResponseModel(
        message: json["message"],
        response: json["response"] == null
            ? null
            : AddUserToSelcomIdResponseModelResponse.fromJson(json["response"]),
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "response": response?.toJson(),
  };
}

class AddUserToSelcomIdResponseModelResponse {
  int? statusCode;
  String? message;
  ResponseResponse? response;

  AddUserToSelcomIdResponseModelResponse({
    this.statusCode,
    this.message,
    this.response,
  });

  AddUserToSelcomIdResponseModelResponse copyWith({
    int? statusCode,
    String? message,
    ResponseResponse? response,
  }) => AddUserToSelcomIdResponseModelResponse(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
  );

  factory AddUserToSelcomIdResponseModelResponse.fromJson(
    Map<String, dynamic> json,
  ) => AddUserToSelcomIdResponseModelResponse(
    statusCode: json["status_code"],
    message: json["message"],
    response: json["response"] == null
        ? null
        : ResponseResponse.fromJson(json["response"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
  };
}

class ResponseResponse {
  RegistrationSteps? registrationSteps;
  String? id;
  String? firstName;
  String? lastName;
  String? middleName;
  String? nidaNumber;
  int? mobileNumber;
  int? pinLength;
  String? latitude;
  String? longitude;
  String? countryCode;
  int? isVerify;
  int? isBlocked;
  bool? isDeleted;
  bool? isBiometricEnabled;
  int? registrationStepDone;
  String? gender;
  DateTime? dateOfBirth;
  String? placeOfBirth;
  String? residentRegion;
  String? residentDistrict;
  String? residentWard;
  String? residentVillage;
  String? residentStreet;
  String? residentPostcode;
  String? nationality;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  ResponseResponse({
    this.registrationSteps,
    this.id,
    this.firstName,
    this.lastName,
    this.middleName,
    this.nidaNumber,
    this.mobileNumber,
    this.pinLength,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.isVerify,
    this.isBlocked,
    this.isDeleted,
    this.isBiometricEnabled,
    this.registrationStepDone,
    this.gender,
    this.dateOfBirth,
    this.placeOfBirth,
    this.residentRegion,
    this.residentDistrict,
    this.residentWard,
    this.residentVillage,
    this.residentStreet,
    this.residentPostcode,
    this.nationality,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  ResponseResponse copyWith({
    RegistrationSteps? registrationSteps,
    String? id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? nidaNumber,
    int? mobileNumber,
    int? pinLength,
    String? latitude,
    String? longitude,
    String? countryCode,
    int? isVerify,
    int? isBlocked,
    bool? isDeleted,
    bool? isBiometricEnabled,
    int? registrationStepDone,
    String? gender,
    DateTime? dateOfBirth,
    String? placeOfBirth,
    String? residentRegion,
    String? residentDistrict,
    String? residentWard,
    String? residentVillage,
    String? residentStreet,
    String? residentPostcode,
    String? nationality,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) => ResponseResponse(
    registrationSteps: registrationSteps ?? this.registrationSteps,
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    middleName: middleName ?? this.middleName,
    nidaNumber: nidaNumber ?? this.nidaNumber,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    pinLength: pinLength ?? this.pinLength,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    countryCode: countryCode ?? this.countryCode,
    isVerify: isVerify ?? this.isVerify,
    isBlocked: isBlocked ?? this.isBlocked,
    isDeleted: isDeleted ?? this.isDeleted,
    isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    registrationStepDone: registrationStepDone ?? this.registrationStepDone,
    gender: gender ?? this.gender,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    placeOfBirth: placeOfBirth ?? this.placeOfBirth,
    residentRegion: residentRegion ?? this.residentRegion,
    residentDistrict: residentDistrict ?? this.residentDistrict,
    residentWard: residentWard ?? this.residentWard,
    residentVillage: residentVillage ?? this.residentVillage,
    residentStreet: residentStreet ?? this.residentStreet,
    residentPostcode: residentPostcode ?? this.residentPostcode,
    nationality: nationality ?? this.nationality,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    v: v ?? this.v,
  );

  factory ResponseResponse.fromJson(Map<String, dynamic> json) =>
      ResponseResponse(
        registrationSteps: json["registration_steps"] == null
            ? null
            : RegistrationSteps.fromJson(json["registration_steps"]),
        id: json["_id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        middleName: json["middle_name"],
        nidaNumber: json["nida_number"],
        mobileNumber: json["mobile_number"],
        pinLength: json["pin_length"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        countryCode: json["country_code"],
        isVerify: json["is_verify"],
        isBlocked: json["is_blocked"],
        isDeleted: json["is_deleted"],
        isBiometricEnabled: json["is_biometric_enabled"],
        registrationStepDone: json["registration_step_done"],
        gender: json["gender"],
        dateOfBirth: json["date_of_birth"] == null
            ? null
            : DateTime.parse(json["date_of_birth"]),
        placeOfBirth: json["place_of_birth"],
        residentRegion: json["resident_region"],
        residentDistrict: json["resident_district"],
        residentWard: json["resident_ward"],
        residentVillage: json["resident_village"],
        residentStreet: json["resident_street"],
        residentPostcode: json["resident_postcode"],
        nationality: json["nationality"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
    "registration_steps": registrationSteps?.toJson(),
    "_id": id,
    "first_name": firstName,
    "last_name": lastName,
    "middle_name": middleName,
    "nida_number": nidaNumber,
    "mobile_number": mobileNumber,
    "pin_length": pinLength,
    "latitude": latitude,
    "longitude": longitude,
    "country_code": countryCode,
    "is_verify": isVerify,
    "is_blocked": isBlocked,
    "is_deleted": isDeleted,
    "is_biometric_enabled": isBiometricEnabled,
    "registration_step_done": registrationStepDone,
    "gender": gender,
    "date_of_birth": dateOfBirth?.toIso8601String(),
    "place_of_birth": placeOfBirth,
    "resident_region": residentRegion,
    "resident_district": residentDistrict,
    "resident_ward": residentWard,
    "resident_village": residentVillage,
    "resident_street": residentStreet,
    "resident_postcode": residentPostcode,
    "nationality": nationality,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "__v": v,
  };
}

class RegistrationSteps {
  bool? mobileNumberEntered;
  bool? otpVerified;
  bool? nidaVerified;
  bool? selfieVerified;
  bool? pinSet;
  bool? tinVerified;
  bool? passportVerified;

  RegistrationSteps({
    this.mobileNumberEntered,
    this.otpVerified,
    this.nidaVerified,
    this.selfieVerified,
    this.pinSet,
    this.tinVerified,
    this.passportVerified,
  });

  RegistrationSteps copyWith({
    bool? mobileNumberEntered,
    bool? otpVerified,
    bool? nidaVerified,
    bool? selfieVerified,
    bool? pinSet,
    bool? tinVerified,
    bool? passportVerified,
  }) => RegistrationSteps(
    mobileNumberEntered: mobileNumberEntered ?? this.mobileNumberEntered,
    otpVerified: otpVerified ?? this.otpVerified,
    nidaVerified: nidaVerified ?? this.nidaVerified,
    selfieVerified: selfieVerified ?? this.selfieVerified,
    pinSet: pinSet ?? this.pinSet,
    tinVerified: tinVerified ?? this.tinVerified,
    passportVerified: passportVerified ?? this.passportVerified,
  );

  factory RegistrationSteps.fromJson(Map<String, dynamic> json) =>
      RegistrationSteps(
        mobileNumberEntered: json["mobile_number_entered"],
        otpVerified: json["otp_verified"],
        nidaVerified: json["nida_verified"],
        selfieVerified: json["selfie_verified"],
        pinSet: json["pin_set"],
        tinVerified: json["tin_verified"],
        passportVerified: json["passport_verified"],
      );

  Map<String, dynamic> toJson() => {
    "mobile_number_entered": mobileNumberEntered,
    "otp_verified": otpVerified,
    "nida_verified": nidaVerified,
    "selfie_verified": selfieVerified,
    "pin_set": pinSet,
    "tin_verified": tinVerified,
    "passport_verified": passportVerified,
  };
}
