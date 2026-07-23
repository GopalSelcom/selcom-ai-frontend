import '../../../../core/constants/currency_code.dart';
import '../../../../core/data/models/ride_model.dart';

String receiptTransactionIdFromJson(Map<String, dynamic> json) {
  final direct =
      json['transid'] ??
      json['trans_id'] ??
      json['transaction_id'] ??
      json['block_transid'];
  final directText = direct?.toString().trim() ?? '';
  if (directText.isNotEmpty) return directText;

  final payment = (json['payment'] as Map?)?.cast<String, dynamic>();
  if (payment != null) {
    final paymentId =
        (payment['transid'] ?? payment['trans_id'])?.toString().trim() ?? '';
    if (paymentId.isNotEmpty) return paymentId;
  }

  final preauths = json['preauths'];
  if (preauths is List) {
    for (final item in preauths) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      for (final key in ['transid', 'capture_transid']) {
        final id = map[key]?.toString().trim() ?? '';
        if (id.isNotEmpty) return id;
      }
      final raw = map['raw_response'];
      if (raw is Map) {
        final rawId =
            Map<String, dynamic>.from(raw)['transid']?.toString().trim() ?? '';
        if (rawId.isNotEmpty) return rawId;
      }
    }
  }

  return '';
}

class ReceiptModel {
  final String rideId;
  final String transactionId;
  final int baseFare;
  final int distanceCharge;
  final int timeCharge;
  final int total;
  final int discount;
  final int tax;
  final String currency;
  final String paymentMethod;
  final String? completedAt;

  /// From `fare_breakdown.promo_code` when ride used a promo.
  final String? promoCode;
  final int promoDiscountAmount;

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
  final bool isMultiStop;
  final List<RideStopModel> stops;

  // Detailed Fare breakdown fields
  final int totalFare;
  final int bookingFee;
  final int totalAmount;

  ReceiptModel({
    required this.rideId,
    this.transactionId = '',
    required this.baseFare,
    required this.distanceCharge,
    required this.timeCharge,
    required this.total,
    this.discount = 0,
    this.tax = 0,
    required this.currency,
    required this.paymentMethod,
    this.completedAt,
    this.promoCode,
    this.promoDiscountAmount = 0,
    this.driverName,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleRegistration,
    this.vehicleType,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.pickupAddress = '',
    this.destinationAddress = '',
    this.isMultiStop = false,
    this.stops = const [],
    this.totalFare = 0,
    this.bookingFee = 0,
    this.totalAmount = 0,
  });

  ReceiptModel copyWith({String? transactionId}) {
    return ReceiptModel(
      rideId: rideId,
      transactionId: transactionId ?? this.transactionId,
      baseFare: baseFare,
      distanceCharge: distanceCharge,
      timeCharge: timeCharge,
      total: total,
      discount: discount,
      tax: tax,
      currency: currency,
      paymentMethod: paymentMethod,
      completedAt: completedAt,
      promoCode: promoCode,
      promoDiscountAmount: promoDiscountAmount,
      driverName: driverName,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      vehicleRegistration: vehicleRegistration,
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      isMultiStop: isMultiStop,
      stops: stops,
      totalFare: totalFare,
      bookingFee: bookingFee,
      totalAmount: totalAmount,
    );
  }

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    final fareBreakdown =
        (json['fare_breakdown'] as Map?)?.cast<String, dynamic>() ?? {};
    final driverSnap =
        (json['driver_snapshot'] as Map?)?.cast<String, dynamic>() ?? {};
    final pickup = (json['pickup'] as Map?)?.cast<String, dynamic>() ?? {};
    final destination =
        (json['destination'] as Map?)?.cast<String, dynamic>() ?? {};
    final totalRaw =
        fareBreakdown['total_amount'] ?? fareBreakdown['total_fare'] ?? 0;
    final totalParsed = totalRaw is num
        ? totalRaw.toInt()
        : int.tryParse(totalRaw.toString()) ?? 0;
    final promoDisc = (fareBreakdown['promo_discount'] as num?)?.toInt() ?? 0;

    final stopsJson = json['stops'] as List? ?? [];
    final stops = stopsJson
        .whereType<Map>()
        .map((e) => RideStopModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final baseFare = (fareBreakdown['base_fare'] ?? 0) as int;
    final distanceCharge = (fareBreakdown['distance_charge'] ?? 0) as int;
    final timeCharge = (fareBreakdown['time_charge'] ?? 0) as int;
    final totalFare =
        (fareBreakdown['total_fare'] ??
                (baseFare + distanceCharge + timeCharge))
            as int;
    final bookingFee = (fareBreakdown['booking_fee'] ?? 0) as int;
    final totalAmount =
        (fareBreakdown['total_amount'] ?? (totalFare + bookingFee)) as int;

    return ReceiptModel(
      rideId: (json['ride_id'] ?? json['_id'] ?? '').toString(),
      transactionId: receiptTransactionIdFromJson(json),
      baseFare:
          (fareBreakdown['base_fare'] ?? fareBreakdown['ride_charge'] ?? 0)
              as int,
      distanceCharge: (fareBreakdown['distance_charge'] ?? 0) as int,
      timeCharge: (fareBreakdown['time_charge'] ?? 0) as int,
      total: totalParsed,
      discount: 0,
      tax: 0,
      currency: (fareBreakdown['currency'] ?? CurrencyCode.tzs) as String,
      promoCode: fareBreakdown['promo_code']?.toString(),
      promoDiscountAmount: promoDisc,
      paymentMethod: (json['payment_method'] ?? '') as String,
      completedAt: (json['completed_at'] ?? json['ride_completed_at'])
          ?.toString(),
      driverName: driverSnap['name'] as String?,
      vehicleModel: driverSnap['vehicle_model'] as String?,
      vehicleColor: driverSnap['vehicle_color'] as String?,
      vehicleRegistration: driverSnap['vehicle_registration_number'] as String?,
      vehicleType: driverSnap['vehicle_type'] as String?,
      distanceKm: ((json['distance_km'] ?? 0) as num).toDouble(),
      durationMinutes: (json['duration_minutes'] ?? 0) as int,
      pickupAddress: (pickup['address'] ?? '') as String,
      destinationAddress: (destination['address'] ?? '') as String,
      isMultiStop: json['is_multi_stop'] ?? false,
      stops: stops,
      totalFare: totalFare,
      bookingFee: bookingFee,
      totalAmount: totalAmount,
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
      showBookForOtherOption:
          data['show_book_for_other_option'] as bool? ?? false,
      distanceKm: (data['distance_km'] as num?)?.toDouble(),
      thresholdKm: (data['threshold_km'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
