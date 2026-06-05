// To parse this JSON data, do
//
//     final passportScanningModel = passportScanningModelFromJson(jsonString);

import 'dart:convert';

PassportScanningModel passportScanningModelFromJson(String str) =>
    PassportScanningModel.fromJson(json.decode(str));

String passportScanningModelToJson(PassportScanningModel data) =>
    json.encode(data.toJson());

class PassportScanningModel {
  String? msg;
  int? statusCode;
  Data? data;

  PassportScanningModel({this.msg, this.statusCode, this.data});

  PassportScanningModel copyWith({String? msg, int? statusCode, Data? data}) =>
      PassportScanningModel(
        msg: msg ?? this.msg,
        statusCode: statusCode ?? this.statusCode,
        data: data ?? this.data,
      );

  factory PassportScanningModel.fromJson(Map<String, dynamic> json) =>
      PassportScanningModel(
        msg: json["msg"],
        statusCode: json["status_code"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "status_code": statusCode,
    "data": data?.toJson(),
  };
}

class Data {
  String? name;
  String? surname;
  String? gender;
  String? state;
  String? nationality;
  String? dob;
  String? dateOfExpiry;
  String? documentCode;
  String? documentNumber;
  String? placeOfBirth;
  String? residenceAddress;
  String? image;
  String? signatureImage;
  String? passiveAuth;
  String? chipAuth;

  Data({
    this.name,
    this.surname,
    this.gender,
    this.state,
    this.nationality,
    this.dob,
    this.dateOfExpiry,
    this.documentCode,
    this.documentNumber,
    this.placeOfBirth,
    this.residenceAddress,
    this.image,
    this.signatureImage,
    this.passiveAuth,
    this.chipAuth,
  });

  Data copyWith({
    String? name,
    String? surname,
    String? gender,
    String? state,
    String? nationality,
    String? dob,
    String? dateOfExpiry,
    String? documentCode,
    String? documentNumber,
    String? placeOfBirth,
    String? residenceAddress,
    String? image,
    String? signatureImage,
    String? passiveAuth,
    String? chipAuth,
  }) => Data(
    name: name ?? this.name,
    surname: surname ?? this.surname,
    gender: gender ?? this.gender,
    state: state ?? this.state,
    nationality: nationality ?? this.nationality,
    dob: dob ?? this.dob,
    dateOfExpiry: dateOfExpiry ?? this.dateOfExpiry,
    documentCode: documentCode ?? this.documentCode,
    documentNumber: documentNumber ?? this.documentNumber,
    placeOfBirth: placeOfBirth ?? this.placeOfBirth,
    residenceAddress: residenceAddress ?? this.residenceAddress,
    image: image ?? this.image,
    signatureImage: signatureImage ?? this.signatureImage,
    passiveAuth: passiveAuth ?? this.passiveAuth,
    chipAuth: chipAuth ?? this.chipAuth,
  );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    name: json["name"],
    surname: json["surname"],
    gender: json["gender"],
    state: json["state"],
    nationality: json["nationality"],
    dob: json["dob"],
    dateOfExpiry: json["dateOfExpiry"],
    documentCode: json["documentCode"],
    documentNumber: json["documentNumber"],
    placeOfBirth: json["placeOfBirth"],
    residenceAddress: json["residenceAddress"],
    image: json["image"],
    signatureImage: json["signatureImage"],
    passiveAuth: json["passiveAuth"],
    chipAuth: json["chipAuth"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "surname": surname,
    "gender": gender,
    "state": state,
    "nationality": nationality,
    "dob": dob,
    "dateOfExpiry": dateOfExpiry,
    "documentCode": documentCode,
    "documentNumber": documentNumber,
    "placeOfBirth": placeOfBirth,
    "residenceAddress": residenceAddress,
    "image": image,
    "signatureImage": signatureImage,
    "passiveAuth": passiveAuth,
    "chipAuth": chipAuth,
  };
}
