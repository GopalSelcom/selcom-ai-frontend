import 'dart:convert';

class SpMainBalanceResponse {
  int? statusCode;
  String? message;
  SpAccountData? data;

  SpMainBalanceResponse({this.statusCode, this.message, this.data});

  factory SpMainBalanceResponse.fromRawJson(String str) =>
      SpMainBalanceResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SpMainBalanceResponse.fromJson(Map<String, dynamic> json) =>
      SpMainBalanceResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null ? null : SpAccountData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class SpAccountData {
  double? balance;

  SpAccountData({this.balance});

  factory SpAccountData.fromRawJson(String str) => SpAccountData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SpAccountData.fromJson(Map<String, dynamic> json) =>
      SpAccountData(balance: json["balance"]?.toDouble());

  Map<String, dynamic> toJson() => {"balance": balance};
}
