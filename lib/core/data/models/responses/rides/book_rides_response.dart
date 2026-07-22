import 'dart:convert';

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<String> _stringListFromJson(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString()).toList();
}

Map<String, dynamic>? _mapFromJson(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

List<BookRideStop> _stopsFromJson(dynamic value) {
  if (value is! List) return const [];
  final out = <BookRideStop>[];
  for (final item in value) {
    if (item is Map<String, dynamic>) {
      out.add(BookRideStop.fromJson(item));
    } else if (item is Map) {
      out.add(BookRideStop.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return out;
}

List<BookRidePreauth> _preauthsFromJson(dynamic value) {
  if (value is! List) return const [];
  final out = <BookRidePreauth>[];
  for (final item in value) {
    if (item is Map<String, dynamic>) {
      out.add(BookRidePreauth.fromJson(item));
    } else if (item is Map) {
      out.add(BookRidePreauth.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return out;
}

BookRide? _rideFromDataJson(dynamic value) {
  final map = _mapFromJson(value);
  if (map == null) return null;

  // Support both `{ "ride": { ... } }` and flattened ride document in `data`.
  final nested = map['ride'];
  if (nested is Map<String, dynamic>) {
    return BookRide.fromJson(nested);
  }
  if (nested is Map) {
    return BookRide.fromJson(Map<String, dynamic>.from(nested));
  }
  return BookRide.fromJson(map);
}

class BookRideResponse {
  final int? statusCode;
  final String? message;
  final BookRide? data;

  const BookRideResponse({this.statusCode, this.message, this.data});

  factory BookRideResponse.fromRawJson(String str) =>
      BookRideResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookRideResponse.fromJson(Map<String, dynamic> json) =>
      BookRideResponse(
        statusCode: json['status_code'],
        message: json['message']?.toString(),
        data: _rideFromDataJson(json['data']),
      );

  bool get isSuccess => statusCode == 200 && data != null;

  /// Convenience alias used by booking flow.
  BookRide? get ride => data;

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
    'data': data?.toJson(),
  };
}

class BookRideStop {
  final RideGeoLocation? location;
  final String? status;
  final String? subtaskId;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final int? index;
  final double? lat;
  final double? lng;
  final String? address;

  const BookRideStop({
    this.location,
    this.status,
    this.subtaskId,
    this.arrivedAt,
    this.completedAt,
    this.index,
    this.lat,
    this.lng,
    this.address,
  });

  factory BookRideStop.fromRawJson(String str) =>
      BookRideStop.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookRideStop.fromJson(Map<String, dynamic> json) => BookRideStop(
    location: json['location'] == null
        ? null
        : RideGeoLocation.fromJson(json['location']),
    status: json['status']?.toString(),
    subtaskId: json['subtask_id']?.toString(),
    arrivedAt: _dateTimeFromJson(json['arrived_at']),
    completedAt: _dateTimeFromJson(json['completed_at']),
    index: (json['index'] as num?)?.toInt(),
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    address: json['address']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'location': location?.toJson(),
    'status': status,
    'subtask_id': subtaskId,
    'arrived_at': arrivedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'index': index,
    'lat': lat,
    'lng': lng,
    'address': address,
  };
}

class BookRide {
  final FareBreakdown? fareBreakdown;
  final dynamic driverId;
  final dynamic taskId;
  final String? status;
  final bool? isMultiStop;
  final bool? isBookAny;
  final List<String> bookAnyVehicleTypeIds;
  final int? bookAnyBlockAmount;
  final DateTime? bookAnyResolvedAt;
  final int? currentStopIndex;
  final List<BookRideStop> stops;
  final dynamic finalFare;
  final int? additionalFare;
  final String? pinCode;
  final bool? pinRequired;
  final int? pinAttempts;
  final DateTime? pinLockedUntil;
  final dynamic subOrderHistoryId;
  final String? paymentStatus;
  final int? blockedAmount;
  final String? blockValidationId;
  final dynamic blockTransid;
  final int? preauthTotal;
  final int? captureTotal;
  final int? cancellationFeeCaptured;
  final dynamic promoCode;
  final int? promoDiscount;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final int? cancellationFee;
  final Map<String, dynamic>? midRideCancel;
  final List<String> rejectedDrivers;
  final List<String> blockedDrivers;
  final dynamic driverSnapshot;
  final dynamic vehicleSnapshot;
  final DateTime? driverAssignedAt;
  final DateTime? driverArrivedAt;
  final DateTime? rideStartedAt;
  final DateTime? rideCompletedAt;
  final num? riderRating;
  final String? riderRatingComment;
  final DateTime? ratedAt;
  final num? driverRating;
  final String? driverRatingComment;
  final DateTime? driverRatedAt;
  final String? feedbackText;
  final List<String> feedbackTags;
  final List<String> feedbackImages;
  final DateTime? feedbackAt;
  final List<String> ratingTags;
  final bool? isReviewSkipped;
  final String? iosActivityToken;
  final String? shareToken;
  final DateTime? shareLinkExpiresAt;
  final bool? isShared;
  final String? note;
  final Map<String, dynamic>? pendingStopsUpdate;
  final bool? isBookedForOther;
  final String? passengerName;
  final String? passengerPhone;
  final String? latraReferenceNumber;
  final DateTime? latraSubmittedAt;
  final String? id;
  final String? riderId;
  final String? vehicleTypeId;
  final String? transid;
  final BookRidePlace? pickup;
  final BookRidePlace? destination;
  final int? fareEstimate;
  final double? distanceKm;
  final int? durationMinutes;
  final String? idempotencyKey;
  final String? paymentMethod;
  final DateTime? searchStartedAt;
  final List<BookRidePreauth> preauths;
  final List<String> pdfLinks;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final int? cancelTime;

  const BookRide({
    this.fareBreakdown,
    this.driverId,
    this.taskId,
    this.status,
    this.isMultiStop,
    this.isBookAny,
    this.bookAnyVehicleTypeIds = const [],
    this.bookAnyBlockAmount,
    this.bookAnyResolvedAt,
    this.currentStopIndex,
    this.stops = const [],
    this.finalFare,
    this.additionalFare,
    this.pinCode,
    this.pinRequired,
    this.pinAttempts,
    this.pinLockedUntil,
    this.subOrderHistoryId,
    this.paymentStatus,
    this.blockedAmount,
    this.blockValidationId,
    this.blockTransid,
    this.preauthTotal,
    this.captureTotal,
    this.cancellationFeeCaptured,
    this.promoCode,
    this.promoDiscount,
    this.cancelledAt,
    this.cancellationReason,
    this.cancellationFee,
    this.midRideCancel,
    this.rejectedDrivers = const [],
    this.blockedDrivers = const [],
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.driverAssignedAt,
    this.driverArrivedAt,
    this.rideStartedAt,
    this.rideCompletedAt,
    this.riderRating,
    this.riderRatingComment,
    this.ratedAt,
    this.driverRating,
    this.driverRatingComment,
    this.driverRatedAt,
    this.feedbackText,
    this.feedbackTags = const [],
    this.feedbackImages = const [],
    this.feedbackAt,
    this.ratingTags = const [],
    this.isReviewSkipped,
    this.iosActivityToken,
    this.shareToken,
    this.shareLinkExpiresAt,
    this.isShared,
    this.note,
    this.pendingStopsUpdate,
    this.isBookedForOther,
    this.passengerName,
    this.passengerPhone,
    this.latraReferenceNumber,
    this.latraSubmittedAt,
    this.id,
    this.riderId,
    this.vehicleTypeId,
    this.transid,
    this.pickup,
    this.destination,
    this.fareEstimate,
    this.distanceKm,
    this.durationMinutes,
    this.idempotencyKey,
    this.paymentMethod,
    this.searchStartedAt,
    this.preauths = const [],
    this.pdfLinks = const [],
    this.createdAt,
    this.updatedAt,
    this.v,
    this.cancelTime,
  });

  factory BookRide.fromRawJson(String str) =>
      BookRide.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookRide.fromJson(Map<String, dynamic> json) => BookRide(
    fareBreakdown: json['fare_breakdown'] == null
        ? null
        : FareBreakdown.fromJson(json['fare_breakdown']),
    driverId: json['driver_id'],
    taskId: json['task_id'],
    status: json['status']?.toString(),
    isMultiStop: json['is_multi_stop'] as bool?,
    isBookAny: json['is_book_any'] as bool?,
    bookAnyVehicleTypeIds: _stringListFromJson(json['book_any_vehicle_type_ids']),
    bookAnyBlockAmount: (json['book_any_block_amount'] as num?)?.toInt(),
    bookAnyResolvedAt: _dateTimeFromJson(json['book_any_resolved_at']),
    currentStopIndex: (json['current_stop_index'] as num?)?.toInt(),
    stops: _stopsFromJson(json['stops']),
    finalFare: json['final_fare'],
    additionalFare: (json['additional_fare'] as num?)?.toInt(),
    pinCode: json['pin_code']?.toString(),
    pinRequired: json['pin_required'] as bool?,
    pinAttempts: (json['pin_attempts'] as num?)?.toInt(),
    pinLockedUntil: _dateTimeFromJson(json['pin_locked_until']),
    subOrderHistoryId: json['sub_order_history_id'],
    paymentStatus: json['payment_status']?.toString(),
    blockedAmount: (json['blocked_amount'] as num?)?.toInt(),
    blockValidationId: json['block_validation_id']?.toString(),
    blockTransid: json['block_transid'],
    preauthTotal: (json['preauth_total'] as num?)?.toInt(),
    captureTotal: (json['capture_total'] as num?)?.toInt(),
    cancellationFeeCaptured: (json['cancellation_fee_captured'] as num?)?.toInt(),
    promoCode: json['promo_code'],
    promoDiscount: (json['promo_discount'] as num?)?.toInt(),
    cancelledAt: _dateTimeFromJson(json['cancelled_at']),
    cancellationReason: json['cancellation_reason']?.toString(),
    cancellationFee: (json['cancellation_fee'] as num?)?.toInt(),
    midRideCancel: _mapFromJson(json['mid_ride_cancel']),
    rejectedDrivers: _stringListFromJson(json['rejected_drivers']),
    blockedDrivers: _stringListFromJson(json['blocked_drivers']),
    driverSnapshot: json['driver_snapshot'],
    vehicleSnapshot: json['vehicle_snapshot'],
    driverAssignedAt: _dateTimeFromJson(json['driver_assigned_at']),
    driverArrivedAt: _dateTimeFromJson(json['driver_arrived_at']),
    rideStartedAt: _dateTimeFromJson(json['ride_started_at']),
    rideCompletedAt: _dateTimeFromJson(json['ride_completed_at']),
    riderRating: json['rider_rating'] as num?,
    riderRatingComment: json['rider_rating_comment']?.toString(),
    ratedAt: _dateTimeFromJson(json['rated_at']),
    driverRating: json['driver_rating'] as num?,
    driverRatingComment: json['driver_rating_comment']?.toString(),
    driverRatedAt: _dateTimeFromJson(json['driver_rated_at']),
    feedbackText: json['feedback_text']?.toString(),
    feedbackTags: _stringListFromJson(json['feedback_tags']),
    feedbackImages: _stringListFromJson(json['feedback_images']),
    feedbackAt: _dateTimeFromJson(json['feedback_at']),
    ratingTags: _stringListFromJson(json['rating_tags']),
    isReviewSkipped: json['is_review_skipped'] as bool?,
    iosActivityToken: json['ios_activity_token']?.toString(),
    shareToken: json['share_token']?.toString(),
    shareLinkExpiresAt: _dateTimeFromJson(json['share_link_expires_at']),
    isShared: json['is_shared'] as bool?,
    note: json['note']?.toString(),
    pendingStopsUpdate: _mapFromJson(json['pending_stops_update']),
    isBookedForOther: json['is_booked_for_other'] as bool?,
    passengerName: json['passenger_name']?.toString(),
    passengerPhone: json['passenger_phone']?.toString(),
    latraReferenceNumber: json['latra_reference_number']?.toString(),
    latraSubmittedAt: _dateTimeFromJson(json['latra_submitted_at']),
    id: json['_id']?.toString(),
    riderId: json['rider_id']?.toString(),
    vehicleTypeId: json['vehicle_type_id']?.toString(),
    transid: json['transid']?.toString(),
    pickup: json['pickup'] == null
        ? null
        : BookRidePlace.fromJson(json['pickup']),
    destination: json['destination'] == null
        ? null
        : BookRidePlace.fromJson(json['destination']),
    fareEstimate: (json['fare_estimate'] as num?)?.toInt(),
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
    durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
    idempotencyKey: json['idempotency_key']?.toString(),
    paymentMethod: json['payment_method']?.toString(),
    searchStartedAt: _dateTimeFromJson(json['search_started_at']),
    preauths: _preauthsFromJson(json['preauths']),
    pdfLinks: _stringListFromJson(json['pdf_links']),
    createdAt: _dateTimeFromJson(json['createdAt']),
    updatedAt: _dateTimeFromJson(json['updatedAt']),
    v: (json['__v'] as num?)?.toInt(),
    cancelTime: (json['cancel_time'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'fare_breakdown': fareBreakdown?.toJson(),
    'driver_id': driverId,
    'task_id': taskId,
    'status': status,
    'is_multi_stop': isMultiStop,
    'is_book_any': isBookAny,
    'book_any_vehicle_type_ids': bookAnyVehicleTypeIds,
    'book_any_block_amount': bookAnyBlockAmount,
    'book_any_resolved_at': bookAnyResolvedAt?.toIso8601String(),
    'current_stop_index': currentStopIndex,
    'stops': stops.map((x) => x.toJson()).toList(),
    'final_fare': finalFare,
    'additional_fare': additionalFare,
    'pin_code': pinCode,
    'pin_required': pinRequired,
    'pin_attempts': pinAttempts,
    'pin_locked_until': pinLockedUntil?.toIso8601String(),
    'sub_order_history_id': subOrderHistoryId,
    'payment_status': paymentStatus,
    'blocked_amount': blockedAmount,
    'block_validation_id': blockValidationId,
    'block_transid': blockTransid,
    'preauth_total': preauthTotal,
    'capture_total': captureTotal,
    'cancellation_fee_captured': cancellationFeeCaptured,
    'promo_code': promoCode,
    'promo_discount': promoDiscount,
    'cancelled_at': cancelledAt?.toIso8601String(),
    'cancellation_reason': cancellationReason,
    'cancellation_fee': cancellationFee,
    'mid_ride_cancel': midRideCancel,
    'rejected_drivers': rejectedDrivers,
    'blocked_drivers': blockedDrivers,
    'driver_snapshot': driverSnapshot,
    'vehicle_snapshot': vehicleSnapshot,
    'driver_assigned_at': driverAssignedAt?.toIso8601String(),
    'driver_arrived_at': driverArrivedAt?.toIso8601String(),
    'ride_started_at': rideStartedAt?.toIso8601String(),
    'ride_completed_at': rideCompletedAt?.toIso8601String(),
    'rider_rating': riderRating,
    'rider_rating_comment': riderRatingComment,
    'rated_at': ratedAt?.toIso8601String(),
    'driver_rating': driverRating,
    'driver_rating_comment': driverRatingComment,
    'driver_rated_at': driverRatedAt?.toIso8601String(),
    'feedback_text': feedbackText,
    'feedback_tags': feedbackTags,
    'feedback_images': feedbackImages,
    'feedback_at': feedbackAt?.toIso8601String(),
    'rating_tags': ratingTags,
    'is_review_skipped': isReviewSkipped,
    'ios_activity_token': iosActivityToken,
    'share_token': shareToken,
    'share_link_expires_at': shareLinkExpiresAt?.toIso8601String(),
    'is_shared': isShared,
    'note': note,
    'pending_stops_update': pendingStopsUpdate,
    'is_booked_for_other': isBookedForOther,
    'passenger_name': passengerName,
    'passenger_phone': passengerPhone,
    'latra_reference_number': latraReferenceNumber,
    'latra_submitted_at': latraSubmittedAt?.toIso8601String(),
    '_id': id,
    'rider_id': riderId,
    'vehicle_type_id': vehicleTypeId,
    'transid': transid,
    'pickup': pickup?.toJson(),
    'destination': destination?.toJson(),
    'fare_estimate': fareEstimate,
    'distance_km': distanceKm,
    'duration_minutes': durationMinutes,
    'idempotency_key': idempotencyKey,
    'payment_method': paymentMethod,
    'search_started_at': searchStartedAt?.toIso8601String(),
    'preauths': preauths.map((x) => x.toJson()).toList(),
    'pdf_links': pdfLinks,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    '__v': v,
    'cancel_time': cancelTime,
  };
}

class FareBreakdown {
  final int? rideCharge;
  final int? bookingFee;
  final int? totalAmount;
  final String? promoCode;
  final int? promoDiscount;

  const FareBreakdown({
    this.rideCharge,
    this.bookingFee,
    this.totalAmount,
    this.promoCode,
    this.promoDiscount,
  });

  factory FareBreakdown.fromRawJson(String str) =>
      FareBreakdown.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FareBreakdown.fromJson(Map<String, dynamic> json) => FareBreakdown(
    rideCharge: (json['ride_charge'] as num?)?.toInt(),
    bookingFee: (json['booking_fee'] as num?)?.toInt(),
    totalAmount: (json['total_amount'] as num?)?.toInt(),
    promoCode: json['promo_code']?.toString(),
    promoDiscount: (json['promo_discount'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'ride_charge': rideCharge,
    'booking_fee': bookingFee,
    'total_amount': totalAmount,
    'promo_code': promoCode,
    'promo_discount': promoDiscount,
  };
}

class BookRidePlace {
  final RideGeoLocation? location;
  final double? lat;
  final double? lng;
  final String? address;
  final int? index;
  final String? status;
  final String? subtaskId;
  final DateTime? arrivedAt;
  final DateTime? completedAt;

  const BookRidePlace({
    this.location,
    this.lat,
    this.lng,
    this.address,
    this.index,
    this.status,
    this.subtaskId,
    this.arrivedAt,
    this.completedAt,
  });

  factory BookRidePlace.fromRawJson(String str) =>
      BookRidePlace.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookRidePlace.fromJson(Map<String, dynamic> json) => BookRidePlace(
    location: json['location'] == null
        ? null
        : RideGeoLocation.fromJson(json['location']),
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    address: json['address']?.toString(),
    index: (json['index'] as num?)?.toInt(),
    status: json['status']?.toString(),
    subtaskId: json['subtask_id']?.toString(),
    arrivedAt: _dateTimeFromJson(json['arrived_at']),
    completedAt: _dateTimeFromJson(json['completed_at']),
  );

  Map<String, dynamic> toJson() => {
    'location': location?.toJson(),
    'lat': lat,
    'lng': lng,
    'address': address,
    'index': index,
    'status': status,
    'subtask_id': subtaskId,
    'arrived_at': arrivedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };
}

/// GeoJSON point used inside book-ride pickup/destination/stops.
class RideGeoLocation {
  final String? type;
  final List<double>? coordinates;

  const RideGeoLocation({this.type, this.coordinates});

  factory RideGeoLocation.fromRawJson(String str) =>
      RideGeoLocation.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory RideGeoLocation.fromJson(Map<String, dynamic> json) =>
      RideGeoLocation(
        type: json['type']?.toString(),
        coordinates: json['coordinates'] == null
            ? const []
            : List<double>.from(
                json['coordinates'].map((x) => (x as num).toDouble()),
              ),
      );

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}

class BookRidePreauth {
  final String? reference;
  final String? status;
  final String? idempotencyKey;
  final String? captureTransid;
  final String? captureReference;
  final int? capturedAmount;
  final String? reverseTransid;
  final String? reverseReference;
  final String? obal;
  final String? cbal;
  final Map<String, dynamic>? rawResponse;
  final Map<String, dynamic>? captureResponse;
  final DateTime? settledAt;
  final String? transid;
  final int? amount;
  final String? type;
  final DateTime? createdAt;

  const BookRidePreauth({
    this.reference,
    this.status,
    this.idempotencyKey,
    this.captureTransid,
    this.captureReference,
    this.capturedAmount,
    this.reverseTransid,
    this.reverseReference,
    this.obal,
    this.cbal,
    this.rawResponse,
    this.captureResponse,
    this.settledAt,
    this.transid,
    this.amount,
    this.type,
    this.createdAt,
  });

  factory BookRidePreauth.fromRawJson(String str) =>
      BookRidePreauth.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookRidePreauth.fromJson(Map<String, dynamic> json) =>
      BookRidePreauth(
        reference: json['reference']?.toString(),
        status: json['status']?.toString(),
        idempotencyKey: json['idempotency_key']?.toString(),
        captureTransid: json['capture_transid']?.toString(),
        captureReference: json['capture_reference']?.toString(),
        capturedAmount: (json['captured_amount'] as num?)?.toInt(),
        reverseTransid: json['reverse_transid']?.toString(),
        reverseReference: json['reverse_reference']?.toString(),
        obal: json['obal']?.toString(),
        cbal: json['cbal']?.toString(),
        rawResponse: _mapFromJson(json['raw_response']),
        captureResponse: _mapFromJson(json['capture_response']),
        settledAt: _dateTimeFromJson(json['settled_at']),
        transid: json['transid']?.toString(),
        amount: (json['amount'] as num?)?.toInt(),
        type: json['type']?.toString(),
        createdAt: _dateTimeFromJson(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'status': status,
    'idempotency_key': idempotencyKey,
    'capture_transid': captureTransid,
    'capture_reference': captureReference,
    'captured_amount': capturedAmount,
    'reverse_transid': reverseTransid,
    'reverse_reference': reverseReference,
    'obal': obal,
    'cbal': cbal,
    'raw_response': rawResponse,
    'capture_response': captureResponse,
    'settled_at': settledAt?.toIso8601String(),
    'transid': transid,
    'amount': amount,
    'type': type,
    'created_at': createdAt?.toIso8601String(),
  };
}

/// Backward-compatible aliases for older call sites / generated names.
typedef Destination = BookRidePlace;
typedef Location = RideGeoLocation;
