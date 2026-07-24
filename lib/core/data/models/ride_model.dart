import '../../../shared/utils/driver_search_timeout_from_cancel_time.dart';
import '../../domain/entities/location_entity.dart';
import 'location_model.dart';
import 'mid_ride_cancel_model.dart';

enum RideStatus {
  searching,
  driverAssigned,
  driverArriving,
  driverArrived,
  rideStarted,
  rideInProgress,
  nearDestination,
  rideCompleted,
  cancelled,
  noDriverFound,
}

enum PaymentStatus { pending, blocked, completed, failed, refunded }

enum PaymentMethod { wallet, selcomPesa, mobileMoney, card }

/// In-app ride model for live/ongoing flows — the only in-app ride type.
///
/// Built from `GET go/rides/active` / `GET go/rides/:id` payloads (see
/// [ActiveRideResponse] / [RideDetailsResponse] and their `toRideModel()`).
class RideModel {
  final String id;
  final String riderId;
  final String? driverId;
  final String vehicleTypeId;
  final String? vehicleKey;
  final String? vehicleDisplayName;
  final RideStatus status;
  final LocationEntity pickup;
  final LocationEntity destination;
  final List<RideStopModel> stops;
  final bool isMultiStop;
  final int currentStopIndex;
  final int fareEstimate;
  final int? finalFare;
  final double distanceKm;
  final int durationMinutes;
  final String pinCode;
  final bool pinRequired;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final int? cancellationFee;
  final int? riderRating;
  final bool showReviewUi;
  final FareBreakdownModel? fareBreakdown;
  final DriverSnapshotModel? driverSnapshot;
  final VehicleSnapshotModel? vehicleSnapshot;
  final DateTime createdAt;
  final PendingStopsUpdateModel? pendingStopsUpdate;
  final bool isBookedForOther;
  final bool isBookAny;
  final String? passengerName;
  final String? passengerPhone;
  final List<PdfLinkModel>? pdfLinks;

  /// Applied promo on this ride (GET ride / history payloads).
  final String? promoCode;
  final int? promoDiscount;
  final bool? promoAutoApplied;
  final int? cashbackAmount;

  /// Wallet/payment transaction id from ride payload (`transid`).
  final String transactionId;

  /// Present when the driver ended the trip mid-ride (partial charge flow).
  final MidRideCancelModel? midRideCancel;

  /// Driver-search window length from API `cancel_time` (milliseconds).
  final int? cancelTime;

  /// When the driver search phase started (`search_started_at`).
  final DateTime? searchStartedAt;

  const RideModel({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.vehicleTypeId,
    this.vehicleKey,
    this.vehicleDisplayName,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.stops,
    this.isMultiStop = false,
    this.currentStopIndex = 0,
    required this.fareEstimate,
    this.finalFare,
    required this.distanceKm,
    required this.durationMinutes,
    required this.pinCode,
    required this.pinRequired,
    required this.paymentMethod,
    required this.paymentStatus,
    this.cancellationFee,
    this.riderRating,
    this.showReviewUi = true,
    this.fareBreakdown,
    this.driverSnapshot,
    this.vehicleSnapshot,
    required this.createdAt,
    this.pendingStopsUpdate,
    this.isBookedForOther = false,
    this.isBookAny = false,
    this.passengerName,
    this.passengerPhone,
    this.pdfLinks,
    this.promoCode,
    this.promoDiscount,
    this.promoAutoApplied,
    this.cashbackAmount,
    this.transactionId = '',
    this.midRideCancel,
    this.cancelTime,
    this.searchStartedAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    // Backend may return createdAt or created_at
    final createdAtStr =
        json['createdAt'] ??
        json['created_at'] ??
        DateTime.now().toIso8601String();

    final driverSnapshotJson = json['driver_snapshot'];
    final driverSnapshot = driverSnapshotJson != null
        ? DriverSnapshotModel.fromJson(driverSnapshotJson)
        : null;

    // Use top-level pin_code or fallback to verification_code from driver_snapshot
    final pin =
        (json['pin_code']?.toString() ?? driverSnapshot?.verificationCode ?? '')
            .trim();
    final pinRequiredRaw = json['pin_required'];
    final bool pinRequired = pinRequiredRaw == null
        ? true
        : (pinRequiredRaw == true ||
              pinRequiredRaw == 1 ||
              pinRequiredRaw.toString().toLowerCase() == 'true');
    final fareBreakdownJson = json['fare_breakdown'];
    final fareBreakdown = fareBreakdownJson is Map<String, dynamic>
        ? FareBreakdownModel.fromJson(fareBreakdownJson)
        : fareBreakdownJson is Map
        ? FareBreakdownModel.fromJson(
            Map<String, dynamic>.from(fareBreakdownJson),
          )
        : null;

    final stopsJson = json['stops'] as List? ?? [];
    final stops = stopsJson.map((e) => RideStopModel.fromJson(e)).toList();
    final vehicleTypeIdRaw = json['vehicle_type_id'];
    final vehicleTypeKey = vehicleTypeIdRaw is Map
        ? vehicleTypeIdRaw['key']?.toString()
        : json['vehicle_key']?.toString();
    final vehicleTypeDisplayName = vehicleTypeIdRaw is Map
        ? vehicleTypeIdRaw['display_name']?.toString()
        : json['vehicle_display_name']?.toString();

    final pendingUpdateJson = json['pending_stops_update'];
    final pendingStopsUpdate = pendingUpdateJson != null
        ? PendingStopsUpdateModel.fromJson(pendingUpdateJson)
        : null;

    final pdfLinksJson = json['pdf_links'] as List?;
    final pdfLinks = pdfLinksJson
        ?.map((e) => PdfLinkModel.fromJson(e))
        .toList();

    final promoCodeRaw = json['promo_code']?.toString().trim();
    final promoCodeParsed = (promoCodeRaw == null || promoCodeRaw.isEmpty)
        ? null
        : promoCodeRaw;
    final promoDiscountParsed = (json['promo_discount'] as num?)?.toInt();
    final cashbackAmountParsed = (json['cashback_amount'] as num?)?.toInt();
    final promoAutoAppliedParsed = json['promo_auto_applied'] as bool?;

    final midRideCancelJson = json['mid_ride_cancel'];
    final midRideCancel = midRideCancelJson is Map
        ? MidRideCancelModel.fromJson(Map<String, dynamic>.from(midRideCancelJson))
        : null;

    return RideModel(
      id: json['_id'] ?? '',
      riderId: json['rider_id'] ?? '',
      driverId: json['driver_id'],
      vehicleTypeId: json['vehicle_type_id'] is Map
          ? (json['vehicle_type_id']['_id'] ?? '').toString()
          : (json['vehicle_type_id'] ?? '').toString(),
      vehicleKey: vehicleTypeKey,
      vehicleDisplayName: vehicleTypeDisplayName,
      status: RideStatus.values.firstWhere(
        (e) => e.name == _toCamelCase(json['status'] ?? 'searching'),
        orElse: () => RideStatus.searching,
      ),
      pickup: LocationModel.fromJson(json['pickup'] ?? {}),
      destination: LocationModel.fromJson(json['destination'] ?? {}),
      stops: stops,
      isMultiStop: json['is_multi_stop'] ?? false,
      currentStopIndex: json['current_stop_index'] ?? 0,
      fareEstimate: json['fare_estimate'] ?? 0,
      finalFare: json['final_fare'],
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 0,
      pinCode: pin,
      pinRequired: pinRequired,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == _toCamelCase(json['payment_method'] ?? 'wallet'),
        orElse: () => PaymentMethod.wallet,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (json['payment_status'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      cancellationFee: json['cancellation_fee'],
      riderRating: (json['rider_rating'] as num?)?.toInt(),
      showReviewUi: json['show_review_ui'] is bool
          ? json['show_review_ui'] as bool
          : true,
      fareBreakdown: fareBreakdown,
      driverSnapshot: driverSnapshot,
      vehicleSnapshot: json['vehicle_snapshot'] != null
          ? VehicleSnapshotModel.fromJson(json['vehicle_snapshot'])
          : null,
      createdAt: DateTime.parse(createdAtStr),
      pendingStopsUpdate: pendingStopsUpdate,
      isBookedForOther: json['is_booked_for_other'] ?? false,
      isBookAny: json['is_book_any'] == true,
      passengerName: _nullableTrimmedString(json['passenger_name']),
      passengerPhone: _nullableTrimmedString(json['passenger_phone']),
      pdfLinks: pdfLinks,
      promoCode: promoCodeParsed,
      promoDiscount: promoDiscountParsed,
      promoAutoApplied: promoAutoAppliedParsed,
      cashbackAmount: cashbackAmountParsed,
      transactionId: (json['transid'] ?? json['trans_id'] ?? '')
          .toString()
          .trim(),
      midRideCancel: midRideCancel,
      cancelTime: (json['cancel_time'] as num?)?.toInt(),
      searchStartedAt: parseDriverSearchStartedAt(json['search_started_at']),
    );
  }

  RideModel copyWith({
    String? id,
    String? riderId,
    String? driverId,
    String? vehicleTypeId,
    String? vehicleKey,
    String? vehicleDisplayName,
    RideStatus? status,
    LocationEntity? pickup,
    LocationEntity? destination,
    List<RideStopModel>? stops,
    bool? isMultiStop,
    int? currentStopIndex,
    int? fareEstimate,
    int? finalFare,
    double? distanceKm,
    int? durationMinutes,
    String? pinCode,
    bool? pinRequired,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    int? cancellationFee,
    int? riderRating,
    bool? showReviewUi,
    FareBreakdownModel? fareBreakdown,
    DriverSnapshotModel? driverSnapshot,
    VehicleSnapshotModel? vehicleSnapshot,
    DateTime? createdAt,
    PendingStopsUpdateModel? pendingStopsUpdate,
    bool? isBookedForOther,
    bool? isBookAny,
    String? passengerName,
    String? passengerPhone,
    List<PdfLinkModel>? pdfLinks,
    String? promoCode,
    int? promoDiscount,
    bool? promoAutoApplied,
    int? cashbackAmount,
    String? transactionId,
    MidRideCancelModel? midRideCancel,
    int? cancelTime,
    DateTime? searchStartedAt,
  }) {
    return RideModel(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
      vehicleKey: vehicleKey ?? this.vehicleKey,
      vehicleDisplayName: vehicleDisplayName ?? this.vehicleDisplayName,
      status: status ?? this.status,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      stops: stops ?? this.stops,
      pinRequired: pinRequired ?? this.pinRequired,
      isMultiStop: isMultiStop ?? this.isMultiStop,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      fareEstimate: fareEstimate ?? this.fareEstimate,
      finalFare: finalFare ?? this.finalFare,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      pinCode: pinCode ?? this.pinCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      cancellationFee: cancellationFee ?? this.cancellationFee,
      riderRating: riderRating ?? this.riderRating,
      showReviewUi: showReviewUi ?? this.showReviewUi,
      fareBreakdown: fareBreakdown ?? this.fareBreakdown,
      driverSnapshot: driverSnapshot ?? this.driverSnapshot,
      vehicleSnapshot: vehicleSnapshot ?? this.vehicleSnapshot,
      createdAt: createdAt ?? this.createdAt,
      pendingStopsUpdate: pendingStopsUpdate ?? this.pendingStopsUpdate,
      isBookedForOther: isBookedForOther ?? this.isBookedForOther,
      isBookAny: isBookAny ?? this.isBookAny,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      pdfLinks: pdfLinks ?? this.pdfLinks,
      promoCode: promoCode ?? this.promoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      promoAutoApplied: promoAutoApplied ?? this.promoAutoApplied,
      cashbackAmount: cashbackAmount ?? this.cashbackAmount,
      transactionId: transactionId ?? this.transactionId,
      midRideCancel: midRideCancel ?? this.midRideCancel,
      cancelTime: cancelTime ?? this.cancelTime,
      searchStartedAt: searchStartedAt ?? this.searchStartedAt,
    );
  }

  static String _toCamelCase(String snakeCase) {
    List<String> words = snakeCase.split('_');
    if (words.length == 1) return words[0];
    return words[0] +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join('');
  }

  static String? _nullableTrimmedString(Object? value) {
    final trimmed = value?.toString().trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class RideStopModel {
  final int index;
  final double lat;
  final double lng;
  final String address;
  final String status;
  final DateTime? arrivedAt;
  final DateTime? completedAt;

  const RideStopModel({
    required this.index,
    required this.lat,
    required this.lng,
    required this.address,
    required this.status,
    this.arrivedAt,
    this.completedAt,
  });

  factory RideStopModel.fromJson(Map<String, dynamic> json) {
    return RideStopModel(
      index: json['index'] ?? 0,
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      status: json['status'] ?? 'pending',
      arrivedAt: json['arrived_at'] != null
          ? DateTime.parse(json['arrived_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}

class DriverSnapshotModel {
  final String name;
  final String phone;
  final String? avatarUrl;
  final double rating;
  final String? verificationCode;
  final String? vehicleRegistrationNumber;
  final String? vehicleModel;
  final String? vehicleType;
  final String? vehicleColor;

  const DriverSnapshotModel({
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.rating,
    this.verificationCode,
    this.vehicleRegistrationNumber,
    this.vehicleModel,
    this.vehicleType,
    this.vehicleColor,
  });

  factory DriverSnapshotModel.fromJson(Map<String, dynamic> json) {
    return DriverSnapshotModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      verificationCode: json['verification_code']?.toString(),
      vehicleRegistrationNumber: json['vehicle_registration_number']
          ?.toString(),
      vehicleModel: json['vehicle_model']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      vehicleColor: json['vehicle_color']?.toString(),
    );
  }
}

class VehicleSnapshotModel {
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String plateNumber;

  const VehicleSnapshotModel({
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.plateNumber,
  });

  factory VehicleSnapshotModel.fromJson(Map<String, dynamic> json) {
    return VehicleSnapshotModel(
      vehicleType:
          json['display_name'] ??
          json['vehicle_name'] ??
          json['vehicle_type'] ??
          '',
      vehicleMake: json['vehicle_make'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleColor: json['vehicle_color'] ?? '',
      plateNumber: json['plate_number'] ?? '',
    );
  }
}

class FareBreakdownModel {
  final int rideCharge;
  final int bookingFee;
  final int totalAmount;
  final String? currency;
  final int? baseFare;
  final double? distanceKm;
  final int? distanceCharge;
  final int? durationMinutes;
  final int? timeCharge;
  final int? waypointCharge;
  final int? minimumFare;
  final bool? minimumFareApplied;
  final int? originalFare;
  final String? promoCode;
  final int? promoDiscount;
  final bool? promoAutoApplied;
  final String? promoDescription;
  final bool? isCashback;
  final int? cashbackAmount;
  final int? amountCharged;

  const FareBreakdownModel({
    required this.rideCharge,
    required this.bookingFee,
    required this.totalAmount,
    this.currency,
    this.baseFare,
    this.distanceKm,
    this.distanceCharge,
    this.durationMinutes,
    this.timeCharge,
    this.waypointCharge,
    this.minimumFare,
    this.minimumFareApplied,
    this.originalFare,
    this.promoCode,
    this.promoDiscount,
    this.promoAutoApplied,
    this.promoDescription,
    this.isCashback,
    this.cashbackAmount,
    this.amountCharged,
  });

  factory FareBreakdownModel.fromJson(Map<String, dynamic> json) {
    return FareBreakdownModel(
      rideCharge: json['ride_charge'] ?? 0,
      bookingFee: json['booking_fee'] ?? 0,
      totalAmount: json['total_amount'] ?? 0,
      currency: json['currency'] ?? '',
      baseFare: json['base_fare'] ?? 0,
      distanceKm: json['distance_km']?.toDouble() ?? 0.0,
      distanceCharge: json['distance_charge'] ?? 0,
      durationMinutes: json['duration_minutes'] ?? 0,
      timeCharge: json['time_charge'] ?? 0,
      waypointCharge: json['waypoint_charge'] ?? 0,
      minimumFare: json['minimum_fare'] ?? 0,
      minimumFareApplied: json['minimum_fare_applied'] ?? false,
      originalFare: json['original_fare'] ?? 0,
      promoCode: json['promo_code'] ?? '',
      promoDiscount: json['promo_discount'] ?? 0,
      promoAutoApplied: json['promo_auto_applied'] ?? false,
      promoDescription: json['promo_description'] ?? '',
      isCashback: json['is_cashback'] ?? false,
      cashbackAmount: json['cashback_amount'] ?? 0,
      amountCharged: json['amount_charged'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'ride_charge': rideCharge,
    'booking_fee': bookingFee,
    'total_amount': totalAmount,
    'currency': currency,
    'base_fare': baseFare,
    'distance_km': distanceKm,
    'distance_charge': distanceCharge,
    'duration_minutes': durationMinutes,
    'time_charge': timeCharge,
    'waypoint_charge': waypointCharge,
    'minimum_fare': minimumFare,
    'minimum_fare_applied': minimumFareApplied,
    'original_fare': originalFare,
    'promo_code': promoCode,
    'promo_discount': promoDiscount,
    'promo_auto_applied': promoAutoApplied,
    'promo_description': promoDescription,
    'is_cashback': isCashback,
    'cashback_amount': cashbackAmount,
    'amount_charged': amountCharged,
  };
}

class PendingStopsUpdateModel {
  final List<RideStopModel> stops;
  final String status;
  final int deltaAmount;
  final String direction;
  final int? newFare;
  final String? validationId;
  final DateTime? expiresAt;
  final String? idempotencyKey;

  const PendingStopsUpdateModel({
    required this.stops,
    required this.status,
    required this.deltaAmount,
    required this.direction,
    this.newFare,
    this.validationId,
    this.expiresAt,
    this.idempotencyKey,
  });

  factory PendingStopsUpdateModel.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List? ?? [];
    final stops = stopsJson.map((e) => RideStopModel.fromJson(e)).toList();

    return PendingStopsUpdateModel(
      stops: stops,
      status: json['status'] ?? '',
      deltaAmount: json['delta_amount'] ?? 0,
      direction: json['direction'] ?? '',
      newFare: json['new_fare'] ?? json['new_fare_estimate'],
      validationId: json['block_update_validation_id'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      idempotencyKey: json['idempotency_key'],
    );
  }
}

class PdfLinkModel {
  final String url;
  final String token;
  final String originalName;
  final DateTime? expiresAt;
  final DateTime? uploadedAt;

  const PdfLinkModel({
    required this.url,
    required this.token,
    required this.originalName,
    this.expiresAt,
    this.uploadedAt,
  });

  factory PdfLinkModel.fromJson(Map<String, dynamic> json) {
    return PdfLinkModel(
      url: json['url'] ?? '',
      token: json['token'] ?? '',
      originalName: json['original_name'] ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'])
          : null,
    );
  }
}
