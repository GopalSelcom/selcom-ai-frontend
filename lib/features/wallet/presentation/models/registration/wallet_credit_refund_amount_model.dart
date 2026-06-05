// To parse this JSON data, do
//
//     final walletCreditRefundAmountModel = walletCreditRefundAmountModelFromJson(jsonString);

import 'dart:convert';

WalletCreditRefundAmountModel walletCreditRefundAmountModelFromJson(
  String str,
) => WalletCreditRefundAmountModel.fromJson(json.decode(str));

String walletCreditRefundAmountModelToJson(
  WalletCreditRefundAmountModel data,
) => json.encode(data.toJson());

class WalletCreditRefundAmountModel {
  final int? statusCode;
  final String? message;

  WalletCreditRefundAmountModel({this.statusCode, this.message});

  factory WalletCreditRefundAmountModel.fromJson(Map<String, dynamic> json) =>
      WalletCreditRefundAmountModel(
        statusCode: json["status_code"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
  };
}
