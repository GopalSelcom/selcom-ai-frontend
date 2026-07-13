import 'dart:convert';

/// Envelope for `go/selcom_pesa/main_balance`.
///
/// Example: `{"status_code":200,"message":"...","data":{"balance":81964.85}}`
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
      SpAccountData(balance: _parseBalance(json['balance']));

  /// Accepts JSON numbers or numeric strings from main_balance `data.balance`.
  static double? _parseBalance(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  Map<String, dynamic> toJson() => {"balance": balance};
}
