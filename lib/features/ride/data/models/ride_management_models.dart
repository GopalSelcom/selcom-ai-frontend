class BookingResponseModel {
  final String id;
  final String status;
  final int pinCode;
  final int fare;
  final String currency;

  BookingResponseModel({
    required this.id,
    required this.status,
    required this.pinCode,
    required this.fare,
    required this.currency,
  });

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    return BookingResponseModel(
      id: json['_id'] ?? '',
      status: json['status'] ?? '',
      pinCode: (json['pin_code'] is int)
          ? json['pin_code']
          : int.parse(json['pin_code'].toString()),
      fare: (json['fare'] is int)
          ? json['fare']
          : int.parse(json['fare'].toString()),
      currency: json['currency'] ?? 'TZS',
    );
  }
}

class RecentDestinationModel {
  final String address;
  final double lat;
  final double lng;
  final DateTime lastUsed;

  RecentDestinationModel({
    required this.address,
    required this.lat,
    required this.lng,
    required this.lastUsed,
  });

  factory RecentDestinationModel.fromJson(Map<String, dynamic> json) {
    return RecentDestinationModel(
      address: json['address'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      lastUsed: DateTime.parse(
        json['last_used'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class ReceiptModel {
  final String rideId;
  final int fare;
  final int discount;
  final int tax;
  final int total;
  final String currency;
  final String paymentMethod;

  ReceiptModel({
    required this.rideId,
    required this.fare,
    required this.discount,
    required this.tax,
    required this.total,
    required this.currency,
    required this.paymentMethod,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      rideId: json['ride_id'] ?? '',
      fare: json['fare'] ?? 0,
      discount: json['discount'] ?? 0,
      tax: json['tax'] ?? 0,
      total: json['total'] ?? 0,
      currency: json['currency'] ?? 'TZS',
      paymentMethod: json['payment_method'] ?? '',
    );
  }
}

class RideCancellationPolicyItem {
  final String status;
  final bool canCancel;
  final int fee;
  final String label;

  RideCancellationPolicyItem({
    required this.status,
    required this.canCancel,
    required this.fee,
    required this.label,
  });

  factory RideCancellationPolicyItem.fromJson(Map<String, dynamic> json) {
    return RideCancellationPolicyItem(
      status: (json['status'] ?? '').toString(),
      canCancel: json['can_cancel'] == true,
      fee: (json['fee'] as num?)?.toInt() ?? 0,
      label: (json['label'] ?? '').toString(),
    );
  }
}

class RideCancellationChargesModel {
  final String rideId;
  final String currentStatus;
  final bool canCancel;
  final int cancellationFee;
  final int netRefund;
  final List<RideCancellationPolicyItem> policy;

  RideCancellationChargesModel({
    required this.rideId,
    required this.currentStatus,
    required this.canCancel,
    required this.cancellationFee,
    required this.netRefund,
    required this.policy,
  });

  factory RideCancellationChargesModel.fromJson(Map<String, dynamic> json) {
    final policyRaw = (json['policy'] as List?) ?? const [];
    return RideCancellationChargesModel(
      rideId: (json['ride_id'] ?? '').toString(),
      currentStatus: (json['current_status'] ?? '').toString(),
      canCancel: json['can_cancel'] == true,
      cancellationFee: (json['cancellation_fee'] as num?)?.toInt() ?? 0,
      netRefund: (json['net_refund'] as num?)?.toInt() ?? 0,
      policy: policyRaw
          .whereType<Map>()
          .map((e) => RideCancellationPolicyItem.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
    );
  }
}
