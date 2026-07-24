import 'dart:convert';

/// Envelope for book-ride API (from `model/model.dart`).
class BookRideResponse {
  int? statusCode;
  String? message;
  BookRide? data;

  BookRideResponse({this.statusCode, this.message, this.data});

  factory BookRideResponse.fromJson(dynamic json) {
    if (json is String) {
      return BookRideResponse.fromMap(jsonDecode(json) as Map<String, dynamic>);
    }
    if (json is Map<String, dynamic>) {
      return BookRideResponse.fromMap(json);
    }
    if (json is Map) {
      return BookRideResponse.fromMap(Map<String, dynamic>.from(json));
    }
    throw ArgumentError(
      'Unsupported BookRideResponse JSON: ${json.runtimeType}',
    );
  }

  String toJsonString() => json.encode(toMap());

  factory BookRideResponse.fromMap(Map<String, dynamic> json) =>
      BookRideResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null ? null : BookRide.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };

  /// Convenience alias used by booking flow (call-site compatible).
  BookRide? get ride => data;
}

class BookRide {
  BookRideFareBreakdown? fareBreakdown;
  dynamic driverId;
  dynamic taskId;
  String? status;
  bool? isMultiStop;
  bool? isBookAny;
  List<String>? bookAnyVehicleTypeIds;
  int? bookAnyBlockAmount;
  DateTime? bookAnyResolvedAt;
  int? currentStopIndex;
  dynamic finalFare;
  int? additionalFare;
  String? pinCode;
  bool? pinRequired;
  int? pinAttempts;
  DateTime? pinLockedUntil;
  dynamic subOrderHistoryId;
  String? paymentStatus;
  int? blockedAmount;
  String? blockValidationId;
  dynamic blockTransid;
  int? preauthTotal;
  int? captureTotal;
  int? cancellationFeeCaptured;
  String? promoCode;
  int? promoDiscount;
  bool? promoAutoApplied;
  int? cashbackAmount;
  DateTime? cancelledAt;
  String? cancellationReason;
  int? cancellationFee;
  Map<String, dynamic>? midRideCancel;
  List<String>? rejectedDrivers;
  List<String>? blockedDrivers;
  dynamic driverSnapshot;
  dynamic vehicleSnapshot;
  DateTime? driverAssignedAt;
  DateTime? driverArrivedAt;
  DateTime? rideStartedAt;
  DateTime? rideCompletedAt;
  num? riderRating;
  String? riderRatingComment;
  DateTime? ratedAt;
  num? driverRating;
  String? driverRatingComment;
  DateTime? driverRatedAt;
  String? feedbackText;
  List<String>? feedbackTags;
  List<String>? feedbackImages;
  DateTime? feedbackAt;
  List<String>? ratingTags;
  bool? isReviewSkipped;
  String? iosActivityToken;
  String? shareToken;
  DateTime? shareLinkExpiresAt;
  bool? isShared;
  String? note;
  Map<String, dynamic>? pendingStopsUpdate;
  bool? isBookedForOther;
  String? passengerName;
  String? passengerPhone;
  String? latraReferenceNumber;
  DateTime? latraSubmittedAt;
  String? id;
  String? riderId;
  String? vehicleTypeId;
  String? transid;
  BookRidePickup? pickup;
  BookRidePlace? destination;
  List<BookRidePlace>? stops;
  int? fareEstimate;
  double? distanceKm;
  int? durationMinutes;
  String? idempotencyKey;
  String? paymentMethod;
  DateTime? searchStartedAt;
  List<BookRidePreauth>? preauths;
  List<String>? pdfLinks;
  String? createdAt;
  String? updatedAt;
  int? v;
  int? cancelTime;

  BookRide({
    this.fareBreakdown,
    this.driverId,
    this.taskId,
    this.status,
    this.isMultiStop,
    this.isBookAny,
    this.bookAnyVehicleTypeIds,
    this.bookAnyBlockAmount,
    this.bookAnyResolvedAt,
    this.currentStopIndex,
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
    this.promoAutoApplied,
    this.cashbackAmount,
    this.cancelledAt,
    this.cancellationReason,
    this.cancellationFee,
    this.midRideCancel,
    this.rejectedDrivers,
    this.blockedDrivers,
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
    this.feedbackTags,
    this.feedbackImages,
    this.feedbackAt,
    this.ratingTags,
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
    this.stops,
    this.fareEstimate,
    this.distanceKm,
    this.durationMinutes,
    this.idempotencyKey,
    this.paymentMethod,
    this.searchStartedAt,
    this.preauths,
    this.pdfLinks,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.cancelTime,
  });

  factory BookRide.fromJson(String str) => BookRide.fromMap(json.decode(str));

  String toJsonString() => json.encode(toMap());

  factory BookRide.fromMap(Map<String, dynamic> json) => BookRide(
    fareBreakdown: json["fare_breakdown"] == null
        ? null
        : BookRideFareBreakdown.fromMap(json["fare_breakdown"]),
    driverId: json["driver_id"],
    taskId: json["task_id"],
    status: json["status"],
    isMultiStop: json["is_multi_stop"],
    isBookAny: json["is_book_any"],
    bookAnyVehicleTypeIds: json["book_any_vehicle_type_ids"] == null
        ? []
        : List<String>.from(json["book_any_vehicle_type_ids"]!.map((x) => x)),
    bookAnyBlockAmount: json["book_any_block_amount"],
    bookAnyResolvedAt: json["book_any_resolved_at"] == null
        ? null
        : DateTime.parse(json["book_any_resolved_at"]),
    currentStopIndex: json["current_stop_index"],
    finalFare: json["final_fare"],
    additionalFare: json["additional_fare"],
    pinCode: json["pin_code"],
    pinRequired: json["pin_required"],
    pinAttempts: json["pin_attempts"],
    pinLockedUntil: json["pin_locked_until"] == null
        ? null
        : DateTime.parse(json["pin_locked_until"]),
    subOrderHistoryId: json["sub_order_history_id"],
    paymentStatus: json["payment_status"],
    blockedAmount: json["blocked_amount"],
    blockValidationId: json["block_validation_id"],
    blockTransid: json["block_transid"],
    preauthTotal: json["preauth_total"],
    captureTotal: json["capture_total"],
    cancellationFeeCaptured: json["cancellation_fee_captured"],
    promoCode: json["promo_code"],
    promoDiscount: json["promo_discount"],
    promoAutoApplied: json["promo_auto_applied"],
    cashbackAmount: json["cashback_amount"],
    cancelledAt: json["cancelled_at"] == null
        ? null
        : DateTime.parse(json["cancelled_at"]),
    cancellationReason: json["cancellation_reason"],
    cancellationFee: json["cancellation_fee"],
    midRideCancel: json["mid_ride_cancel"] == null
        ? null
        : Map<String, dynamic>.from(json["mid_ride_cancel"]),
    rejectedDrivers: json["rejected_drivers"] == null
        ? []
        : List<String>.from(json["rejected_drivers"]!.map((x) => x)),
    blockedDrivers: json["blocked_drivers"] == null
        ? []
        : List<String>.from(json["blocked_drivers"]!.map((x) => x)),
    driverSnapshot: json["driver_snapshot"],
    vehicleSnapshot: json["vehicle_snapshot"],
    driverAssignedAt: json["driver_assigned_at"] == null
        ? null
        : DateTime.parse(json["driver_assigned_at"]),
    driverArrivedAt: json["driver_arrived_at"] == null
        ? null
        : DateTime.parse(json["driver_arrived_at"]),
    rideStartedAt: json["ride_started_at"] == null
        ? null
        : DateTime.parse(json["ride_started_at"]),
    rideCompletedAt: json["ride_completed_at"] == null
        ? null
        : DateTime.parse(json["ride_completed_at"]),
    riderRating: json["rider_rating"],
    riderRatingComment: json["rider_rating_comment"],
    ratedAt: json["rated_at"] == null ? null : DateTime.parse(json["rated_at"]),
    driverRating: json["driver_rating"],
    driverRatingComment: json["driver_rating_comment"],
    driverRatedAt: json["driver_rated_at"] == null
        ? null
        : DateTime.parse(json["driver_rated_at"]),
    feedbackText: json["feedback_text"],
    feedbackTags: json["feedback_tags"] == null
        ? []
        : List<String>.from(json["feedback_tags"]!.map((x) => x)),
    feedbackImages: json["feedback_images"] == null
        ? []
        : List<String>.from(json["feedback_images"]!.map((x) => x)),
    feedbackAt: json["feedback_at"] == null
        ? null
        : DateTime.parse(json["feedback_at"]),
    ratingTags: json["rating_tags"] == null
        ? []
        : List<String>.from(json["rating_tags"]!.map((x) => x)),
    isReviewSkipped: json["is_review_skipped"],
    iosActivityToken: json["ios_activity_token"],
    shareToken: json["share_token"],
    shareLinkExpiresAt: json["share_link_expires_at"] == null
        ? null
        : DateTime.parse(json["share_link_expires_at"]),
    isShared: json["is_shared"],
    note: json["note"],
    pendingStopsUpdate: json["pending_stops_update"] == null
        ? null
        : Map<String, dynamic>.from(json["pending_stops_update"]),
    isBookedForOther: json["is_booked_for_other"],
    passengerName: json["passenger_name"],
    passengerPhone: json["passenger_phone"],
    latraReferenceNumber: json["latra_reference_number"],
    latraSubmittedAt: json["latra_submitted_at"] == null
        ? null
        : DateTime.parse(json["latra_submitted_at"]),
    id: json["_id"],
    riderId: json["rider_id"],
    vehicleTypeId: json["vehicle_type_id"],
    transid: json["transid"],
    pickup: json["pickup"] == null
        ? null
        : BookRidePickup.fromMap(json["pickup"]),
    destination: json["destination"] == null
        ? null
        : BookRidePlace.fromMap(json["destination"]),
    stops: json["stops"] == null
        ? []
        : List<BookRidePlace>.from(
            json["stops"]!.map((x) => BookRidePlace.fromMap(x)),
          ),
    fareEstimate: json["fare_estimate"],
    distanceKm: json["distance_km"]?.toDouble(),
    durationMinutes: json["duration_minutes"],
    idempotencyKey: json["idempotency_key"],
    paymentMethod: json["payment_method"],
    searchStartedAt: json["search_started_at"] == null
        ? null
        : DateTime.parse(json["search_started_at"]),
    preauths: json["preauths"] == null
        ? []
        : List<BookRidePreauth>.from(
            json["preauths"]!.map((x) => BookRidePreauth.fromMap(x)),
          ),
    pdfLinks: json["pdf_links"] == null
        ? []
        : List<String>.from(json["pdf_links"]!.map((x) => x)),
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    v: json["__v"],
    cancelTime: json["cancel_time"],
  );

  Map<String, dynamic> toMap() => {
    "fare_breakdown": fareBreakdown?.toMap(),
    "driver_id": driverId,
    "task_id": taskId,
    "status": status,
    "is_multi_stop": isMultiStop,
    "is_book_any": isBookAny,
    "book_any_vehicle_type_ids": bookAnyVehicleTypeIds == null
        ? []
        : List<dynamic>.from(bookAnyVehicleTypeIds!.map((x) => x)),
    "book_any_block_amount": bookAnyBlockAmount,
    "book_any_resolved_at": bookAnyResolvedAt?.toIso8601String(),
    "current_stop_index": currentStopIndex,
    "final_fare": finalFare,
    "additional_fare": additionalFare,
    "pin_code": pinCode,
    "pin_required": pinRequired,
    "pin_attempts": pinAttempts,
    "pin_locked_until": pinLockedUntil?.toIso8601String(),
    "sub_order_history_id": subOrderHistoryId,
    "payment_status": paymentStatus,
    "blocked_amount": blockedAmount,
    "block_validation_id": blockValidationId,
    "block_transid": blockTransid,
    "preauth_total": preauthTotal,
    "capture_total": captureTotal,
    "cancellation_fee_captured": cancellationFeeCaptured,
    "promo_code": promoCode,
    "promo_discount": promoDiscount,
    "promo_auto_applied": promoAutoApplied,
    "cashback_amount": cashbackAmount,
    "cancelled_at": cancelledAt?.toIso8601String(),
    "cancellation_reason": cancellationReason,
    "cancellation_fee": cancellationFee,
    "mid_ride_cancel": midRideCancel,
    "rejected_drivers": rejectedDrivers == null
        ? []
        : List<dynamic>.from(rejectedDrivers!.map((x) => x)),
    "blocked_drivers": blockedDrivers == null
        ? []
        : List<dynamic>.from(blockedDrivers!.map((x) => x)),
    "driver_snapshot": driverSnapshot,
    "vehicle_snapshot": vehicleSnapshot,
    "driver_assigned_at": driverAssignedAt?.toIso8601String(),
    "driver_arrived_at": driverArrivedAt?.toIso8601String(),
    "ride_started_at": rideStartedAt?.toIso8601String(),
    "ride_completed_at": rideCompletedAt?.toIso8601String(),
    "rider_rating": riderRating,
    "rider_rating_comment": riderRatingComment,
    "rated_at": ratedAt?.toIso8601String(),
    "driver_rating": driverRating,
    "driver_rating_comment": driverRatingComment,
    "driver_rated_at": driverRatedAt?.toIso8601String(),
    "feedback_text": feedbackText,
    "feedback_tags": feedbackTags == null
        ? []
        : List<dynamic>.from(feedbackTags!.map((x) => x)),
    "feedback_images": feedbackImages == null
        ? []
        : List<dynamic>.from(feedbackImages!.map((x) => x)),
    "feedback_at": feedbackAt?.toIso8601String(),
    "rating_tags": ratingTags == null
        ? []
        : List<dynamic>.from(ratingTags!.map((x) => x)),
    "is_review_skipped": isReviewSkipped,
    "ios_activity_token": iosActivityToken,
    "share_token": shareToken,
    "share_link_expires_at": shareLinkExpiresAt?.toIso8601String(),
    "is_shared": isShared,
    "note": note,
    "pending_stops_update": pendingStopsUpdate,
    "is_booked_for_other": isBookedForOther,
    "passenger_name": passengerName,
    "passenger_phone": passengerPhone,
    "latra_reference_number": latraReferenceNumber,
    "latra_submitted_at": latraSubmittedAt?.toIso8601String(),
    "_id": id,
    "rider_id": riderId,
    "vehicle_type_id": vehicleTypeId,
    "transid": transid,
    "pickup": pickup?.toMap(),
    "destination": destination?.toMap(),
    "stops": stops == null
        ? []
        : List<dynamic>.from(stops!.map((x) => x.toMap())),
    "fare_estimate": fareEstimate,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
    "idempotency_key": idempotencyKey,
    "payment_method": paymentMethod,
    "search_started_at": searchStartedAt?.toIso8601String(),
    "preauths": preauths == null
        ? []
        : List<dynamic>.from(preauths!.map((x) => x.toMap())),
    "pdf_links": pdfLinks == null
        ? []
        : List<dynamic>.from(pdfLinks!.map((x) => x)),
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": v,
    "cancel_time": cancelTime,
  };
}

class BookRidePlace {
  BookRideLocation? location;
  int? index;
  String? status;
  String? subtaskId;
  DateTime? arrivedAt;
  DateTime? completedAt;
  double? lat;
  double? lng;
  String? address;

  BookRidePlace({
    this.location,
    this.index,
    this.status,
    this.subtaskId,
    this.arrivedAt,
    this.completedAt,
    this.lat,
    this.lng,
    this.address,
  });

  factory BookRidePlace.fromJson(String str) =>
      BookRidePlace.fromMap(json.decode(str));

  String toJsonString() => json.encode(toMap());

  factory BookRidePlace.fromMap(Map<String, dynamic> json) => BookRidePlace(
    location: json["location"] == null
        ? null
        : BookRideLocation.fromMap(json["location"]),
    index: json["index"],
    status: json["status"],
    subtaskId: json["subtask_id"],
    arrivedAt: json["arrived_at"] == null
        ? null
        : DateTime.parse(json["arrived_at"]),
    completedAt: json["completed_at"] == null
        ? null
        : DateTime.parse(json["completed_at"]),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toMap() => {
    "location": location?.toMap(),
    "index": index,
    "status": status,
    "subtask_id": subtaskId,
    "arrived_at": arrivedAt?.toIso8601String(),
    "completed_at": completedAt?.toIso8601String(),
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class BookRideLocation {
  String? type;
  List<double>? coordinates;

  BookRideLocation({this.type, this.coordinates});

  factory BookRideLocation.fromJson(String str) =>
      BookRideLocation.fromMap(json.decode(str));

  String toJsonString() => json.encode(toMap());

  factory BookRideLocation.fromMap(Map<String, dynamic> json) =>
      BookRideLocation(
        type: json["type"],
        coordinates: json["coordinates"] == null
            ? []
            : List<double>.from(json["coordinates"]!.map((x) => x?.toDouble())),
      );

  Map<String, dynamic> toMap() => {
    "type": type,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}

class BookRideFareBreakdown {
  int? rideCharge;
  int? bookingFee;
  int? totalAmount;
  String? promoCode;
  int? promoDiscount;

  BookRideFareBreakdown({
    this.rideCharge,
    this.bookingFee,
    this.totalAmount,
    this.promoCode,
    this.promoDiscount,
  });

  factory BookRideFareBreakdown.fromJson(String str) =>
      BookRideFareBreakdown.fromMap(json.decode(str));

  /// Call sites use `fareBreakdown?.toJson()` expecting a Map.
  Map<String, dynamic> toJson() => toMap();

  String toJsonString() => json.encode(toMap());

  factory BookRideFareBreakdown.fromMap(Map<String, dynamic> json) =>
      BookRideFareBreakdown(
        rideCharge: json["ride_charge"],
        bookingFee: json["booking_fee"],
        totalAmount: json["total_amount"],
        promoCode: json["promo_code"],
        promoDiscount: json["promo_discount"],
      );

  Map<String, dynamic> toMap() => {
    "ride_charge": rideCharge,
    "booking_fee": bookingFee,
    "total_amount": totalAmount,
    "promo_code": promoCode,
    "promo_discount": promoDiscount,
  };
}

/// Alias kept for existing typed references.
typedef FareBreakdown = BookRideFareBreakdown;

class BookRidePickup {
  BookRideLocation? location;
  double? lat;
  double? lng;
  String? address;

  BookRidePickup({this.location, this.lat, this.lng, this.address});

  factory BookRidePickup.fromJson(String str) =>
      BookRidePickup.fromMap(json.decode(str));

  String toJsonString() => json.encode(toMap());

  factory BookRidePickup.fromMap(Map<String, dynamic> json) => BookRidePickup(
    location: json["location"] == null
        ? null
        : BookRideLocation.fromMap(json["location"]),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toMap() => {
    "location": location?.toMap(),
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class BookRidePreauth {
  String? reference;
  String? status;
  String? idempotencyKey;
  String? captureTransid;
  String? captureReference;
  int? capturedAmount;
  String? reverseTransid;
  String? reverseReference;
  String? obal;
  String? cbal;
  BookRidePreauthRawResponse? rawResponse;
  Map<String, dynamic>? captureResponse;
  DateTime? settledAt;
  String? transid;
  int? amount;
  String? type;
  String? createdAt;

  BookRidePreauth({
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

  factory BookRidePreauth.fromJson(String str) =>
      BookRidePreauth.fromMap(json.decode(str));

  String toJsonString() => json.encode(toMap());

  factory BookRidePreauth.fromMap(Map<String, dynamic> json) => BookRidePreauth(
    reference: json["reference"],
    status: json["status"],
    idempotencyKey: json["idempotency_key"],
    captureTransid: json["capture_transid"],
    captureReference: json["capture_reference"],
    capturedAmount: json["captured_amount"],
    reverseTransid: json["reverse_transid"],
    reverseReference: json["reverse_reference"],
    obal: json["obal"],
    cbal: json["cbal"],
    rawResponse: json["raw_response"] == null
        ? null
        : BookRidePreauthRawResponse.fromMap(json["raw_response"]),
    captureResponse: json["capture_response"] == null
        ? null
        : Map<String, dynamic>.from(json["capture_response"]),
    settledAt: json["settled_at"] == null
        ? null
        : DateTime.parse(json["settled_at"]),
    transid: json["transid"],
    amount: json["amount"],
    type: json["type"],
    createdAt: json["created_at"],
  );

  Map<String, dynamic> toMap() => {
    "reference": reference,
    "status": status,
    "idempotency_key": idempotencyKey,
    "capture_transid": captureTransid,
    "capture_reference": captureReference,
    "captured_amount": capturedAmount,
    "reverse_transid": reverseTransid,
    "reverse_reference": reverseReference,
    "obal": obal,
    "cbal": cbal,
    "raw_response": rawResponse?.toMap(),
    "capture_response": captureResponse,
    "settled_at": settledAt?.toIso8601String(),
    "transid": transid,
    "amount": amount,
    "type": type,
    "created_at": createdAt,
  };
}

class BookRidePreauthRawResponse {
  String? transid;
  String? result;
  String? resultcode;
  String? reference;
  String? message;
  String? currency;
  int? reserved;
  int? available;

  BookRidePreauthRawResponse({
    this.transid,
    this.result,
    this.resultcode,
    this.reference,
    this.message,
    this.currency,
    this.reserved,
    this.available,
  });

  factory BookRidePreauthRawResponse.fromJson(String str) =>
      BookRidePreauthRawResponse.fromMap(json.decode(str));

  String toJsonString() => json.encode(toMap());

  factory BookRidePreauthRawResponse.fromMap(Map<String, dynamic> json) =>
      BookRidePreauthRawResponse(
        transid: json["transid"],
        result: json["result"],
        resultcode: json["resultcode"],
        reference: json["reference"],
        message: json["message"],
        currency: json["currency"],
        reserved: json["reserved"],
        available: json["available"],
      );

  Map<String, dynamic> toMap() => {
    "transid": transid,
    "result": result,
    "resultcode": resultcode,
    "reference": reference,
    "message": message,
    "currency": currency,
    "reserved": reserved,
    "available": available,
  };
}
