import 'dart:convert';

/// Models for `GET go/rides/active` (from `model/model.dart` + legacy fields).
class ActiveRideResponseModel {
  int? statusCode;
  String? message;
  ActiveRideData? data;

  ActiveRideResponseModel({this.statusCode, this.message, this.data});

  /// Datasource-compatible: [Map] (or String JSON via decode).
  factory ActiveRideResponseModel.fromJson(dynamic source) {
    if (source is String) {
      return ActiveRideResponseModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
    }
    if (source is Map<String, dynamic>) {
      return ActiveRideResponseModel.fromMap(source);
    }
    if (source is Map) {
      return ActiveRideResponseModel.fromMap(
        Map<String, dynamic>.from(source),
      );
    }
    throw ArgumentError(
      'Unsupported ActiveRideResponseModel JSON: ${source.runtimeType}',
    );
  }

  String toJson() => json.encode(toMap());

  factory ActiveRideResponseModel.fromMap(Map<String, dynamic> json) =>
      ActiveRideResponseModel(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : ActiveRideData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

class ActiveRideData {
  List<ActiveRideEntry>? rides;
  int? count;

  /// Legacy single-ride envelope fields (older API / parser fallbacks).
  ActiveRide? ride;
  List<ActiveRide>? additionalRides;
  ActiveRideSocketRooms? socketRooms;
  int? activeRidesCount;
  int? additionalActiveRidesCount;

  ActiveRideData({
    this.rides,
    this.count,
    this.ride,
    this.additionalRides,
    this.socketRooms,
    this.activeRidesCount,
    this.additionalActiveRidesCount,
  });

  factory ActiveRideData.fromJson(String str) =>
      ActiveRideData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRideData.fromMap(Map<String, dynamic> json) => ActiveRideData(
    rides: json["rides"] == null
        ? []
        : List<ActiveRideEntry>.from(
            json["rides"]!.map((x) => ActiveRideEntry.fromMap(
                  x is Map<String, dynamic>
                      ? x
                      : Map<String, dynamic>.from(x as Map),
                )),
          ),
    count: json["count"],
    ride: json["ride"] == null ? null : ActiveRide.fromMap(json["ride"]),
    additionalRides: json["additional_rides"] == null
        ? null
        : List<ActiveRide>.from(
            json["additional_rides"]!.map((x) => ActiveRide.fromMap(
                  x is Map<String, dynamic>
                      ? x
                      : Map<String, dynamic>.from(x as Map),
                )),
          ),
    socketRooms: json["socket_rooms"] == null
        ? null
        : ActiveRideSocketRooms.fromMap(json["socket_rooms"]),
    activeRidesCount: json["active_rides_count"],
    additionalActiveRidesCount: json["additional_active_rides_count"],
  );

  Map<String, dynamic> toMap() => {
    "rides": rides == null
        ? []
        : List<dynamic>.from(rides!.map((x) => x.toMap())),
    "count": count,
    "ride": ride?.toMap(),
    "additional_rides": additionalRides == null
        ? null
        : List<dynamic>.from(additionalRides!.map((x) => x.toMap())),
    "socket_rooms": socketRooms?.toMap(),
    "active_rides_count": activeRidesCount,
    "additional_active_rides_count": additionalActiveRidesCount,
  };
}

class ActiveRideEntry {
  ActiveRide? ride;
  ActiveRideSocketRooms? socketRooms;

  ActiveRideEntry({this.ride, this.socketRooms});

  factory ActiveRideEntry.fromJson(String str) =>
      ActiveRideEntry.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRideEntry.fromMap(Map<String, dynamic> json) {
    final nestedRide = json["ride"];
    if (nestedRide is Map) {
      return ActiveRideEntry(
        ride: ActiveRide.fromMap(
          nestedRide is Map<String, dynamic>
              ? nestedRide
              : Map<String, dynamic>.from(nestedRide),
        ),
        socketRooms: json["socket_rooms"] == null
            ? null
            : ActiveRideSocketRooms.fromMap(json["socket_rooms"]),
      );
    }
    // Legacy: list item is a flat ride document (no nested `ride` key).
    return ActiveRideEntry(
      ride: ActiveRide.fromMap(json),
      socketRooms: json["socket_rooms"] == null
          ? null
          : ActiveRideSocketRooms.fromMap(json["socket_rooms"]),
    );
  }

  Map<String, dynamic> toMap() => {
    "ride": ride?.toMap(),
    "socket_rooms": socketRooms?.toMap(),
  };
}

class ActiveRide {
  String? id;
  String? status;
  ActiveRidePickup? pickup;
  ActiveRidePlace? destination;
  List<ActiveRidePlace>? stops;
  bool? isMultiStop;
  int? currentStopIndex;
  int? fareEstimate;
  String? vehicleTypeId;
  String? paymentMethod;
  String? paymentStatus;
  ActiveRideDriverSnapshot? driverSnapshot;
  ActiveRideVehicleSnapshot? vehicleSnapshot;
  String? pinCode;
  String? rideCreatedAt;
  ActiveRideFareBreakdown? fareBreakdown;
  bool? isBookedForOther;
  dynamic passengerName;
  dynamic passengerPhone;
  String? driverId;
  String? taskId;
  bool? isBookAny;
  List<dynamic>? bookAnyVehicleTypeIds;
  dynamic bookAnyBlockAmount;
  dynamic bookAnyResolvedAt;
  dynamic finalFare;
  int? additionalFare;
  bool? pinRequired;
  int? pinAttempts;
  dynamic pinLockedUntil;
  dynamic subOrderHistoryId;
  int? blockedAmount;
  String? blockValidationId;
  dynamic blockTransid;
  int? preauthTotal;
  int? captureTotal;
  int? cancellationFeeCaptured;
  dynamic promoCode;
  int? promoDiscount;
  bool? promoAutoApplied;
  dynamic cancelledAt;
  dynamic cancellationReason;
  int? cancellationFee;
  dynamic midRideCancel;
  List<dynamic>? rejectedDrivers;
  List<dynamic>? blockedDrivers;
  String? driverAssignedAt;
  String? driverArrivedAt;
  String? rideStartedAt;
  dynamic rideCompletedAt;
  dynamic riderRating;
  dynamic riderRatingComment;
  dynamic ratedAt;
  dynamic driverRating;
  dynamic driverRatingComment;
  dynamic driverRatedAt;
  dynamic feedbackText;
  List<dynamic>? feedbackTags;
  List<dynamic>? feedbackImages;
  dynamic feedbackAt;
  List<dynamic>? ratingTags;
  bool? isReviewSkipped;
  dynamic iosActivityToken;
  String? shareToken;
  String? shareLinkExpiresAt;
  bool? isShared;
  String? note;
  dynamic latraReferenceNumber;
  dynamic latraSubmittedAt;
  String? riderId;
  String? transid;
  double? distanceKm;
  int? durationMinutes;
  String? searchStartedAt;
  List<ActiveRidePreauth>? preauths;
  List<dynamic>? pdfLinks;
  String? createdAt;
  String? updatedAt;

  ActiveRide({
    this.id,
    this.status,
    this.pickup,
    this.destination,
    this.stops,
    this.isMultiStop,
    this.currentStopIndex,
    this.fareEstimate,
    this.vehicleTypeId,
    this.paymentMethod,
    this.paymentStatus,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.pinCode,
    this.rideCreatedAt,
    this.fareBreakdown,
    this.isBookedForOther,
    this.passengerName,
    this.passengerPhone,
    this.driverId,
    this.taskId,
    this.isBookAny,
    this.bookAnyVehicleTypeIds,
    this.bookAnyBlockAmount,
    this.bookAnyResolvedAt,
    this.finalFare,
    this.additionalFare,
    this.pinRequired,
    this.pinAttempts,
    this.pinLockedUntil,
    this.subOrderHistoryId,
    this.blockedAmount,
    this.blockValidationId,
    this.blockTransid,
    this.preauthTotal,
    this.captureTotal,
    this.cancellationFeeCaptured,
    this.promoCode,
    this.promoDiscount,
    this.promoAutoApplied,
    this.cancelledAt,
    this.cancellationReason,
    this.cancellationFee,
    this.midRideCancel,
    this.rejectedDrivers,
    this.blockedDrivers,
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
    this.latraReferenceNumber,
    this.latraSubmittedAt,
    this.riderId,
    this.transid,
    this.distanceKm,
    this.durationMinutes,
    this.searchStartedAt,
    this.preauths,
    this.pdfLinks,
    this.createdAt,
    this.updatedAt,
  });

  factory ActiveRide.fromJson(String str) =>
      ActiveRide.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRide.fromMap(Map<String, dynamic> json) => ActiveRide(
    id: json["_id"],
    status: json["status"],
    pickup: json["pickup"] == null
        ? null
        : ActiveRidePickup.fromMap(json["pickup"]),
    destination: json["destination"] == null
        ? null
        : ActiveRidePlace.fromMap(json["destination"]),
    stops: json["stops"] == null
        ? []
        : List<ActiveRidePlace>.from(
            json["stops"]!.map((x) => ActiveRidePlace.fromMap(x)),
          ),
    isMultiStop: json["is_multi_stop"],
    currentStopIndex: json["current_stop_index"],
    fareEstimate: json["fare_estimate"],
    vehicleTypeId: json["vehicle_type_id"] is Map
        ? json["vehicle_type_id"]["_id"]?.toString()
        : json["vehicle_type_id"]?.toString(),
    paymentMethod: json["payment_method"],
    paymentStatus: json["payment_status"],
    driverSnapshot: json["driver_snapshot"] == null
        ? null
        : ActiveRideDriverSnapshot.fromMap(json["driver_snapshot"]),
    vehicleSnapshot: json["vehicle_snapshot"] == null
        ? null
        : ActiveRideVehicleSnapshot.fromMap(json["vehicle_snapshot"]),
    pinCode: json["pin_code"],
    rideCreatedAt: json["created_at"],
    fareBreakdown: json["fare_breakdown"] == null
        ? null
        : ActiveRideFareBreakdown.fromMap(json["fare_breakdown"]),
    isBookedForOther: json["is_booked_for_other"],
    passengerName: json["passenger_name"],
    passengerPhone: json["passenger_phone"],
    driverId: json["driver_id"],
    taskId: json["task_id"],
    isBookAny: json["is_book_any"],
    bookAnyVehicleTypeIds: json["book_any_vehicle_type_ids"] == null
        ? []
        : List<dynamic>.from(json["book_any_vehicle_type_ids"]!.map((x) => x)),
    bookAnyBlockAmount: json["book_any_block_amount"],
    bookAnyResolvedAt: json["book_any_resolved_at"],
    finalFare: json["final_fare"],
    additionalFare: json["additional_fare"],
    pinRequired: json["pin_required"],
    pinAttempts: json["pin_attempts"],
    pinLockedUntil: json["pin_locked_until"],
    subOrderHistoryId: json["sub_order_history_id"],
    blockedAmount: json["blocked_amount"],
    blockValidationId: json["block_validation_id"],
    blockTransid: json["block_transid"],
    preauthTotal: json["preauth_total"],
    captureTotal: json["capture_total"],
    cancellationFeeCaptured: json["cancellation_fee_captured"],
    promoCode: json["promo_code"],
    promoDiscount: json["promo_discount"],
    promoAutoApplied: json["promo_auto_applied"],
    cancelledAt: json["cancelled_at"],
    cancellationReason: json["cancellation_reason"],
    cancellationFee: json["cancellation_fee"],
    midRideCancel: json["mid_ride_cancel"],
    rejectedDrivers: json["rejected_drivers"] == null
        ? []
        : List<dynamic>.from(json["rejected_drivers"]!.map((x) => x)),
    blockedDrivers: json["blocked_drivers"] == null
        ? []
        : List<dynamic>.from(json["blocked_drivers"]!.map((x) => x)),
    driverAssignedAt: json["driver_assigned_at"],
    driverArrivedAt: json["driver_arrived_at"],
    rideStartedAt: json["ride_started_at"],
    rideCompletedAt: json["ride_completed_at"],
    riderRating: json["rider_rating"],
    riderRatingComment: json["rider_rating_comment"],
    ratedAt: json["rated_at"],
    driverRating: json["driver_rating"],
    driverRatingComment: json["driver_rating_comment"],
    driverRatedAt: json["driver_rated_at"],
    feedbackText: json["feedback_text"],
    feedbackTags: json["feedback_tags"] == null
        ? []
        : List<dynamic>.from(json["feedback_tags"]!.map((x) => x)),
    feedbackImages: json["feedback_images"] == null
        ? []
        : List<dynamic>.from(json["feedback_images"]!.map((x) => x)),
    feedbackAt: json["feedback_at"],
    ratingTags: json["rating_tags"] == null
        ? []
        : List<dynamic>.from(json["rating_tags"]!.map((x) => x)),
    isReviewSkipped: json["is_review_skipped"],
    iosActivityToken: json["ios_activity_token"],
    shareToken: json["share_token"],
    shareLinkExpiresAt: json["share_link_expires_at"],
    isShared: json["is_shared"],
    note: json["note"],
    latraReferenceNumber: json["latra_reference_number"],
    latraSubmittedAt: json["latra_submitted_at"],
    riderId: json["rider_id"],
    transid: json["transid"],
    distanceKm: json["distance_km"]?.toDouble(),
    durationMinutes: json["duration_minutes"],
    searchStartedAt: json["search_started_at"],
    preauths: json["preauths"] == null
        ? []
        : List<ActiveRidePreauth>.from(
            json["preauths"]!.map((x) => ActiveRidePreauth.fromMap(x)),
          ),
    pdfLinks: json["pdf_links"] == null
        ? []
        : List<dynamic>.from(json["pdf_links"]!.map((x) => x)),
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id,
    "status": status,
    "pickup": pickup?.toMap(),
    "destination": destination?.toMap(),
    "stops": stops == null
        ? []
        : List<dynamic>.from(stops!.map((x) => x.toMap())),
    "is_multi_stop": isMultiStop,
    "current_stop_index": currentStopIndex,
    "fare_estimate": fareEstimate,
    "vehicle_type_id": vehicleTypeId,
    "payment_method": paymentMethod,
    "payment_status": paymentStatus,
    "driver_snapshot": driverSnapshot?.toMap(),
    "vehicle_snapshot": vehicleSnapshot?.toMap(),
    "pin_code": pinCode,
    "created_at": rideCreatedAt,
    "fare_breakdown": fareBreakdown?.toMap(),
    "is_booked_for_other": isBookedForOther,
    "passenger_name": passengerName,
    "passenger_phone": passengerPhone,
    "driver_id": driverId,
    "task_id": taskId,
    "is_book_any": isBookAny,
    "book_any_vehicle_type_ids": bookAnyVehicleTypeIds == null
        ? []
        : List<dynamic>.from(bookAnyVehicleTypeIds!.map((x) => x)),
    "book_any_block_amount": bookAnyBlockAmount,
    "book_any_resolved_at": bookAnyResolvedAt,
    "final_fare": finalFare,
    "additional_fare": additionalFare,
    "pin_required": pinRequired,
    "pin_attempts": pinAttempts,
    "pin_locked_until": pinLockedUntil,
    "sub_order_history_id": subOrderHistoryId,
    "blocked_amount": blockedAmount,
    "block_validation_id": blockValidationId,
    "block_transid": blockTransid,
    "preauth_total": preauthTotal,
    "capture_total": captureTotal,
    "cancellation_fee_captured": cancellationFeeCaptured,
    "promo_code": promoCode,
    "promo_discount": promoDiscount,
    "promo_auto_applied": promoAutoApplied,
    "cancelled_at": cancelledAt,
    "cancellation_reason": cancellationReason,
    "cancellation_fee": cancellationFee,
    "mid_ride_cancel": midRideCancel,
    "rejected_drivers": rejectedDrivers == null
        ? []
        : List<dynamic>.from(rejectedDrivers!.map((x) => x)),
    "blocked_drivers": blockedDrivers == null
        ? []
        : List<dynamic>.from(blockedDrivers!.map((x) => x)),
    "driver_assigned_at": driverAssignedAt,
    "driver_arrived_at": driverArrivedAt,
    "ride_started_at": rideStartedAt,
    "ride_completed_at": rideCompletedAt,
    "rider_rating": riderRating,
    "rider_rating_comment": riderRatingComment,
    "rated_at": ratedAt,
    "driver_rating": driverRating,
    "driver_rating_comment": driverRatingComment,
    "driver_rated_at": driverRatedAt,
    "feedback_text": feedbackText,
    "feedback_tags": feedbackTags == null
        ? []
        : List<dynamic>.from(feedbackTags!.map((x) => x)),
    "feedback_images": feedbackImages == null
        ? []
        : List<dynamic>.from(feedbackImages!.map((x) => x)),
    "feedback_at": feedbackAt,
    "rating_tags": ratingTags == null
        ? []
        : List<dynamic>.from(ratingTags!.map((x) => x)),
    "is_review_skipped": isReviewSkipped,
    "ios_activity_token": iosActivityToken,
    "share_token": shareToken,
    "share_link_expires_at": shareLinkExpiresAt,
    "is_shared": isShared,
    "note": note,
    "latra_reference_number": latraReferenceNumber,
    "latra_submitted_at": latraSubmittedAt,
    "rider_id": riderId,
    "transid": transid,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
    "search_started_at": searchStartedAt,
    "preauths": preauths == null
        ? []
        : List<dynamic>.from(preauths!.map((x) => x.toMap())),
    "pdf_links": pdfLinks == null
        ? []
        : List<dynamic>.from(pdfLinks!.map((x) => x)),
    "createdAt": createdAt,
    "updatedAt": updatedAt,
  };
}

class ActiveRidePlace {
  ActiveRideLocation? location;
  int? index;
  String? status;
  String? subtaskId;
  dynamic arrivedAt;
  dynamic completedAt;
  double? lat;
  double? lng;
  String? address;

  ActiveRidePlace({
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

  factory ActiveRidePlace.fromJson(String str) =>
      ActiveRidePlace.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRidePlace.fromMap(Map<String, dynamic> json) => ActiveRidePlace(
    location: json["location"] == null
        ? null
        : ActiveRideLocation.fromMap(json["location"]),
    index: json["index"],
    status: json["status"],
    subtaskId: json["subtask_id"],
    arrivedAt: json["arrived_at"],
    completedAt: json["completed_at"],
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toMap() => {
    "location": location?.toMap(),
    "index": index,
    "status": status,
    "subtask_id": subtaskId,
    "arrived_at": arrivedAt,
    "completed_at": completedAt,
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class ActiveRideLocation {
  String? type;
  List<double>? coordinates;

  ActiveRideLocation({this.type, this.coordinates});

  factory ActiveRideLocation.fromJson(String str) =>
      ActiveRideLocation.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRideLocation.fromMap(Map<String, dynamic> json) =>
      ActiveRideLocation(
        type: json["type"],
        coordinates: json["coordinates"] == null
            ? []
            : List<double>.from(
                json["coordinates"]!.map((x) => x?.toDouble()),
              ),
      );

  Map<String, dynamic> toMap() => {
    "type": type,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}

class ActiveRideDriverSnapshot {
  String? driverId;
  int? fleetId;
  String? name;
  String? accountNo;
  String? phone;
  String? email;
  dynamic licenseNumber;
  dynamic licenseCategory;
  String? avatarUrl;
  String? vehicleColor;
  String? vehicleModel;
  String? vehicleRegistrationNumber;
  dynamic vehicleChassisNumber;
  String? vehicleType;
  String? vehicleYear;
  int? rating;
  String? verificationCode;

  ActiveRideDriverSnapshot({
    this.driverId,
    this.fleetId,
    this.name,
    this.accountNo,
    this.phone,
    this.email,
    this.licenseNumber,
    this.licenseCategory,
    this.avatarUrl,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleRegistrationNumber,
    this.vehicleChassisNumber,
    this.vehicleType,
    this.vehicleYear,
    this.rating,
    this.verificationCode,
  });

  factory ActiveRideDriverSnapshot.fromJson(String str) =>
      ActiveRideDriverSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRideDriverSnapshot.fromMap(Map<String, dynamic> json) =>
      ActiveRideDriverSnapshot(
        driverId: json["driver_id"],
        fleetId: json["fleet_id"],
        name: json["name"],
        accountNo: json["account_no"],
        phone: json["phone"],
        email: json["email"],
        licenseNumber: json["license_number"],
        licenseCategory: json["license_category"],
        avatarUrl: json["avatar_url"],
        vehicleColor: json["vehicle_color"],
        vehicleModel: json["vehicle_model"],
        vehicleRegistrationNumber: json["vehicle_registration_number"],
        vehicleChassisNumber: json["vehicle_chassis_number"],
        vehicleType: json["vehicle_type"],
        vehicleYear: json["vehicle_year"]?.toString(),
        rating: json["rating"],
        verificationCode: json["verification_code"]?.toString(),
      );

  Map<String, dynamic> toMap() => {
    "driver_id": driverId,
    "fleet_id": fleetId,
    "name": name,
    "account_no": accountNo,
    "phone": phone,
    "email": email,
    "license_number": licenseNumber,
    "license_category": licenseCategory,
    "avatar_url": avatarUrl,
    "vehicle_color": vehicleColor,
    "vehicle_model": vehicleModel,
    "vehicle_registration_number": vehicleRegistrationNumber,
    "vehicle_chassis_number": vehicleChassisNumber,
    "vehicle_type": vehicleType,
    "vehicle_year": vehicleYear,
    "rating": rating,
    "verification_code": verificationCode,
  };
}

class ActiveRideFareBreakdown {
  int? rideCharge;
  int? bookingFee;
  int? totalAmount;

  ActiveRideFareBreakdown({
    this.rideCharge,
    this.bookingFee,
    this.totalAmount,
  });

  factory ActiveRideFareBreakdown.fromJson(String str) =>
      ActiveRideFareBreakdown.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRideFareBreakdown.fromMap(Map<String, dynamic> json) =>
      ActiveRideFareBreakdown(
        rideCharge: json["ride_charge"],
        bookingFee: json["booking_fee"],
        totalAmount: json["total_amount"],
      );

  Map<String, dynamic> toMap() => {
    "ride_charge": rideCharge,
    "booking_fee": bookingFee,
    "total_amount": totalAmount,
  };
}

/// Alias kept for existing typed references.
typedef FareBreakdown = ActiveRideFareBreakdown;

class ActiveRidePickup {
  ActiveRideLocation? location;
  double? lat;
  double? lng;
  String? address;

  ActiveRidePickup({this.location, this.lat, this.lng, this.address});

  factory ActiveRidePickup.fromJson(String str) =>
      ActiveRidePickup.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRidePickup.fromMap(Map<String, dynamic> json) =>
      ActiveRidePickup(
        location: json["location"] == null
            ? null
            : ActiveRideLocation.fromMap(json["location"]),
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

class ActiveRidePreauth {
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
  ActiveRidePreauthRawResponse? rawResponse;
  dynamic captureResponse;
  String? settledAt;
  String? transid;
  int? amount;
  String? type;
  String? createdAt;

  ActiveRidePreauth({
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

  factory ActiveRidePreauth.fromJson(String str) =>
      ActiveRidePreauth.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRidePreauth.fromMap(Map<String, dynamic> json) =>
      ActiveRidePreauth(
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
            : ActiveRidePreauthRawResponse.fromMap(json["raw_response"]),
        captureResponse: json["capture_response"],
        settledAt: json["settled_at"],
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
    "settled_at": settledAt,
    "transid": transid,
    "amount": amount,
    "type": type,
    "created_at": createdAt,
  };
}

class ActiveRidePreauthRawResponse {
  String? transid;
  String? result;
  String? resultcode;
  String? reference;
  String? message;
  String? currency;
  int? reserved;
  int? available;

  ActiveRidePreauthRawResponse({
    this.transid,
    this.result,
    this.resultcode,
    this.reference,
    this.message,
    this.currency,
    this.reserved,
    this.available,
  });

  factory ActiveRidePreauthRawResponse.fromJson(String str) =>
      ActiveRidePreauthRawResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRidePreauthRawResponse.fromMap(Map<String, dynamic> json) =>
      ActiveRidePreauthRawResponse(
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

class ActiveRideVehicleSnapshot {
  String? vehicleType;
  String? vehicleName;
  String? displayName;

  ActiveRideVehicleSnapshot({
    this.vehicleType,
    this.vehicleName,
    this.displayName,
  });

  factory ActiveRideVehicleSnapshot.fromJson(String str) =>
      ActiveRideVehicleSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRideVehicleSnapshot.fromMap(Map<String, dynamic> json) =>
      ActiveRideVehicleSnapshot(
        vehicleType: json["vehicle_type"],
        vehicleName: json["vehicle_name"],
        displayName: json["display_name"],
      );

  Map<String, dynamic> toMap() => {
    "vehicle_type": vehicleType,
    "vehicle_name": vehicleName,
    "display_name": displayName,
  };
}

class ActiveRideSocketRooms {
  String? status;
  String? track;
  String? chat;

  ActiveRideSocketRooms({this.status, this.track, this.chat});

  factory ActiveRideSocketRooms.fromJson(String str) =>
      ActiveRideSocketRooms.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ActiveRideSocketRooms.fromMap(Map<String, dynamic> json) =>
      ActiveRideSocketRooms(
        status: json["status"],
        track: json["track"],
        chat: json["chat"],
      );

  Map<String, dynamic> toMap() => {
    "status": status,
    "track": track,
    "chat": chat,
  };
}
