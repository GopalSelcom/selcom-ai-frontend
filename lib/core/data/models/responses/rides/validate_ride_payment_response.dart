import 'dart:convert';

/// Envelope for `POST go/validate_ride_payment`.
class ValidateRidePaymentResponse {
  final int? statusCode;
  final String? message;
  final ValidateRidePaymentData? data;

  const ValidateRidePaymentResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory ValidateRidePaymentResponse.fromRawJson(String str) =>
      ValidateRidePaymentResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ValidateRidePaymentResponse.fromJson(Map<String, dynamic> json) =>
      ValidateRidePaymentResponse(
        statusCode: json['status_code'],
        message: json['message']?.toString(),
        data: json['data'] == null
            ? null
            : ValidateRidePaymentData.fromJson(
                json['data'] is Map<String, dynamic>
                    ? json['data'] as Map<String, dynamic>
                    : Map<String, dynamic>.from(json['data'] as Map),
              ),
      );

  bool get isSuccess =>
      statusCode == 200 && (validationId?.trim().isNotEmpty ?? false);

  String? get validationId => data?.validationId;

  bool get canProceedDirectly =>
      isSuccess &&
      (data?.callbackRequired != true) &&
      (data?.blockStatus == null ||
          data!.blockStatus!.trim().isEmpty ||
          data!.blockStatus!.trim().toLowerCase() == 'confirmed');

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
    'data': data?.toJson(),
  };
}

class ValidateRidePaymentData {
  final String? validationId;
  final int? totalPayableAmount;
  final String? blockStatus;
  final bool? callbackRequired;
  final String? callbackUrl;
  final String? socketRoom;
  final bool? walletEligible;
  final ValidatePaymentWalletSnapshot? walletSnapshot;

  const ValidateRidePaymentData({
    this.validationId,
    this.totalPayableAmount,
    this.blockStatus,
    this.callbackRequired,
    this.callbackUrl,
    this.socketRoom,
    this.walletEligible,
    this.walletSnapshot,
  });

  factory ValidateRidePaymentData.fromRawJson(String str) =>
      ValidateRidePaymentData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ValidateRidePaymentData.fromJson(Map<String, dynamic> json) =>
      ValidateRidePaymentData(
        validationId: json['validation_id']?.toString(),
        totalPayableAmount: (json['total_payable_amount'] as num?)?.toInt(),
        blockStatus: json['block_status']?.toString(),
        callbackRequired: json['callback_required'] as bool?,
        callbackUrl: json['callback_url']?.toString(),
        socketRoom: json['socket_room']?.toString(),
        walletEligible: json['wallet_eligible'] as bool?,
        walletSnapshot: json['wallet_snapshot'] == null
            ? null
            : ValidatePaymentWalletSnapshot.fromJson(
                json['wallet_snapshot'] is Map<String, dynamic>
                    ? json['wallet_snapshot'] as Map<String, dynamic>
                    : Map<String, dynamic>.from(
                        json['wallet_snapshot'] as Map,
                      ),
              ),
      );

  Map<String, dynamic> toJson() => {
    'validation_id': validationId,
    'total_payable_amount': totalPayableAmount,
    'block_status': blockStatus,
    'callback_required': callbackRequired,
    'callback_url': callbackUrl,
    'socket_room': socketRoom,
    'wallet_eligible': walletEligible,
    'wallet_snapshot': walletSnapshot?.toJson(),
  };
}

class ValidatePaymentWalletSnapshot {
  final String? pan;
  final num? available;
  final num? reserved;
  final String? currency;

  const ValidatePaymentWalletSnapshot({
    this.pan,
    this.available,
    this.reserved,
    this.currency,
  });

  factory ValidatePaymentWalletSnapshot.fromRawJson(String str) =>
      ValidatePaymentWalletSnapshot.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ValidatePaymentWalletSnapshot.fromJson(Map<String, dynamic> json) =>
      ValidatePaymentWalletSnapshot(
        pan: json['pan']?.toString(),
        available: json['available'] as num?,
        reserved: json['reserved'] as num?,
        currency: json['currency']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'pan': pan,
    'available': available,
    'reserved': reserved,
    'currency': currency,
  };
}
