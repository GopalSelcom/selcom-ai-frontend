// To parse this JSON data, do
//
//     final bookRideResponse = bookRideResponseFromJson(jsonString);

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

BookRideResponse bookRideResponseFromJson(String str) => BookRideResponse.fromJson(json.decode(str));

String bookRideResponseToJson(BookRideResponse data) => json.encode(data.toJson());

class BookRideResponse {
  int? statusCode;
  String? message;
  RideData? data;

  BookRideResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  BookRideResponse copyWith({
    int? statusCode,
    String? message,
    RideData? data,
  }) =>
      BookRideResponse(
        statusCode: statusCode ?? this.statusCode,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory BookRideResponse.fromJson(Map<String, dynamic> json) => BookRideResponse(
    statusCode: json["status_code"],
    message: json["message"],
    data: json["data"] == null ? null : RideData.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class RideData {
  Ride? ride;

  RideData({
    this.ride,
  });

  RideData copyWith({
    Ride? ride,
  }) =>
      RideData(
        ride: ride ?? this.ride,
      );

  /// Book ride API may return either `{ "ride": { ... } }` or the ride
  /// document flattened at the root of `data`.
  factory RideData.fromJson(Map<String, dynamic> json) {
    final nested = json['ride'];
    if (nested is Map<String, dynamic>) {
      return RideData(ride: Ride.fromJson(nested));
    }
    return RideData(ride: Ride.fromJson(json));
  }

  Map<String, dynamic> toJson() => {
    "ride": ride?.toJson(),
  };
}

/// One stop row from `stops` in book/active ride payloads.
class BookRideStop {
  Location? location;
  String? status;
  String? subtaskId;
  DateTime? arrivedAt;
  DateTime? completedAt;
  int? index;
  double? lat;
  double? lng;
  String? address;

  BookRideStop({
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

  factory BookRideStop.fromJson(Map<String, dynamic> json) => BookRideStop(
    location: json["location"] == null ? null : Location.fromJson(json["location"]),
    status: json["status"]?.toString(),
    subtaskId: json["subtask_id"]?.toString(),
    arrivedAt: _dateTimeFromJson(json["arrived_at"]),
    completedAt: _dateTimeFromJson(json["completed_at"]),
    index: (json["index"] as num?)?.toInt(),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "status": status,
    "subtask_id": subtaskId,
    "arrived_at": arrivedAt?.toIso8601String(),
    "completed_at": completedAt?.toIso8601String(),
    "index": index,
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class Ride {
  FareBreakdown? fareBreakdown;
  dynamic driverId;
  dynamic taskId;
  String? status;
  bool? isMultiStop;
  int? currentStopIndex;
  List<BookRideStop> stops;
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
  dynamic promoCode;
  int? promoDiscount;
  DateTime? cancelledAt;
  String? cancellationReason;
  int? cancellationFee;
  List<String> rejectedDrivers;
  List<String> blockedDrivers;
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
  List<String> feedbackTags;
  List<String> feedbackImages;
  DateTime? feedbackAt;
  List<String> ratingTags;
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
  Destination? pickup;
  Destination? destination;
  int? fareEstimate;
  double? distanceKm;
  int? durationMinutes;
  String? idempotencyKey;
  String? paymentMethod;
  DateTime? searchStartedAt;
  List<String> pdfLinks;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;
  int? cancelTime;

  Ride({
    this.fareBreakdown,
    this.driverId,
    this.taskId,
    this.status,
    this.isMultiStop,
    this.currentStopIndex,
    List<BookRideStop>? stops,
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
    this.promoCode,
    this.promoDiscount,
    this.cancelledAt,
    this.cancellationReason,
    this.cancellationFee,
    List<String>? rejectedDrivers,
    List<String>? blockedDrivers,
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
    List<String>? feedbackTags,
    List<String>? feedbackImages,
    this.feedbackAt,
    List<String>? ratingTags,
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
    List<String>? pdfLinks,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.cancelTime,
  })  : stops = stops ?? const [],
        rejectedDrivers = rejectedDrivers ?? const [],
        blockedDrivers = blockedDrivers ?? const [],
        feedbackTags = feedbackTags ?? const [],
        feedbackImages = feedbackImages ?? const [],
        ratingTags = ratingTags ?? const [],
        pdfLinks = pdfLinks ?? const [];

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
    fareBreakdown: json["fare_breakdown"] == null
        ? null
        : FareBreakdown.fromJson(json["fare_breakdown"]),
    driverId: json["driver_id"],
    taskId: json["task_id"],
    status: json["status"]?.toString(),
    isMultiStop: json["is_multi_stop"] as bool?,
    currentStopIndex: (json["current_stop_index"] as num?)?.toInt(),
    stops: _stopsFromJson(json["stops"]),
    finalFare: json["final_fare"],
    additionalFare: (json["additional_fare"] as num?)?.toInt(),
    pinCode: json["pin_code"]?.toString(),
    pinRequired: json["pin_required"] as bool?,
    pinAttempts: (json["pin_attempts"] as num?)?.toInt(),
    pinLockedUntil: _dateTimeFromJson(json["pin_locked_until"]),
    subOrderHistoryId: json["sub_order_history_id"],
    paymentStatus: json["payment_status"]?.toString(),
    blockedAmount: (json["blocked_amount"] as num?)?.toInt(),
    blockValidationId: json["block_validation_id"]?.toString(),
    blockTransid: json["block_transid"],
    promoCode: json["promo_code"],
    promoDiscount: (json["promo_discount"] as num?)?.toInt(),
    cancelledAt: _dateTimeFromJson(json["cancelled_at"]),
    cancellationReason: json["cancellation_reason"]?.toString(),
    cancellationFee: (json["cancellation_fee"] as num?)?.toInt(),
    rejectedDrivers: _stringListFromJson(json["rejected_drivers"]),
    blockedDrivers: _stringListFromJson(json["blocked_drivers"]),
    driverSnapshot: json["driver_snapshot"],
    vehicleSnapshot: json["vehicle_snapshot"],
    driverAssignedAt: _dateTimeFromJson(json["driver_assigned_at"]),
    driverArrivedAt: _dateTimeFromJson(json["driver_arrived_at"]),
    rideStartedAt: _dateTimeFromJson(json["ride_started_at"]),
    rideCompletedAt: _dateTimeFromJson(json["ride_completed_at"]),
    riderRating: json["rider_rating"] as num?,
    riderRatingComment: json["rider_rating_comment"]?.toString(),
    ratedAt: _dateTimeFromJson(json["rated_at"]),
    driverRating: json["driver_rating"] as num?,
    driverRatingComment: json["driver_rating_comment"]?.toString(),
    driverRatedAt: _dateTimeFromJson(json["driver_rated_at"]),
    feedbackText: json["feedback_text"]?.toString(),
    feedbackTags: _stringListFromJson(json["feedback_tags"]),
    feedbackImages: _stringListFromJson(json["feedback_images"]),
    feedbackAt: _dateTimeFromJson(json["feedback_at"]),
    ratingTags: _stringListFromJson(json["rating_tags"]),
    isReviewSkipped: json["is_review_skipped"] as bool?,
    iosActivityToken: json["ios_activity_token"]?.toString(),
    shareToken: json["share_token"]?.toString(),
    shareLinkExpiresAt: _dateTimeFromJson(json["share_link_expires_at"]),
    isShared: json["is_shared"] as bool?,
    note: json["note"]?.toString(),
    pendingStopsUpdate: _mapFromJson(json["pending_stops_update"]),
    isBookedForOther: json["is_booked_for_other"] as bool?,
    passengerName: json["passenger_name"]?.toString(),
    passengerPhone: json["passenger_phone"]?.toString(),
    latraReferenceNumber: json["latra_reference_number"]?.toString(),
    latraSubmittedAt: _dateTimeFromJson(json["latra_submitted_at"]),
    id: json["_id"]?.toString(),
    riderId: json["rider_id"]?.toString(),
    vehicleTypeId: json["vehicle_type_id"]?.toString(),
    transid: json["transid"]?.toString(),
    pickup: json["pickup"] == null ? null : Destination.fromJson(json["pickup"]),
    destination: json["destination"] == null ? null : Destination.fromJson(json["destination"]),
    fareEstimate: (json["fare_estimate"] as num?)?.toInt(),
    distanceKm: json["distance_km"]?.toDouble(),
    durationMinutes: (json["duration_minutes"] as num?)?.toInt(),
    idempotencyKey: json["idempotency_key"]?.toString(),
    paymentMethod: json["payment_method"]?.toString(),
    searchStartedAt: _dateTimeFromJson(json["search_started_at"]),
    pdfLinks: _stringListFromJson(json["pdf_links"]),
    createdAt: _dateTimeFromJson(json["createdAt"]),
    updatedAt: _dateTimeFromJson(json["updatedAt"]),
    v: (json["__v"] as num?)?.toInt(),
    cancelTime: (json["cancel_time"] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    "fare_breakdown": fareBreakdown?.toJson(),
    "driver_id": driverId,
    "task_id": taskId,
    "status": status,
    "is_multi_stop": isMultiStop,
    "current_stop_index": currentStopIndex,
    "stops": stops.map((x) => x.toJson()).toList(),
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
    "promo_code": promoCode,
    "promo_discount": promoDiscount,
    "cancelled_at": cancelledAt?.toIso8601String(),
    "cancellation_reason": cancellationReason,
    "cancellation_fee": cancellationFee,
    "rejected_drivers": rejectedDrivers,
    "blocked_drivers": blockedDrivers,
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
    "feedback_tags": feedbackTags,
    "feedback_images": feedbackImages,
    "feedback_at": feedbackAt?.toIso8601String(),
    "rating_tags": ratingTags,
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
    "pickup": pickup?.toJson(),
    "destination": destination?.toJson(),
    "fare_estimate": fareEstimate,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
    "idempotency_key": idempotencyKey,
    "payment_method": paymentMethod,
    "search_started_at": searchStartedAt?.toIso8601String(),
    "pdf_links": pdfLinks,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
    "cancel_time": cancelTime,
  };
}

class FareBreakdown {
  int? rideCharge;
  int? bookingFee;
  int? totalAmount;

  FareBreakdown({this.rideCharge, this.bookingFee, this.totalAmount});

  FareBreakdown copyWith({
    int? rideCharge,
    int? bookingFee,
    int? totalAmount,
  }) => FareBreakdown(
    rideCharge: rideCharge ?? this.rideCharge,
    bookingFee: bookingFee ?? this.bookingFee,
    totalAmount: totalAmount ?? this.totalAmount,
  );

  factory FareBreakdown.fromJson(Map<String, dynamic> json) => FareBreakdown(
    rideCharge: (json["ride_charge"] as num?)?.toInt(),
    bookingFee: (json["booking_fee"] as num?)?.toInt(),
    totalAmount: (json["total_amount"] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    "ride_charge": rideCharge,
    "booking_fee": bookingFee,
    "total_amount": totalAmount,
  };
}

class Destination {
  Location? location;
  double? lat;
  double? lng;
  String? address;

  Destination({
    this.location,
    this.lat,
    this.lng,
    this.address,
  });

  Destination copyWith({
    Location? location,
    double? lat,
    double? lng,
    String? address,
  }) =>
      Destination(
        location: location ?? this.location,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        address: address ?? this.address,
      );

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
    location: json["location"] == null ? null : Location.fromJson(json["location"]),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({
    this.type,
    this.coordinates,
  });

  Location copyWith({
    String? type,
    List<double>? coordinates,
  }) =>
      Location(
        type: type ?? this.type,
        coordinates: coordinates ?? this.coordinates,
      );

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    type: json["type"],
    coordinates: json["coordinates"] == null ? [] : List<double>.from(json["coordinates"]!.map((x) => x?.toDouble())),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "coordinates": coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}
