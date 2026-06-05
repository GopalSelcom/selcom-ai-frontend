// To parse this JSON data, do
//
//     final selcomIdUserDataExistRequest = selcomIdUserDataExistRequestFromJson(jsonString);

import 'dart:convert';

SelcomIdUserDataExistRequest selcomIdUserDataExistRequestFromJson(String str) =>
    SelcomIdUserDataExistRequest.fromJson(json.decode(str));

String selcomIdUserDataExistRequestToJson(SelcomIdUserDataExistRequest data) =>
    json.encode(data.toJson());

class SelcomIdUserDataExistRequest {
  String mobileNumber;

  SelcomIdUserDataExistRequest({required this.mobileNumber});

  SelcomIdUserDataExistRequest copyWith({String? mobileNumber}) =>
      SelcomIdUserDataExistRequest(
        mobileNumber: mobileNumber ?? this.mobileNumber,
      );

  factory SelcomIdUserDataExistRequest.fromJson(Map<String, dynamic> json) =>
      SelcomIdUserDataExistRequest(mobileNumber: json["mobile_number"]);

  Map<String, dynamic> toJson() => {"mobile_number": mobileNumber};
}
