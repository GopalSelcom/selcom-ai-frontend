import 'dart:convert';

/// Envelope for `PUT go/rides/{id}/cancel`.
class CancelRideResponse {
  int? statusCode;
  String? message;
  CancelRideData? data;

  CancelRideResponse({this.statusCode, this.message, this.data});

  factory CancelRideResponse.fromJson(String str) =>
      CancelRideResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CancelRideResponse.fromMap(Map<String, dynamic> json) =>
      CancelRideResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : CancelRideData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

/// `data` for cancel ride.
class CancelRideData {
  String? rideId;
  String? status;
  int? cancellationFee;
  int? netRefund;
  int? walletCaptured;
  int? walletPendingRelease;

  CancelRideData({
    this.rideId,
    this.status,
    this.cancellationFee,
    this.netRefund,
    this.walletCaptured,
    this.walletPendingRelease,
  });

  factory CancelRideData.fromJson(String str) =>
      CancelRideData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CancelRideData.fromMap(Map<String, dynamic> json) => CancelRideData(
    rideId: json["ride_id"],
    status: json["status"],
    cancellationFee: json["cancellation_fee"],
    netRefund: json["net_refund"],
    walletCaptured: json["wallet_captured"],
    walletPendingRelease: json["wallet_pending_release"],
  );

  Map<String, dynamic> toMap() => {
    "ride_id": rideId,
    "status": status,
    "cancellation_fee": cancellationFee,
    "net_refund": netRefund,
    "wallet_captured": walletCaptured,
    "wallet_pending_release": walletPendingRelease,
  };
}
