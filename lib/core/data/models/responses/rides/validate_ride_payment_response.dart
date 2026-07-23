import 'dart:convert';

/// Envelope for `POST go/validate_ride_payment` (from `model/model.dart`).
class ValidateRidePaymentResponse {
  int? statusCode;
  String? message;
  ValidateRidePaymentData? data;

  ValidateRidePaymentResponse({this.statusCode, this.message, this.data});

  factory ValidateRidePaymentResponse.fromJson(String str) =>
      ValidateRidePaymentResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ValidateRidePaymentResponse.fromMap(Map<String, dynamic> json) =>
      ValidateRidePaymentResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : ValidateRidePaymentData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

class ValidateRidePaymentData {
  String? validationId;
  int? totalPayableAmount;
  String? blockStatus;
  bool? callbackRequired;
  dynamic callbackUrl;
  dynamic socketRoom;
  bool? walletEligible;
  ValidateRidePaymentWalletSnapshot? walletSnapshot;

  ValidateRidePaymentData({
    this.validationId,
    this.totalPayableAmount,
    this.blockStatus,
    this.callbackRequired,
    this.callbackUrl,
    this.socketRoom,
    this.walletEligible,
    this.walletSnapshot,
  });

  factory ValidateRidePaymentData.fromJson(String str) =>
      ValidateRidePaymentData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ValidateRidePaymentData.fromMap(Map<String, dynamic> json) =>
      ValidateRidePaymentData(
        validationId: json["validation_id"],
        totalPayableAmount: json["total_payable_amount"],
        blockStatus: json["block_status"],
        callbackRequired: json["callback_required"],
        callbackUrl: json["callback_url"],
        socketRoom: json["socket_room"],
        walletEligible: json["wallet_eligible"],
        walletSnapshot: json["wallet_snapshot"] == null
            ? null
            : ValidateRidePaymentWalletSnapshot.fromMap(json["wallet_snapshot"]),
      );

  Map<String, dynamic> toMap() => {
    "validation_id": validationId,
    "total_payable_amount": totalPayableAmount,
    "block_status": blockStatus,
    "callback_required": callbackRequired,
    "callback_url": callbackUrl,
    "socket_room": socketRoom,
    "wallet_eligible": walletEligible,
    "wallet_snapshot": walletSnapshot?.toMap(),
  };
}

class ValidateRidePaymentWalletSnapshot {
  String? pan;
  int? available;
  int? reserved;
  String? currency;

  ValidateRidePaymentWalletSnapshot({
    this.pan,
    this.available,
    this.reserved,
    this.currency,
  });

  factory ValidateRidePaymentWalletSnapshot.fromJson(String str) =>
      ValidateRidePaymentWalletSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ValidateRidePaymentWalletSnapshot.fromMap(
    Map<String, dynamic> json,
  ) => ValidateRidePaymentWalletSnapshot(
    pan: json["pan"],
    available: json["available"],
    reserved: json["reserved"],
    currency: json["currency"],
  );

  Map<String, dynamic> toMap() => {
    "pan": pan,
    "available": available,
    "reserved": reserved,
    "currency": currency,
  };
}
