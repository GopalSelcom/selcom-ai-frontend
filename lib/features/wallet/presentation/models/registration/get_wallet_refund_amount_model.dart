// To parse this JSON data, do
//
//     final getWalletRefundAmountModel = getWalletRefundAmountModelFromJson(jsonString);

import 'dart:convert';

GetWalletRefundAmountModel getWalletRefundAmountModelFromJson(String str) =>
    GetWalletRefundAmountModel.fromJson(json.decode(str));

String getWalletRefundAmountModelToJson(GetWalletRefundAmountModel data) =>
    json.encode(data.toJson());

class GetWalletRefundAmountModel {
  final int? statusCode;
  final String? message;
  final GetWalletRefundAmountResponse? response;

  GetWalletRefundAmountModel({this.statusCode, this.message, this.response});

  factory GetWalletRefundAmountModel.fromJson(Map<String, dynamic> json) =>
      GetWalletRefundAmountModel(
        statusCode: json["status_code"],
        message: json["message"],
        response: json["response"] == null
            ? null
            : GetWalletRefundAmountResponse.fromJson(json["response"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "response": response?.toJson(),
  };
}

class GetWalletRefundAmountResponse {
  final int? totalRefundAmount;
  final String? message;
  final bool? isRefundAvailable;

  GetWalletRefundAmountResponse({
    this.totalRefundAmount,
    this.message,
    this.isRefundAvailable,
  });

  factory GetWalletRefundAmountResponse.fromJson(Map<String, dynamic> json) =>
      GetWalletRefundAmountResponse(
        totalRefundAmount: json["total_refund_amount"],
        message: json["message"],
        isRefundAvailable: json["is_refund_available"],
      );

  Map<String, dynamic> toJson() => {
    "total_refund_amount": totalRefundAmount,
    "message": message,
    "is_refund_available": isRefundAvailable,
  };
}
