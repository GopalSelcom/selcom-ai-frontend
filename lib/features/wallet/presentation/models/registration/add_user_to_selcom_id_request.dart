// To parse this JSON data, do
//
//     final addUserToSelcomIdRequest = addUserToSelcomIdRequestFromJson(jsonString);

import 'dart:convert';

AddUserToSelcomIdRequest addUserToSelcomIdRequestFromJson(String str) =>
    AddUserToSelcomIdRequest.fromJson(json.decode(str));

String addUserToSelcomIdRequestToJson(AddUserToSelcomIdRequest data) =>
    json.encode(data.toJson());

class AddUserToSelcomIdRequest {
  String mobileNumber;
  String nidaNumber;
  String firstName;
  String lastName;
  String middleName;
  String gender;
  DateTime dateOfBirth;
  String placeOfBirth;
  String residentRegion;
  String residentDistrict;
  String residentWard;
  String residentVillage;
  String residentStreet;
  String residentPostcode;
  String nationality;
  String profilePicture;

  AddUserToSelcomIdRequest({
    required this.mobileNumber,
    required this.nidaNumber,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.gender,
    required this.dateOfBirth,
    required this.placeOfBirth,
    required this.residentRegion,
    required this.residentDistrict,
    required this.residentWard,
    required this.residentVillage,
    required this.residentStreet,
    required this.residentPostcode,
    required this.nationality,
    required this.profilePicture,
  });

  AddUserToSelcomIdRequest copyWith({
    String? mobileNumber,
    String? nidaNumber,
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
    String? profilePicture,
  }) => AddUserToSelcomIdRequest(
    mobileNumber: mobileNumber ?? this.mobileNumber,
    nidaNumber: nidaNumber ?? this.nidaNumber,
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
    profilePicture: profilePicture ?? this.profilePicture,
  );

  factory AddUserToSelcomIdRequest.fromJson(Map<String, dynamic> json) =>
      AddUserToSelcomIdRequest(
        mobileNumber: json["mobile_number"],
        nidaNumber: json["nida_number"],
        firstName: json["first_name"],
        lastName: json["last_name"],
        middleName: json["middle_name"],
        gender: json["gender"],
        dateOfBirth: DateTime.parse(json["date_of_birth"]),
        placeOfBirth: json["place_of_birth"],
        residentRegion: json["resident_region"],
        residentDistrict: json["resident_district"],
        residentWard: json["resident_ward"],
        residentVillage: json["resident_village"],
        residentStreet: json["resident_street"],
        residentPostcode: json["resident_postcode"],
        nationality: json["nationality"],
        profilePicture: json["profile_picture"],
      );

  Map<String, dynamic> toJson() => {
    "mobile_number": mobileNumber,
    "nida_number": nidaNumber,
    "first_name": firstName,
    "last_name": lastName,
    "middle_name": middleName,
    "gender": gender,
    "date_of_birth":
        "${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}",
    "place_of_birth": placeOfBirth,
    "resident_region": residentRegion,
    "resident_district": residentDistrict,
    "resident_ward": residentWard,
    "resident_village": residentVillage,
    "resident_street": residentStreet,
    "resident_postcode": residentPostcode,
    "nationality": nationality,
    "profile_picture": profilePicture,
  };
}
