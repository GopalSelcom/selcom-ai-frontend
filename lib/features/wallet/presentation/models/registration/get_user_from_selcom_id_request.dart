// To parse this JSON data, do
//
//     final getUserFromSelcomIdRequest = getUserFromSelcomIdRequestFromJson(jsonString);

import 'dart:convert';

GetUserFromSelcomIdRequest getUserFromSelcomIdRequestFromJson(String str) =>
    GetUserFromSelcomIdRequest.fromJson(json.decode(str));

String getUserFromSelcomIdRequestToJson(GetUserFromSelcomIdRequest data) =>
    json.encode(data.toJson());

class GetUserFromSelcomIdRequest {
  String mobileNumber;

  GetUserFromSelcomIdRequest({required this.mobileNumber});

  GetUserFromSelcomIdRequest copyWith({String? mobileNumber}) =>
      GetUserFromSelcomIdRequest(
        mobileNumber: mobileNumber ?? this.mobileNumber,
      );

  factory GetUserFromSelcomIdRequest.fromJson(Map<String, dynamic> json) =>
      GetUserFromSelcomIdRequest(mobileNumber: json["mobile_number"]);

  Map<String, dynamic> toJson() => {"mobile_number": mobileNumber};
}
