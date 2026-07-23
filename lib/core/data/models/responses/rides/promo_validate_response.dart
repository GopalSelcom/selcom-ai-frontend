import 'dart:convert';

/// Models for `POST go/promo/validate` (from `model/model.dart` + `error_code`).
class PromoValidateResponse {
  int? statusCode;
  String? message;
  String? errorCode;
  PromoValidateData? data;

  PromoValidateResponse({
    this.statusCode,
    this.message,
    this.errorCode,
    this.data,
  });

  factory PromoValidateResponse.fromJson(String str) =>
      PromoValidateResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PromoValidateResponse.fromMap(Map<String, dynamic> json) =>
      PromoValidateResponse(
        statusCode: json["status_code"],
        message: json["message"],
        errorCode: json["error_code"],
        data: json["data"] == null
            ? null
            : PromoValidateData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "error_code": errorCode,
    "data": data?.toMap(),
  };
}

class PromoValidateData {
  String? code;
  String? type;
  int? discountValue;
  int? discountAmount;
  int? discountedFare;
  String? description;

  PromoValidateData({
    this.code,
    this.type,
    this.discountValue,
    this.discountAmount,
    this.discountedFare,
    this.description,
  });

  factory PromoValidateData.fromJson(String str) =>
      PromoValidateData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PromoValidateData.fromMap(Map<String, dynamic> json) =>
      PromoValidateData(
        code: json["code"],
        type: json["type"],
        discountValue: json["discount_value"],
        discountAmount: json["discount_amount"],
        discountedFare: json["discounted_fare"],
        description: json["description"],
      );

  Map<String, dynamic> toMap() => {
    "code": code,
    "type": type,
    "discount_value": discountValue,
    "discount_amount": discountAmount,
    "discounted_fare": discountedFare,
    "description": description,
  };
}
