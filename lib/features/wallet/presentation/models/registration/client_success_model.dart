import 'dart:convert';

ClientSuccessModel clientSuccessModelFromJson(String str) =>
    ClientSuccessModel.fromJson(json.decode(str));

String clientSuccessModelToJson(ClientSuccessModel data) =>
    json.encode(data.toJson());

class ClientSuccessModel {
  int? statusCode;
  String? message;
  Response? response;

  ClientSuccessModel({this.statusCode, this.message, this.response});

  ClientSuccessModel copyWith({
    int? statusCode,
    String? message,
    Response? response,
  }) => ClientSuccessModel(
    statusCode: statusCode ?? this.statusCode,
    message: message ?? this.message,
    response: response ?? this.response,
  );

  factory ClientSuccessModel.fromJson(Map<String, dynamic> json) =>
      ClientSuccessModel(
        statusCode: json["status_code"],
        message: json["message"],
        response: json["response"] == null
            ? null
            : Response.fromJson(json["response"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
  };
}

class Response {
  dynamic reference;
  String? externalId;
  String? resultcode;
  String? result;
  String? message;
  List<Datum>? data;

  Response({
    this.reference,
    this.externalId,
    this.resultcode,
    this.result,
    this.message,
    this.data,
  });

  Response copyWith({
    dynamic reference,
    String? externalId,
    String? resultcode,
    String? result,
    String? message,
    List<Datum>? data,
  }) => Response(
    reference: reference ?? this.reference,
    externalId: externalId ?? this.externalId,
    resultcode: resultcode ?? this.resultcode,
    result: result ?? this.result,
    message: message ?? this.message,
    data: data ?? this.data,
  );

  factory Response.fromJson(Map<String, dynamic> json) => Response(
    reference: json["reference"],
    externalId: json["externalId"],
    resultcode: json["resultcode"],
    result: json["result"],
    message: json["message"],
    data: json["data"] == null
        ? []
        : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "reference": reference,
    "externalId": externalId,
    "resultcode": resultcode,
    "result": result,
    "message": message,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class Datum {
  int? savingsId;
  int? clientId;
  int? id;
  String? accountNo;
  String? referralCode;

  Datum({
    this.savingsId,
    this.clientId,
    this.id,
    this.accountNo,
    this.referralCode,
  });

  Datum copyWith({
    int? savingsId,
    int? clientId,
    int? id,
    String? accountNo,
    String? referralCode,
  }) => Datum(
    savingsId: savingsId ?? this.savingsId,
    clientId: clientId ?? this.clientId,
    id: id ?? this.id,
    accountNo: accountNo ?? this.accountNo,
    referralCode: referralCode ?? this.referralCode,
  );

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
    savingsId: json["savingsId"],
    clientId: json["clientId"],
    id: json["id"],
    accountNo: json["accountNo"],
    referralCode: json["referralCode"],
  );

  Map<String, dynamic> toJson() => {
    "savingsId": savingsId,
    "clientId": clientId,
    "id": id,
    "accountNo": accountNo,
    "referralCode": referralCode,
  };
}
