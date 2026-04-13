// To parse this JSON data, do
//
//     final paymentStatusUpdateResponse = paymentStatusUpdateResponseFromJson(jsonString);

import 'dart:convert';

PaymentStatusUpdateResponse paymentStatusUpdateResponseFromJson(String str) => PaymentStatusUpdateResponse.fromJson(json.decode(str));

String paymentStatusUpdateResponseToJson(PaymentStatusUpdateResponse data) => json.encode(data.toJson());

class PaymentStatusUpdateResponse {
  String? phase;
  String? status;
  int? amount;
  String? reference;
  String? message;
  int? cancellationFee;
  int? netRefund;

  PaymentStatusUpdateResponse({
    this.phase,
    this.status,
    this.amount,
    this.reference,
    this.message,
    this.cancellationFee,
    this.netRefund,
  });

  PaymentStatusUpdateResponse copyWith({
    String? phase,
    String? status,
    int? amount,
    String? reference,
    String? message,
    int? cancellationFee,
    int? netRefund,
  }) =>
      PaymentStatusUpdateResponse(
        phase: phase ?? this.phase,
        status: status ?? this.status,
        amount: amount ?? this.amount,
        reference: reference ?? this.reference,
        message: message ?? this.message,
        cancellationFee: cancellationFee ?? this.cancellationFee,
        netRefund: netRefund ?? this.netRefund,
      );

  factory PaymentStatusUpdateResponse.fromJson(Map<String, dynamic> json) => PaymentStatusUpdateResponse(
    phase: json["phase"],
    status: json["status"],
    amount: json["amount"],
    reference: json["reference"],
    message: json["message"],
    cancellationFee: json["cancellation_fee"],
    netRefund: json["net_refund"],
  );

  Map<String, dynamic> toJson() => {
    "phase": phase,
    "status": status,
    "amount": amount,
    "reference": reference,
    "message": message,
    "cancellation_fee": cancellationFee,
    "net_refund": netRefund,
  };
}
