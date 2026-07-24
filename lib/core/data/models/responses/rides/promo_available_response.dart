import 'dart:convert';

/// Models for `GET go/promo/available` (from `model/model.dart`).
class PromoAvailableResponse {
  int? statusCode;
  String? message;
  PromoAvailableData? data;

  PromoAvailableResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory PromoAvailableResponse.fromJson(String str) =>
      PromoAvailableResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PromoAvailableResponse.fromMap(Map<String, dynamic> json) =>
      PromoAvailableResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : PromoAvailableData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

class PromoAvailableData {
  List<AvailablePromo>? promos;
  int? total;

  PromoAvailableData({
    this.promos,
    this.total,
  });

  factory PromoAvailableData.fromJson(String str) =>
      PromoAvailableData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PromoAvailableData.fromMap(Map<String, dynamic> json) =>
      PromoAvailableData(
        promos: json["promos"] == null
            ? []
            : List<AvailablePromo>.from(
                json["promos"]!.map((x) => AvailablePromo.fromMap(x)),
              ),
        total: json["total"],
      );

  Map<String, dynamic> toMap() => {
    "promos": promos == null
        ? []
        : List<dynamic>.from(promos!.map((x) => x.toMap())),
    "total": total,
  };
}

class AvailablePromo {
  String? id;
  String? code;
  String? type;
  int? discountValue;
  dynamic maxDiscountAmount;
  int? minRideAmount;
  List<String>? applicableVehicleTypes;
  String? validUntil;
  String? description;
  bool? isAutoApply;
  bool? isCashback;

  AvailablePromo({
    this.id,
    this.code,
    this.type,
    this.discountValue,
    this.maxDiscountAmount,
    this.minRideAmount,
    this.applicableVehicleTypes,
    this.validUntil,
    this.description,
    this.isAutoApply,
    this.isCashback,
  });

  factory AvailablePromo.fromJson(String str) =>
      AvailablePromo.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AvailablePromo.fromMap(Map<String, dynamic> json) => AvailablePromo(
    id: json["id"],
    code: json["code"],
    type: json["type"],
    discountValue: json["discount_value"],
    maxDiscountAmount: json["max_discount_amount"],
    minRideAmount: json["min_ride_amount"],
    applicableVehicleTypes: json["applicable_vehicle_types"] == null
        ? []
        : List<String>.from(json["applicable_vehicle_types"]!.map((x) => x)),
    validUntil: json["valid_until"],
    description: json["description"],
    isAutoApply: json["is_auto_apply"],
    isCashback: json["is_cashback"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "code": code,
    "type": type,
    "discount_value": discountValue,
    "max_discount_amount": maxDiscountAmount,
    "min_ride_amount": minRideAmount,
    "applicable_vehicle_types": applicableVehicleTypes == null
        ? []
        : List<dynamic>.from(applicableVehicleTypes!.map((x) => x)),
    "valid_until": validUntil,
    "description": description,
    "is_auto_apply": isAutoApply,
    "is_cashback": isCashback,
  };
}
