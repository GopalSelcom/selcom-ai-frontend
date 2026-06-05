// To parse this JSON data, do
//
//     final verifySelfieResponseModel = verifySelfieResponseModelFromJson(jsonString);

import 'dart:convert';

VerifySelfieResponseModel verifySelfieResponseModelFromJson(String str) =>
    VerifySelfieResponseModel.fromJson(json.decode(str));

String verifySelfieResponseModelToJson(VerifySelfieResponseModel data) =>
    json.encode(data.toJson());

class VerifySelfieResponseModel {
  int? statusCode;
  String? message;
  NidaUserDataFromSelcomId? response;
  AppData? appData;

  VerifySelfieResponseModel({
    this.statusCode,
    this.message,
    this.response,
    this.appData,
  });

  VerifySelfieResponseModel copyWith({
    int? statusCode,
    String? message,
    NidaUserDataFromSelcomId? response,
    AppData? appData,
  }) => VerifySelfieResponseModel(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
    appData: appData ?? this.appData,
  );

  factory VerifySelfieResponseModel.fromJson(Map<String, dynamic> json) =>
      VerifySelfieResponseModel(
        statusCode: json["status_code"],
        message: json["message"],
        response: json["response"] == null
            ? null
            : NidaUserDataFromSelcomId.fromJson(json["response"]),
        appData: json["app_data"] == null
            ? null
            : AppData.fromJson(json["app_data"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
    "app_data": appData?.toJson(),
  };
}

class AppData {
  String? accessToken;

  AppData({this.accessToken});

  AppData copyWith({String? accessToken}) =>
      AppData(accessToken: accessToken ?? this.accessToken);

  factory AppData.fromJson(Map<String, dynamic> json) =>
      AppData(accessToken: json["access_token"]);

  Map<String, dynamic> toJson() => {"access_token": accessToken};
}

class NidaUserDataFromSelcomId {
  RegistrationSteps? registrationSteps;
  Passport? passport;
  String? id;
  String? firstName;
  String? lastName;
  String? middleName;
  String? accessToken;
  String? securityToken;
  String? nidaNumber;
  int? mobileNumber;
  String? pin;
  int? pinLength;
  String? verificationCode;
  String? latitude;
  String? longitude;
  String? deviceToken;
  dynamic deviceType;
  String? appUuid;
  String? countryCode;
  int? isVerify;
  int? isBlocked;
  bool? isDeleted;
  bool? isBiometricEnabled;
  int? registrationStepDone;
  String? profilePicture;
  String? signature;
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
  String? selfieImage;
  bool? selfieVerifiedByAdmin;
  bool? selfieVerificationMatch;
  SelfieVerificationData? selfieVerificationData;
  String? recordFoundMessage;

  NidaUserDataFromSelcomId({
    this.registrationSteps,
    this.passport,
    this.id,
    this.firstName,
    this.lastName,
    this.middleName,
    this.accessToken,
    this.securityToken,
    this.nidaNumber,
    this.mobileNumber,
    this.pin,
    this.pinLength,
    this.verificationCode,
    this.latitude,
    this.longitude,
    this.deviceToken,
    this.deviceType,
    this.appUuid,
    this.countryCode,
    this.isVerify,
    this.isBlocked,
    this.isDeleted,
    this.isBiometricEnabled,
    this.registrationStepDone,
    this.profilePicture,
    this.signature,
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
    this.selfieImage,
    this.selfieVerifiedByAdmin,
    this.selfieVerificationMatch,
    this.recordFoundMessage,
    this.selfieVerificationData,
  });

  NidaUserDataFromSelcomId copyWith({
    RegistrationSteps? registrationSteps,
    Passport? passport,
    String? id,
    String? firstName,
    String? lastName,
    String? middleName,
    String? accessToken,
    String? securityToken,
    String? nidaNumber,
    int? mobileNumber,
    String? pin,
    int? pinLength,
    String? verificationCode,
    String? latitude,
    String? longitude,
    String? deviceToken,
    dynamic deviceType,
    String? appUuid,
    String? countryCode,
    int? isVerify,
    int? isBlocked,
    bool? isDeleted,
    bool? isBiometricEnabled,
    int? registrationStepDone,
    String? profilePicture,
    String? signature,
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
    String? selfieImage,
    bool? selfieVerifiedByAdmin,
    bool? selfieVerificationMatch,
    String? recordFoundMessage,
    SelfieVerificationData? selfieVerificationData,
  }) => NidaUserDataFromSelcomId(
    registrationSteps: registrationSteps ?? this.registrationSteps,
    passport: passport ?? this.passport,
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    middleName: middleName ?? this.middleName,
    accessToken: accessToken ?? this.accessToken,
    securityToken: securityToken ?? this.securityToken,
    nidaNumber: nidaNumber ?? this.nidaNumber,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    pin: pin ?? this.pin,
    pinLength: pinLength ?? this.pinLength,
    verificationCode: verificationCode ?? this.verificationCode,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    deviceToken: deviceToken ?? this.deviceToken,
    deviceType: deviceType ?? this.deviceType,
    appUuid: appUuid ?? this.appUuid,
    countryCode: countryCode ?? this.countryCode,
    isVerify: isVerify ?? this.isVerify,
    isBlocked: isBlocked ?? this.isBlocked,
    isDeleted: isDeleted ?? this.isDeleted,
    isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    registrationStepDone: registrationStepDone ?? this.registrationStepDone,
    profilePicture: profilePicture ?? this.profilePicture,
    signature: signature ?? this.signature,
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
    selfieImage: selfieImage ?? this.selfieImage,
    selfieVerifiedByAdmin: selfieVerifiedByAdmin ?? this.selfieVerifiedByAdmin,
    selfieVerificationMatch:
        selfieVerificationMatch ?? this.selfieVerificationMatch,
    recordFoundMessage: recordFoundMessage ?? this.recordFoundMessage,
    selfieVerificationData:
        selfieVerificationData ?? this.selfieVerificationData,
  );

  factory NidaUserDataFromSelcomId.fromJson(Map<String, dynamic> json) =>
      NidaUserDataFromSelcomId(
        registrationSteps: json["registration_steps"] == null
            ? null
            : RegistrationSteps.fromJson(json["registration_steps"]),
        passport: json["passport"] == null
            ? null
            : Passport.fromJson(json["passport"]),
        id: json["_id"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        middleName: json["middle_name"],
        accessToken: json["access_token"],
        securityToken: json["security_token"],
        nidaNumber: json["nida_number"],
        mobileNumber: json["mobile_number"],
        pin: json["pin"],
        pinLength: json["pin_length"],
        verificationCode: json["verification_code"],
        latitude: json["latitude"],
        longitude: json["longitude"],
        deviceToken: json["device_token"],
        deviceType: json["device_type"],
        appUuid: json["app_uuid"],
        countryCode: json["country_code"],
        isVerify: json["is_verify"],
        isBlocked: json["is_blocked"],
        isDeleted: json["is_deleted"],
        isBiometricEnabled: json["is_biometric_enabled"],
        registrationStepDone: json["registration_step_done"],
        profilePicture: json["profile_picture"],
        signature: json["signature"],
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
        selfieImage: json["selfie_image"],
        selfieVerifiedByAdmin: json["selfie_verified_by_admin"],
        selfieVerificationMatch: json["selfie_verification_match"],
        recordFoundMessage: json["record_found_message"],
        selfieVerificationData: json["selfie_verification_data"] == null
            ? null
            : SelfieVerificationData.fromJson(json["selfie_verification_data"]),
      );

  Map<String, dynamic> toJson() => {
    "registration_steps": registrationSteps?.toJson(),
    "passport": passport?.toJson(),
    "_id": id,
    "first_name": firstName,
    "last_name": lastName,
    "middle_name": middleName,
    "access_token": accessToken,
    "security_token": securityToken,
    "nida_number": nidaNumber,
    "mobile_number": mobileNumber,
    "pin": pin,
    "pin_length": pinLength,
    "verification_code": verificationCode,
    "latitude": latitude,
    "longitude": longitude,
    "device_token": deviceToken,
    "device_type": deviceType,
    "app_uuid": appUuid,
    "country_code": countryCode,
    "is_verify": isVerify,
    "is_blocked": isBlocked,
    "is_deleted": isDeleted,
    "is_biometric_enabled": isBiometricEnabled,
    "registration_step_done": registrationStepDone,
    "profile_picture": profilePicture,
    "signature": signature,
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
    "selfie_image": selfieImage,
    "selfie_verified_by_admin": selfieVerifiedByAdmin,
    "selfie_verification_match": selfieVerificationMatch,
    "record_found_message": recordFoundMessage,
    "selfie_verification_data": selfieVerificationData?.toJson(),
  };
}

class SelfieVerificationData {
  bool? status;
  String? message;
  num? similarity;
  int? similarityThreshold;

  SelfieVerificationData({
    this.status,
    this.message,
    this.similarity,
    this.similarityThreshold,
  });

  SelfieVerificationData copyWith({
    bool? status,
    String? message,
    num? similarity,
    int? similarityThreshold,
  }) => SelfieVerificationData(
    status: status ?? this.status,
    message: message ?? this.message,
    similarity: similarity ?? this.similarity,
    similarityThreshold: similarityThreshold ?? this.similarityThreshold,
  );

  factory SelfieVerificationData.fromJson(Map<String, dynamic> json) =>
      SelfieVerificationData(
        status: json["status"],
        message: json["message"],
        similarity: json["similarity"],
        similarityThreshold: json["similarity_threshold"],
      );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "similarity": similarity,
    "similarity_threshold": similarityThreshold,
  };
}

class Passport {
  String? number;
  String? type;
  String? firstName;
  String? lastName;
  String? gender;
  String? state;
  String? residenceAddress;
  String? nationality;
  String? dateOfBirth;
  String? placeOfBirth;
  dynamic dateOfIssue;
  String? placeOfIssue;
  String? dateOfExpiry;
  String? countryOfIssue;
  String? countryCode;
  String? photo;
  String? signature;

  Passport({
    this.number,
    this.type,
    this.firstName,
    this.lastName,
    this.gender,
    this.state,
    this.residenceAddress,
    this.nationality,
    this.dateOfBirth,
    this.placeOfBirth,
    this.dateOfIssue,
    this.placeOfIssue,
    this.dateOfExpiry,
    this.countryOfIssue,
    this.countryCode,
    this.photo,
    this.signature,
  });

  Passport copyWith({
    String? number,
    String? type,
    String? firstName,
    String? lastName,
    String? gender,
    String? state,
    String? residenceAddress,
    String? nationality,
    String? dateOfBirth,
    String? placeOfBirth,
    dynamic dateOfIssue,
    String? placeOfIssue,
    String? dateOfExpiry,
    String? countryOfIssue,
    String? countryCode,
    String? photo,
    String? signature,
  }) => Passport(
    number: number ?? this.number,
    type: type ?? this.type,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    gender: gender ?? this.gender,
    state: state ?? this.state,
    residenceAddress: residenceAddress ?? this.residenceAddress,
    nationality: nationality ?? this.nationality,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    placeOfBirth: placeOfBirth ?? this.placeOfBirth,
    dateOfIssue: dateOfIssue ?? this.dateOfIssue,
    placeOfIssue: placeOfIssue ?? this.placeOfIssue,
    dateOfExpiry: dateOfExpiry ?? this.dateOfExpiry,
    countryOfIssue: countryOfIssue ?? this.countryOfIssue,
    countryCode: countryCode ?? this.countryCode,
    photo: photo ?? this.photo,
    signature: signature ?? this.signature,
  );

  factory Passport.fromJson(Map<String, dynamic> json) => Passport(
    number: json["number"],
    type: json["type"],
    firstName: json["first_name"],
    lastName: json["last_name"],
    gender: json["gender"],
    state: json["state"],
    residenceAddress: json["residence_address"],
    nationality: json["nationality"],
    dateOfBirth: json["date_of_birth"],
    placeOfBirth: json["place_of_birth"],
    dateOfIssue: json["date_of_issue"],
    placeOfIssue: json["place_of_issue"],
    dateOfExpiry: json["date_of_expiry"],
    countryOfIssue: json["country_of_issue"],
    countryCode: json["country_code"],
    photo: json["photo"],
    signature: json["signature"],
  );

  Map<String, dynamic> toJson() => {
    "number": number,
    "type": type,
    "first_name": firstName,
    "last_name": lastName,
    "gender": gender,
    "state": state,
    "residence_address": residenceAddress,
    "nationality": nationality,
    "date_of_birth": dateOfBirth,
    "place_of_birth": placeOfBirth,
    "date_of_issue": dateOfIssue,
    "place_of_issue": placeOfIssue,
    "date_of_expiry": dateOfExpiry,
    "country_of_issue": countryOfIssue,
    "country_code": countryCode,
    "photo": photo,
    "signature": signature,
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
