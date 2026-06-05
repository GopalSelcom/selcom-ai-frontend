// To parse this JSON data, do
//
//     final createSupportTicketSelcomIdResponse = createSupportTicketSelcomIdResponseFromJson(jsonString);

import 'dart:convert';

CreateSupportTicketSelcomIdResponse createSupportTicketSelcomIdResponseFromJson(
  String str,
) => CreateSupportTicketSelcomIdResponse.fromJson(json.decode(str));

String createSupportTicketSelcomIdResponseToJson(
  CreateSupportTicketSelcomIdResponse data,
) => json.encode(data.toJson());

class CreateSupportTicketSelcomIdResponse {
  int? statusCode;
  String? message;
  CreateSupportTicketSelcomIdResponse? response;

  CreateSupportTicketSelcomIdResponse({
    this.statusCode,
    this.message,
    this.response,
  });

  CreateSupportTicketSelcomIdResponse copyWith({
    int? statusCode,
    String? message,
    CreateSupportTicketSelcomIdResponse? response,
  }) => CreateSupportTicketSelcomIdResponse(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
  );

  factory CreateSupportTicketSelcomIdResponse.fromJson(
    Map<String, dynamic> json,
  ) => CreateSupportTicketSelcomIdResponse(
    statusCode: json["status_code"],
    message: json["message"],
    response: json["response"] == null
        ? null
        : CreateSupportTicketSelcomIdResponse.fromJson(json["response"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
  };
}
