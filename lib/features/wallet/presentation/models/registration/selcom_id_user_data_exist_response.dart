// To parse this JSON data, do
//
//     final userDataExistSelcomIdModel = userDataExistSelcomIdModelFromJson(jsonString);

import 'dart:convert';

UserDataExistSelcomIdModel userDataExistSelcomIdModelFromJson(String str) =>
    UserDataExistSelcomIdModel.fromJson(json.decode(str));

String userDataExistSelcomIdModelToJson(UserDataExistSelcomIdModel data) =>
    json.encode(data.toJson());

class UserDataExistSelcomIdModel {
  String? message;
  UserDataExistSelcomIdModelResponse? response;

  UserDataExistSelcomIdModel({this.message, this.response});

  UserDataExistSelcomIdModel copyWith({
    String? message,
    UserDataExistSelcomIdModelResponse? response,
  }) => UserDataExistSelcomIdModel(
    message: message ?? this.message,
    response: response ?? this.response,
  );

  factory UserDataExistSelcomIdModel.fromJson(Map<String, dynamic> json) =>
      UserDataExistSelcomIdModel(
        message: json["message"],
        response: json["response"] == null
            ? null
            : UserDataExistSelcomIdModelResponse.fromJson(json["response"]),
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "response": response?.toJson(),
  };
}

class UserDataExistSelcomIdModelResponse {
  int? statusCode;
  String? message;
  ResponseResponse? response;
  AppData? appData;

  UserDataExistSelcomIdModelResponse({
    this.statusCode,
    this.message,
    this.response,
    this.appData,
  });

  UserDataExistSelcomIdModelResponse copyWith({
    int? statusCode,
    String? message,
    ResponseResponse? response,
    AppData? appData,
  }) => UserDataExistSelcomIdModelResponse(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
    appData: appData ?? this.appData,
  );

  factory UserDataExistSelcomIdModelResponse.fromJson(
    Map<String, dynamic> json,
  ) => UserDataExistSelcomIdModelResponse(
    statusCode: json["status_code"],
    message: json["message"],
    response: json["response"] == null
        ? null
        : ResponseResponse.fromJson(json["response"]),
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

class ResponseResponse {
  String? nidaNumber;
  bool? isTicketRaised;
  String? ticketAlreadyRaisedMessage;
  String? recordFoundMessage;
  bool? nidaVerified;
  bool? passportVerified;

  ResponseResponse({
    this.nidaNumber,
    this.isTicketRaised,
    this.ticketAlreadyRaisedMessage,
    this.nidaVerified,
    this.recordFoundMessage,
    this.passportVerified,
  });

  ResponseResponse copyWith({
    String? nidaNumber,
    bool? isTicketRaised,
    String? ticketAlreadyRaisedMessage,
    String? recordFoundMessage,
    bool? nidaVerified,
    bool? passportVerified,
  }) => ResponseResponse(
    nidaNumber: nidaNumber ?? this.nidaNumber,
    isTicketRaised: isTicketRaised ?? this.isTicketRaised,
    ticketAlreadyRaisedMessage:
        ticketAlreadyRaisedMessage ?? this.ticketAlreadyRaisedMessage,
    nidaVerified: nidaVerified ?? this.nidaVerified,
    recordFoundMessage: recordFoundMessage ?? this.recordFoundMessage,
    passportVerified: passportVerified ?? this.passportVerified,
  );

  factory ResponseResponse.fromJson(Map<String, dynamic> json) =>
      ResponseResponse(
        nidaNumber: json["nida_number"],
        isTicketRaised: json["is_ticket_raised"],
        ticketAlreadyRaisedMessage: json["ticket_already_raised_message"],
        nidaVerified: json["nida_verified"],
        recordFoundMessage: json["record_found_message"],
        passportVerified: json["passport_verified"],
      );

  Map<String, dynamic> toJson() => {
    "nida_number": nidaNumber,
    "is_ticket_raised": isTicketRaised,
    "ticket_already_raised_message": ticketAlreadyRaisedMessage,
    "nida_verified": nidaVerified,
    "record_found_message": recordFoundMessage,
    "passport_verified": passportVerified,
  };
}
