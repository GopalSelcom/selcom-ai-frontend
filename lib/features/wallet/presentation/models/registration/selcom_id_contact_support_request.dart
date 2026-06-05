// To parse this JSON data, do
//
//     final createSupportTicketSelcomIdRequest = createSupportTicketSelcomIdRequestFromJson(jsonString);

import 'dart:convert';

CreateSupportTicketSelcomIdRequest createSupportTicketSelcomIdRequestFromJson(
  String str,
) => CreateSupportTicketSelcomIdRequest.fromJson(json.decode(str));

String createSupportTicketSelcomIdRequestToJson(
  CreateSupportTicketSelcomIdRequest data,
) => json.encode(data.toJson());

class CreateSupportTicketSelcomIdRequest {
  String title;
  String description;
  String mobileNumber;
  String selfieVerificationMatch;
  String selfieImage;

  CreateSupportTicketSelcomIdRequest({
    required this.title,
    required this.description,
    required this.mobileNumber,
    required this.selfieVerificationMatch,
    required this.selfieImage,
  });

  CreateSupportTicketSelcomIdRequest copyWith({
    String? title,
    String? description,
    String? mobileNumber,
    String? selfieVerificationMatch,
    String? selfieImage,
  }) => CreateSupportTicketSelcomIdRequest(
    title: title ?? this.title,
    description: description ?? this.description,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    selfieVerificationMatch:
        selfieVerificationMatch ?? this.selfieVerificationMatch,
    selfieImage: selfieImage ?? this.selfieImage,
  );

  factory CreateSupportTicketSelcomIdRequest.fromJson(
    Map<String, dynamic> json,
  ) => CreateSupportTicketSelcomIdRequest(
    title: json["title"],
    description: json["description"],
    mobileNumber: json["mobile_number"],
    selfieVerificationMatch: json["selfie_verification_match"],
    selfieImage: json["selfie_image"],
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "mobile_number": mobileNumber,
    "selfie_verification_match": selfieVerificationMatch,
    "selfie_image": selfieImage,
  };
}
