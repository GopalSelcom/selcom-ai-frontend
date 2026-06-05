// To parse this JSON data, do
//
//     final fingerScanModel = fingerScanModelFromJson(jsonString);

import 'dart:convert';

FingerScanModel fingerScanModelFromJson(String str) =>
    FingerScanModel.fromJson(json.decode(str));

String fingerScanModelToJson(FingerScanModel data) =>
    json.encode(data.toJson());

class FingerScanModel {
  int? statusCode;
  String? message;
  List<Datum>? data;

  FingerScanModel({this.statusCode, this.message, this.data});

  FingerScanModel copyWith({
    int? statusCode,
    String? message,
    List<Datum>? data,
  }) => FingerScanModel(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    data: data ?? this.data,
  );

  factory FingerScanModel.fromJson(Map<String, dynamic> json) =>
      FingerScanModel(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  UserData? userData;
  String? profilePicture;
  List<DocumentDetail>? documentDetails;

  Datum({this.userData, this.profilePicture, this.documentDetails});

  Datum copyWith({
    UserData? userData,
    String? profilePicture,
    List<DocumentDetail>? documentDetails,
  }) => Datum(
    userData: userData ?? this.userData,
    profilePicture: profilePicture ?? this.profilePicture,
    documentDetails: documentDetails ?? this.documentDetails,
  );

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    userData: json["user_data"] == null
        ? null
        : UserData.fromJson(json["user_data"]),
    profilePicture: json["profile_picture"],
    documentDetails: json["document_details"] == null
        ? []
        : List<DocumentDetail>.from(
            json["document_details"]!.map((x) => DocumentDetail.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "user_data": userData?.toJson(),
    "profile_picture": profilePicture,
    "document_details": documentDetails == null
        ? []
        : List<dynamic>.from(documentDetails!.map((x) => x.toJson())),
  };
}

class DocumentDetail {
  String? key;
  String? value;

  DocumentDetail({this.key, this.value});

  DocumentDetail copyWith({String? key, String? value}) =>
      DocumentDetail(key: key ?? this.key, value: value ?? this.value);

  factory DocumentDetail.fromJson(Map<String, dynamic> json) =>
      DocumentDetail(key: json["key"], value: json["value"]);

  Map<String, dynamic> toJson() => {"key": key, "value": value};
}

class UserData {
  String? firstName;
  String? lastName;
  String? middleName;
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

  UserData({
    this.firstName,
    this.lastName,
    this.middleName,
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
  });

  UserData copyWith({
    String? firstName,
    String? lastName,
    String? middleName,
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
  }) => UserData(
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    middleName: middleName ?? this.middleName,
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
  );

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    firstName: json["first_name"],
    lastName: json["last_name"],
    middleName: json["middle_name"],
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
  );

  Map<String, dynamic> toJson() => {
    "first_name": firstName,
    "last_name": lastName,
    "middle_name": middleName,
    "gender": gender,
    "date_of_birth":
        "${dateOfBirth!.year.toString().padLeft(4, '0')}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}",
    "place_of_birth": placeOfBirth,
    "resident_region": residentRegion,
    "resident_district": residentDistrict,
    "resident_ward": residentWard,
    "resident_village": residentVillage,
    "resident_street": residentStreet,
    "resident_postcode": residentPostcode,
    "nationality": nationality,
  };
}
