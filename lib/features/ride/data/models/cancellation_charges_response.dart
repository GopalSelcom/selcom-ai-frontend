import 'dart:convert';

/// Envelope for `GET go/rides/{id}/cancellation-charges` (from `model/model.dart`).
class RideCancellationChargesResponse {
  int? statusCode;
  RideCancellationChargesData? data;

  RideCancellationChargesResponse({this.statusCode, this.data});

  factory RideCancellationChargesResponse.fromJson(String str) =>
      RideCancellationChargesResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideCancellationChargesResponse.fromMap(Map<String, dynamic> json) =>
      RideCancellationChargesResponse(
        statusCode: json["status_code"],
        data: json["data"] == null
            ? null
            : RideCancellationChargesData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "data": data?.toMap(),
  };
}

/// `data` for cancellation charges.
class RideCancellationChargesData {
  String? rideId;
  String? currentStatus;
  bool? canCancel;
  int? cancellationFee;
  int? netRefund;
  List<RideCancellationPolicyItem>? policy;

  RideCancellationChargesData({
    this.rideId,
    this.currentStatus,
    this.canCancel,
    this.cancellationFee,
    this.netRefund,
    this.policy,
  });

  factory RideCancellationChargesData.fromJson(String str) =>
      RideCancellationChargesData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideCancellationChargesData.fromMap(Map<String, dynamic> json) =>
      RideCancellationChargesData(
        rideId: json["ride_id"],
        currentStatus: json["current_status"],
        canCancel: json["can_cancel"],
        cancellationFee: json["cancellation_fee"],
        netRefund: json["net_refund"],
        policy: json["policy"] == null
            ? []
            : List<RideCancellationPolicyItem>.from(
                json["policy"]!.map(
                  (x) => RideCancellationPolicyItem.fromMap(x),
                ),
              ),
      );

  Map<String, dynamic> toMap() => {
    "ride_id": rideId,
    "current_status": currentStatus,
    "can_cancel": canCancel,
    "cancellation_fee": cancellationFee,
    "net_refund": netRefund,
    "policy": policy == null
        ? []
        : List<dynamic>.from(policy!.map((x) => x.toMap())),
  };
}

class RideCancellationPolicyItem {
  String? status;
  bool? canCancel;
  int? fee;
  String? label;

  RideCancellationPolicyItem({
    this.status,
    this.canCancel,
    this.fee,
    this.label,
  });

  factory RideCancellationPolicyItem.fromJson(String str) =>
      RideCancellationPolicyItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideCancellationPolicyItem.fromMap(Map<String, dynamic> json) =>
      RideCancellationPolicyItem(
        status: json["status"],
        canCancel: json["can_cancel"],
        fee: json["fee"],
        label: json["label"],
      );

  Map<String, dynamic> toMap() => {
    "status": status,
    "can_cancel": canCancel,
    "fee": fee,
    "label": label,
  };
}
