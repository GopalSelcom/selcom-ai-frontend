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
  final int baseFare;
  final int distanceCharge;
  final int timeCharge;
  final int total;
  final int discount;
  final int tax;
  final String currency;
  final String paymentMethod;
  final String? completedAt;
  // Driver & vehicle
  final String? driverName;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleRegistration;
  final String? vehicleType;
  // Trip info
  final double distanceKm;
  final int durationMinutes;
  final String pickupAddress;
  final String destinationAddress;

  ReceiptModel({
    required this.rideId,
    required this.baseFare,
    required this.distanceCharge,
    required this.timeCharge,
    required this.total,
    this.discount = 0,
    this.tax = 0,
    required this.currency,
    required this.paymentMethod,
    this.completedAt,
    this.driverName,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleRegistration,
    this.vehicleType,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.pickupAddress = '',
    this.destinationAddress = '',
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    final fareBreakdown =
        (json['fare_breakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    final driverSnap =
        (json['driver_snapshot'] as Map?)?.cast<String, dynamic>() ?? {};
    final pickup = (json['pickup'] as Map?)?.cast<String, dynamic>() ?? {};
    final destination =
        (json['destination'] as Map?)?.cast<String, dynamic>() ?? {};
    return ReceiptModel(
      rideId: json['ride_id'] ?? '',
      baseFare: (fareBreakdown['base_fare'] ?? 0) as int,
      distanceCharge: (fareBreakdown['distance_charge'] ?? 0) as int,
      timeCharge: (fareBreakdown['time_charge'] ?? 0) as int,
      total: (fareBreakdown['total_fare'] ?? 0) as int,
      discount: 0,
      tax: 0,
      currency: (fareBreakdown['currency'] ?? 'TZS') as String,
      paymentMethod: (json['payment_method'] ?? '') as String,
      completedAt: json['completed_at'] as String?,
      driverName: driverSnap['name'] as String?,
      vehicleModel: driverSnap['vehicle_model'] as String?,
      vehicleColor: driverSnap['vehicle_color'] as String?,
      vehicleRegistration: driverSnap['vehicle_registration_number'] as String?,
      vehicleType: driverSnap['vehicle_type'] as String?,
      distanceKm: ((json['distance_km'] ?? 0) as num).toDouble(),
      durationMinutes: (json['duration_minutes'] ?? 0) as int,
      pickupAddress: (pickup['address'] ?? '') as String,
      destinationAddress: (destination['address'] ?? '') as String,
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
          .map(
            (e) => RideCancellationPolicyItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class CheckBookModeResult {
  final bool showBookForOtherOption;
  final double? distanceKm;
  final double thresholdKm;

  const CheckBookModeResult({
    required this.showBookForOtherOption,
    required this.distanceKm,
    required this.thresholdKm,
  });

  factory CheckBookModeResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return CheckBookModeResult(
      showBookForOtherOption: data['show_book_for_other_option'] as bool? ?? false,
      distanceKm: (data['distance_km'] as num?)?.toDouble(),
      thresholdKm: (data['threshold_km'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
