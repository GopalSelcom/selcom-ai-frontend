// To parse this JSON data, do
//
//     final bookRideResponse = bookRideResponseFromJson(jsonString);

import 'dart:convert';

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

  factory RideData.fromJson(Map<String, dynamic> json) => RideData(
    ride: json["ride"] == null ? null : Ride.fromJson(json["ride"]),
  );

  Map<String, dynamic> toJson() => {
    "ride": ride?.toJson(),
  };
}

class Ride {
  FareBreakdown? fareBreakdown;
  dynamic driverId;
  dynamic taskId;
  String? status;
  List<dynamic>? stops;
  dynamic finalFare;
  int? additionalFare;
  int? pinAttempts;
  dynamic pinLockedUntil;
  dynamic subOrderHistoryId;
  String? paymentStatus;
  int? blockedAmount;
  String? blockValidationId;
  dynamic blockTransid;
  dynamic promoCode;
  int? promoDiscount;
  dynamic cancelledAt;
  dynamic cancellationReason;
  int? cancellationFee;
  List<dynamic>? rejectedDrivers;
  dynamic driverSnapshot;
  dynamic vehicleSnapshot;
  dynamic driverAssignedAt;
  dynamic driverArrivedAt;
  dynamic rideStartedAt;
  dynamic rideCompletedAt;
  dynamic riderRating;
  dynamic riderRatingComment;
  dynamic ratedAt;
  dynamic feedbackText;
  List<dynamic>? feedbackTags;
  List<dynamic>? feedbackImages;
  dynamic feedbackAt;
  String? id;
  String? riderId;
  String? vehicleTypeId;
  Destination? pickup;
  Destination? destination;
  int? fareEstimate;
  double? distanceKm;
  int? durationMinutes;
  String? idempotencyKey;
  String? pinCode;
  String? paymentMethod;
  DateTime? searchStartedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
  int? v;

  Ride({
    this.fareBreakdown,
    this.driverId,
    this.taskId,
    this.status,
    this.stops,
    this.finalFare,
    this.additionalFare,
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
    this.rejectedDrivers,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.driverAssignedAt,
    this.driverArrivedAt,
    this.rideStartedAt,
    this.rideCompletedAt,
    this.riderRating,
    this.riderRatingComment,
    this.ratedAt,
    this.feedbackText,
    this.feedbackTags,
    this.feedbackImages,
    this.feedbackAt,
    this.id,
    this.riderId,
    this.vehicleTypeId,
    this.pickup,
    this.destination,
    this.fareEstimate,
    this.distanceKm,
    this.durationMinutes,
    this.idempotencyKey,
    this.pinCode,
    this.paymentMethod,
    this.searchStartedAt,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  Ride copyWith({
    FareBreakdown? fareBreakdown,
    dynamic driverId,
    dynamic taskId,
    String? status,
    List<dynamic>? stops,
    dynamic finalFare,
    int? additionalFare,
    int? pinAttempts,
    dynamic pinLockedUntil,
    dynamic subOrderHistoryId,
    String? paymentStatus,
    int? blockedAmount,
    String? blockValidationId,
    dynamic blockTransid,
    dynamic promoCode,
    int? promoDiscount,
    dynamic cancelledAt,
    dynamic cancellationReason,
    int? cancellationFee,
    List<dynamic>? rejectedDrivers,
    dynamic driverSnapshot,
    dynamic vehicleSnapshot,
    dynamic driverAssignedAt,
    dynamic driverArrivedAt,
    dynamic rideStartedAt,
    dynamic rideCompletedAt,
    dynamic riderRating,
    dynamic riderRatingComment,
    dynamic ratedAt,
    dynamic feedbackText,
    List<dynamic>? feedbackTags,
    List<dynamic>? feedbackImages,
    dynamic feedbackAt,
    String? id,
    String? riderId,
    String? vehicleTypeId,
    Destination? pickup,
    Destination? destination,
    int? fareEstimate,
    double? distanceKm,
    int? durationMinutes,
    String? idempotencyKey,
    String? pinCode,
    String? paymentMethod,
    DateTime? searchStartedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) =>
      Ride(
        fareBreakdown: fareBreakdown ?? this.fareBreakdown,
        driverId: driverId ?? this.driverId,
        taskId: taskId ?? this.taskId,
        status: status ?? this.status,
        stops: stops ?? this.stops,
        finalFare: finalFare ?? this.finalFare,
        additionalFare: additionalFare ?? this.additionalFare,
        pinAttempts: pinAttempts ?? this.pinAttempts,
        pinLockedUntil: pinLockedUntil ?? this.pinLockedUntil,
        subOrderHistoryId: subOrderHistoryId ?? this.subOrderHistoryId,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        blockedAmount: blockedAmount ?? this.blockedAmount,
        blockValidationId: blockValidationId ?? this.blockValidationId,
        blockTransid: blockTransid ?? this.blockTransid,
        promoCode: promoCode ?? this.promoCode,
        promoDiscount: promoDiscount ?? this.promoDiscount,
        cancelledAt: cancelledAt ?? this.cancelledAt,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        cancellationFee: cancellationFee ?? this.cancellationFee,
        rejectedDrivers: rejectedDrivers ?? this.rejectedDrivers,
        driverSnapshot: driverSnapshot ?? this.driverSnapshot,
        vehicleSnapshot: vehicleSnapshot ?? this.vehicleSnapshot,
        driverAssignedAt: driverAssignedAt ?? this.driverAssignedAt,
        driverArrivedAt: driverArrivedAt ?? this.driverArrivedAt,
        rideStartedAt: rideStartedAt ?? this.rideStartedAt,
        rideCompletedAt: rideCompletedAt ?? this.rideCompletedAt,
        riderRating: riderRating ?? this.riderRating,
        riderRatingComment: riderRatingComment ?? this.riderRatingComment,
        ratedAt: ratedAt ?? this.ratedAt,
        feedbackText: feedbackText ?? this.feedbackText,
        feedbackTags: feedbackTags ?? this.feedbackTags,
        feedbackImages: feedbackImages ?? this.feedbackImages,
        feedbackAt: feedbackAt ?? this.feedbackAt,
        id: id ?? this.id,
        riderId: riderId ?? this.riderId,
        vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
        pickup: pickup ?? this.pickup,
        destination: destination ?? this.destination,
        fareEstimate: fareEstimate ?? this.fareEstimate,
        distanceKm: distanceKm ?? this.distanceKm,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        pinCode: pinCode ?? this.pinCode,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        searchStartedAt: searchStartedAt ?? this.searchStartedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        v: v ?? this.v,
      );

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
    fareBreakdown: json["fare_breakdown"] == null
        ? null
        : FareBreakdown.fromJson(json["fare_breakdown"]),
    driverId: json["driver_id"],
    taskId: json["task_id"],
    status: json["status"],
    stops: json["stops"] == null ? [] : List<dynamic>.from(json["stops"]!.map((x) => x)),
    finalFare: json["final_fare"],
    additionalFare: json["additional_fare"],
    pinAttempts: json["pin_attempts"],
    pinLockedUntil: json["pin_locked_until"],
    subOrderHistoryId: json["sub_order_history_id"],
    paymentStatus: json["payment_status"],
    blockedAmount: json["blocked_amount"],
    blockValidationId: json["block_validation_id"],
    blockTransid: json["block_transid"],
    promoCode: json["promo_code"],
    promoDiscount: json["promo_discount"],
    cancelledAt: json["cancelled_at"],
    cancellationReason: json["cancellation_reason"],
    cancellationFee: json["cancellation_fee"],
    rejectedDrivers: json["rejected_drivers"] == null ? [] : List<dynamic>.from(json["rejected_drivers"]!.map((x) => x)),
    driverSnapshot: json["driver_snapshot"],
    vehicleSnapshot: json["vehicle_snapshot"],
    driverAssignedAt: json["driver_assigned_at"],
    driverArrivedAt: json["driver_arrived_at"],
    rideStartedAt: json["ride_started_at"],
    rideCompletedAt: json["ride_completed_at"],
    riderRating: json["rider_rating"],
    riderRatingComment: json["rider_rating_comment"],
    ratedAt: json["rated_at"],
    feedbackText: json["feedback_text"],
    feedbackTags: json["feedback_tags"] == null ? [] : List<dynamic>.from(json["feedback_tags"]!.map((x) => x)),
    feedbackImages: json["feedback_images"] == null ? [] : List<dynamic>.from(json["feedback_images"]!.map((x) => x)),
    feedbackAt: json["feedback_at"],
    id: json["_id"],
    riderId: json["rider_id"],
    vehicleTypeId: json["vehicle_type_id"],
    pickup: json["pickup"] == null ? null : Destination.fromJson(json["pickup"]),
    destination: json["destination"] == null ? null : Destination.fromJson(json["destination"]),
    fareEstimate: json["fare_estimate"],
    distanceKm: json["distance_km"]?.toDouble(),
    durationMinutes: json["duration_minutes"],
    idempotencyKey: json["idempotency_key"],
    pinCode: json["pin_code"],
    paymentMethod: json["payment_method"],
    searchStartedAt: json["search_started_at"] == null ? null : DateTime.parse(json["search_started_at"]),
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "fare_breakdown": fareBreakdown?.toJson(),
    "driver_id": driverId,
    "task_id": taskId,
    "status": status,
    "stops": stops == null ? [] : List<dynamic>.from(stops!.map((x) => x)),
    "final_fare": finalFare,
    "additional_fare": additionalFare,
    "pin_attempts": pinAttempts,
    "pin_locked_until": pinLockedUntil,
    "sub_order_history_id": subOrderHistoryId,
    "payment_status": paymentStatus,
    "blocked_amount": blockedAmount,
    "block_validation_id": blockValidationId,
    "block_transid": blockTransid,
    "promo_code": promoCode,
    "promo_discount": promoDiscount,
    "cancelled_at": cancelledAt,
    "cancellation_reason": cancellationReason,
    "cancellation_fee": cancellationFee,
    "rejected_drivers": rejectedDrivers == null ? [] : List<dynamic>.from(rejectedDrivers!.map((x) => x)),
    "driver_snapshot": driverSnapshot,
    "vehicle_snapshot": vehicleSnapshot,
    "driver_assigned_at": driverAssignedAt,
    "driver_arrived_at": driverArrivedAt,
    "ride_started_at": rideStartedAt,
    "ride_completed_at": rideCompletedAt,
    "rider_rating": riderRating,
    "rider_rating_comment": riderRatingComment,
    "rated_at": ratedAt,
    "feedback_text": feedbackText,
    "feedback_tags": feedbackTags == null ? [] : List<dynamic>.from(feedbackTags!.map((x) => x)),
    "feedback_images": feedbackImages == null ? [] : List<dynamic>.from(feedbackImages!.map((x) => x)),
    "feedback_at": feedbackAt,
    "_id": id,
    "rider_id": riderId,
    "vehicle_type_id": vehicleTypeId,
    "pickup": pickup?.toJson(),
    "destination": destination?.toJson(),
    "fare_estimate": fareEstimate,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
    "idempotency_key": idempotencyKey,
    "pin_code": pinCode,
    "payment_method": paymentMethod,
    "search_started_at": searchStartedAt?.toIso8601String(),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
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
