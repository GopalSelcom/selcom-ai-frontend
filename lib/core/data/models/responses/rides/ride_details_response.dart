import 'dart:convert';

import '../../fare_stop_charge.dart';
import '../../ride_model.dart';
import '../../ride_no_show_info_model.dart';

/// Models for `GET go/rides/{id}` — `{"status_code":200,"data":{"ride":{...}}}`.
///
/// Field shapes mirror `active_ride_response.dart` (`ActiveRide`) since both
/// endpoints return the same underlying ride document, but this response
/// keeps a few fields more strongly typed (`vehicle_type_id`, `mid_ride_cancel`,
/// `pending_stops_update`, `pdf_links`) for details-screen consumption.
class RideDetailsResponse {
  int? statusCode;
  String? message;
  RideDetailsData? data;

  RideDetailsResponse({this.statusCode, this.message, this.data});

  /// Datasource-compatible: [Map] (or String JSON via decode).
  factory RideDetailsResponse.fromJson(dynamic source) {
    if (source is String) {
      return RideDetailsResponse.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
    }
    if (source is Map<String, dynamic>) {
      return RideDetailsResponse.fromMap(source);
    }
    if (source is Map) {
      return RideDetailsResponse.fromMap(Map<String, dynamic>.from(source));
    }
    throw ArgumentError(
      'Unsupported RideDetailsResponse JSON: ${source.runtimeType}',
    );
  }

  String toJson() => json.encode(toMap());

  factory RideDetailsResponse.fromMap(Map<String, dynamic> json) =>
      RideDetailsResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : RideDetailsData.fromMap(
                json["data"] is Map<String, dynamic>
                    ? json["data"]
                    : Map<String, dynamic>.from(json["data"] as Map),
              ),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };

  bool get isSuccess => statusCode == 200;

  RideDetailsRide? get ride => data?.ride;
}

class RideDetailsData {
  RideDetailsRide? ride;

  RideDetailsData({this.ride});

  factory RideDetailsData.fromJson(String str) =>
      RideDetailsData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsData.fromMap(Map<String, dynamic> json) =>
      RideDetailsData(
        ride: json["ride"] == null
            ? null
            : RideDetailsRide.fromMap(
                json["ride"] is Map<String, dynamic>
                    ? json["ride"]
                    : Map<String, dynamic>.from(json["ride"] as Map),
              ),
      );

  Map<String, dynamic> toMap() => {"ride": ride?.toMap()};
}

class RideDetailsRide {
  String? id;
  String? status;
  RideDetailsPickup? pickup;
  RideDetailsPlace? destination;
  List<RideDetailsPlace>? stops;
  bool? isMultiStop;
  int? currentStopIndex;
  int? fareEstimate;
  RideDetailsVehicleType? vehicleTypeId;
  String? paymentMethod;
  String? paymentStatus;
  RideDetailsDriverSnapshot? driverSnapshot;
  RideDetailsVehicleSnapshot? vehicleSnapshot;
  String? pinCode;
  String? rideCreatedAt;
  RideDetailsFareBreakdown? fareBreakdown;
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
  int? cashbackAmount;
  dynamic cancelledAt;
  dynamic cancellationReason;
  int? cancellationFee;
  String? cancelledBy;
  RideDetailsMidRideCancel? midRideCancel;
  /// Waiting banner while driver is at pickup (`no_show` object, e.g. scheduled).
  RideNoShowInfoModel? noShow;
  /// Terminal no-show cancel — `no_show: true` or fired `no_show` object.
  bool isNoShowCancellation;
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
  bool? showReviewUi;
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
  List<RideDetailsPreauth>? preauths;
  List<RideDetailsPdfLink>? pdfLinks;
  RideDetailsPendingStopsUpdate? pendingStopsUpdate;
  String? createdAt;
  String? updatedAt;

  RideDetailsRide({
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
    this.cashbackAmount,
    this.cancelledAt,
    this.cancellationReason,
    this.cancellationFee,
    this.cancelledBy,
    this.midRideCancel,
    this.noShow,
    this.isNoShowCancellation = false,
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
    this.showReviewUi,
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
    this.pendingStopsUpdate,
    this.createdAt,
    this.updatedAt,
  });

  factory RideDetailsRide.fromJson(String str) =>
      RideDetailsRide.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsRide.fromMap(Map<String, dynamic> json) {
    final createdAtStr = json["createdAt"];

    return RideDetailsRide(
      id: json["_id"] ?? '',
      status: json["status"] ?? '',
      pickup: json["pickup"] == null
          ? null
          : RideDetailsPickup.fromMap(json["pickup"]),
      destination: json["destination"] == null
          ? null
          : RideDetailsPlace.fromMap(json["destination"]),
      stops: json["stops"] == null
          ? <RideDetailsPlace>[]
          : List<RideDetailsPlace>.from(
              json["stops"].map((x) => RideDetailsPlace.fromMap(x)),
            ),
      isMultiStop: json["is_multi_stop"] ?? false,
      currentStopIndex: json["current_stop_index"] ?? 0,
      fareEstimate: json["fare_estimate"] ?? 0,
      vehicleTypeId: json["vehicle_type_id"] == null
          ? null
          : RideDetailsVehicleType.fromMap(json["vehicle_type_id"]),
      paymentMethod: json["payment_method"] ?? '',
      paymentStatus: json["payment_status"] ?? '',
      driverSnapshot: json["driver_snapshot"] == null
          ? null
          : RideDetailsDriverSnapshot.fromMap(json["driver_snapshot"]),
      vehicleSnapshot: json["vehicle_snapshot"] == null
          ? null
          : RideDetailsVehicleSnapshot.fromMap(json["vehicle_snapshot"]),
      pinCode: json["pin_code"] ?? '',
      rideCreatedAt: json["created_at"] ?? createdAtStr ?? '',
      fareBreakdown: json["fare_breakdown"] == null
          ? null
          : RideDetailsFareBreakdown.fromMap(json["fare_breakdown"]),
      isBookedForOther: json["is_booked_for_other"] ?? false,
      passengerName: json["passenger_name"],
      passengerPhone: json["passenger_phone"],
      driverId: json["driver_id"] ?? '',
      taskId: json["task_id"] ?? '',
      isBookAny: json["is_book_any"] ?? false,
      bookAnyVehicleTypeIds: json["book_any_vehicle_type_ids"] ?? <dynamic>[],
      bookAnyBlockAmount: json["book_any_block_amount"],
      bookAnyResolvedAt: json["book_any_resolved_at"],
      finalFare: json["final_fare"],
      additionalFare: json["additional_fare"] ?? 0,
      pinRequired: json["pin_required"] ?? false,
      pinAttempts: json["pin_attempts"] ?? 0,
      pinLockedUntil: json["pin_locked_until"],
      subOrderHistoryId: json["sub_order_history_id"],
      blockedAmount: json["blocked_amount"] ?? 0,
      blockValidationId: json["block_validation_id"] ?? '',
      blockTransid: json["block_transid"],
      preauthTotal: json["preauth_total"] ?? 0,
      captureTotal: json["capture_total"] ?? 0,
      cancellationFeeCaptured: json["cancellation_fee_captured"] ?? 0,
      promoCode: json["promo_code"] ?? '',
      promoDiscount: json["promo_discount"] ?? 0,
      promoAutoApplied: json["promo_auto_applied"] ?? false,
      cashbackAmount: json["cashback_amount"] ?? 0,
      cancelledAt: json["cancelled_at"],
      cancellationReason: json["cancellation_reason"],
      cancellationFee: json["cancellation_fee"] ?? 0,
      cancelledBy: json["cancelled_by"] ?? '',
      midRideCancel: json["mid_ride_cancel"] == null
          ? null
          : RideDetailsMidRideCancel.fromMap(json["mid_ride_cancel"]),
      noShow: RideDetailsRide._parseWaitingNoShow(json),
      isNoShowCancellation: RideDetailsRide._parseIsNoShowCancellation(json),
      rejectedDrivers: json["rejected_drivers"] ?? <dynamic>[],
      blockedDrivers: json["blocked_drivers"] ?? <dynamic>[],
      driverAssignedAt: json["driver_assigned_at"] ?? '',
      driverArrivedAt: json["driver_arrived_at"] ?? '',
      rideStartedAt: json["ride_started_at"] ?? '',
      rideCompletedAt: json["ride_completed_at"],
      riderRating: json["rider_rating"],
      riderRatingComment: json["rider_rating_comment"],
      ratedAt: json["rated_at"],
      driverRating: json["driver_rating"],
      driverRatingComment: json["driver_rating_comment"],
      driverRatedAt: json["driver_rated_at"],
      feedbackText: json["feedback_text"],
      feedbackTags: json["feedback_tags"] ?? <dynamic>[],
      feedbackImages: json["feedback_images"] ?? <dynamic>[],
      feedbackAt: json["feedback_at"],
      ratingTags: json["rating_tags"] ?? <dynamic>[],
      isReviewSkipped: json["is_review_skipped"] ?? false,
      showReviewUi: json["show_review_ui"] ?? false,
      iosActivityToken: json["ios_activity_token"],
      shareToken: json["share_token"] ?? '',
      shareLinkExpiresAt: json["share_link_expires_at"] ?? '',
      isShared: json["is_shared"] ?? false,
      note: json["note"] ?? '',
      latraReferenceNumber: json["latra_reference_number"],
      latraSubmittedAt: json["latra_submitted_at"],
      riderId: json["rider_id"] ?? '',
      transid: json["transid"] ?? '',
      distanceKm: json["distance_km"]?.toDouble() ?? 0.0,
      durationMinutes: json["duration_minutes"] ?? 0,
      searchStartedAt: json["search_started_at"] ?? '',
      preauths: json["preauths"] == null
          ? <RideDetailsPreauth>[]
          : List<RideDetailsPreauth>.from(
              json["preauths"].map((x) => RideDetailsPreauth.fromMap(x)),
            ),
      pdfLinks: json["pdf_links"] == null
          ? <RideDetailsPdfLink>[]
          : List<RideDetailsPdfLink>.from(
              json["pdf_links"].map((x) => RideDetailsPdfLink.fromMap(x)),
            ),
      pendingStopsUpdate: json["pending_stops_update"] == null
          ? null
          : RideDetailsPendingStopsUpdate.fromMap(json["pending_stops_update"]),
      createdAt: createdAtStr ?? '',
      updatedAt: json["updatedAt"] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    "_id": id,
    "status": status,
    "pickup": pickup?.toMap(),
    "destination": destination?.toMap(),
    "stops": stops == null
        ? null
        : List<dynamic>.from(stops!.map((x) => x.toMap())),
    "is_multi_stop": isMultiStop,
    "current_stop_index": currentStopIndex,
    "fare_estimate": fareEstimate,
    "vehicle_type_id": vehicleTypeId == null
        ? null
        : (vehicleTypeId!.idOnly ? vehicleTypeId!.id : vehicleTypeId!.toMap()),
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
    "book_any_vehicle_type_ids": bookAnyVehicleTypeIds,
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
    "cashback_amount": cashbackAmount,
    "cancelled_at": cancelledAt,
    "cancellation_reason": cancellationReason,
    "cancellation_fee": cancellationFee,
    "cancelled_by": cancelledBy,
    "mid_ride_cancel": midRideCancel?.toMap(),
    // Terminal cancel uses boolean `true`; ongoing wait keeps the object
    // so [toRideModel] can arm the SCR-11 no-show countdown.
    "no_show": isNoShowCancellation ? true : noShow?.toJson(),
    "rejected_drivers": rejectedDrivers,
    "blocked_drivers": blockedDrivers,
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
    "feedback_tags": feedbackTags,
    "feedback_images": feedbackImages,
    "feedback_at": feedbackAt,
    "rating_tags": ratingTags,
    "is_review_skipped": isReviewSkipped,
    "show_review_ui": showReviewUi,
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
        ? null
        : List<dynamic>.from(preauths!.map((x) => x.toMap())),
    "pdf_links": pdfLinks == null
        ? null
        : List<dynamic>.from(pdfLinks!.map((x) => x.toMap())),
    "pending_stops_update": pendingStopsUpdate?.toMap(),
    "createdAt": createdAt,
    "updatedAt": updatedAt,
  };

  /// Lets completion/detail flows reuse the [RideModel] parsing logic
  /// (formatting helpers, JSON shape) from this raw response.
  RideModel toRideModel() => RideModel.fromJson(toMap());

  String get promoCodeTrimmed {
    final raw = (promoCode ?? fareBreakdown?.promoCode)?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null') return '';
    return raw;
  }

  int get effectivePromoDiscount =>
      promoDiscount ?? fareBreakdown?.promoDiscount ?? 0;

  int get effectiveCashbackAmount =>
      cashbackAmount ?? fareBreakdown?.cashbackAmount ?? 0;

  bool get effectivePromoAutoApplied =>
      promoAutoApplied ?? fareBreakdown?.promoAutoApplied ?? false;

  /// Cashback promo: fare not reduced; cashback amount credited.
  bool get hasCashbackPromo {
    if (promoCodeTrimmed.isEmpty) return false;
    if (fareBreakdown?.isCashback == true && effectiveCashbackAmount > 0) {
      return true;
    }
    return effectiveCashbackAmount > 0 && effectivePromoDiscount <= 0;
  }

  /// Classic fare discount promo.
  bool get hasFareDiscountPromo =>
      promoCodeTrimmed.isNotEmpty && effectivePromoDiscount > 0;

  bool get hasPromoBenefit => hasCashbackPromo || hasFareDiscountPromo;

  int get promoBenefitAmount =>
      hasCashbackPromo ? effectiveCashbackAmount : effectivePromoDiscount;

  bool get isCancelled => status == 'cancelled';

  bool get isCompleted => status == 'ride_completed';

  bool get isNoDriverFound => status == 'no_driver_found';

  bool get isMidRideDriverCancel =>
      midRideCancel?.isDriverMidRideCancel == true;

  String get vehicleDisplayNameResolved =>
      (vehicleTypeId?.displayName ??
              vehicleSnapshot?.displayName ??
              vehicleSnapshot?.vehicleName ??
              '')
          .trim();

  String get vehicleKeyResolved =>
      (vehicleTypeId?.key ?? vehicleSnapshot?.vehicleType ?? '').trim();

  int get displayRideCharge {
    if (isMidRideDriverCancel) {
      return midRideCancel?.displayChargeAmount ?? 0;
    }
    if (isCancelled) return cancellationFee ?? 0;
    return fareBreakdown?.rideCharge ?? fareEstimate ?? 0;
  }

  int get displayBookingFee {
    if (isCancelled || isMidRideDriverCancel) return 0;
    return fareBreakdown?.bookingFee ?? 0;
  }

  int get displayTotalAmount {
    if (isMidRideDriverCancel) {
      return midRideCancel?.displayChargeAmount ?? 0;
    }
    if (isCancelled) return cancellationFee ?? 0;
    final amountCharged = fareBreakdown?.amountCharged;
    if (amountCharged != null && amountCharged > 0) {
      return amountCharged;
    }
    final total = fareBreakdown?.totalAmount;
    if (total != null && total > 0) return total;
    final fare = finalFare;
    if (fare is num) return fare.toInt();
    return fareEstimate ?? 0;
  }

  /// Hold/preauth amount used to derive net refund on cancelled rides.
  int get displayBlockedHoldAmount {
    final blocked = blockedAmount ?? 0;
    if (blocked > 0) return blocked;
    return preauthTotal ?? 0;
  }

  /// Amount captured as cancel/no-show fee.
  int get displayCancellationFeeAmount {
    final fee = cancellationFee ?? 0;
    if (fee > 0) return fee;
    final captured = cancellationFeeCaptured ?? 0;
    if (captured > 0) return captured;
    return captureTotal ?? 0;
  }

  /// Released hold after fee capture (`hold - fee`), never negative.
  int get displayNetRefundAmount {
    if (isMidRideDriverCancel) {
      final fromApi = midRideCancel?.netRefund;
      if (fromApi != null && fromApi > 0) return fromApi;
      final released = midRideCancel?.releasedAmount;
      if (released != null && released > 0) return released;
      final charged = midRideCancel?.displayChargeAmount ?? 0;
      final refund = displayBlockedHoldAmount - charged;
      return refund > 0 ? refund : 0;
    }
    if (!isCancelled) return 0;
    final refund = displayBlockedHoldAmount - displayCancellationFeeAmount;
    return refund > 0 ? refund : 0;
  }

  String get displayCancellationReason {
    final raw = cancellationReason?.toString().trim() ?? '';
    return raw;
  }

  /// System / no-show cancels have machine codes (e.g. `rider_no_show`) — hide in UI.
  bool get shouldShowCancellationReason {
    if (!isCancelled || isMidRideDriverCancel) return false;
    if (isNoShowCancellation) return false;
    final by = (cancelledBy ?? '').trim().toLowerCase();
    if (by == 'system') return false;
    final reason = displayCancellationReason.toLowerCase();
    if (reason.isEmpty) return false;
    if (reason == 'rider_no_show' || reason == 'no_show') return false;
    return true;
  }

  /// Waiting `no_show` object for ongoing rides; null when terminal / absent.
  static RideNoShowInfoModel? _parseWaitingNoShow(Map<String, dynamic> json) {
    if (_parseIsNoShowCancellation(json)) return null;
    return rideNoShowInfoFromJson(json['no_show']);
  }

  /// Detects terminal no-show from boolean or fired object payloads.
  static bool _parseIsNoShowCancellation(Map<String, dynamic> json) {
    final raw = json['no_show'];
    if (raw == true) return true;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final status = map['status']?.toString().trim().toLowerCase() ?? '';
      if (status == 'fired' ||
          status == 'completed' ||
          status == 'captured' ||
          map['fired_at'] != null) {
        return true;
      }
      // Cancelled ride with a no_show object is treated as no-show terminal.
      if ((json['status']?.toString() ?? '') == 'cancelled') return true;
    }
    final reason =
        json['cancellation_reason']?.toString().trim().toLowerCase() ?? '';
    if (reason == 'rider_no_show' || reason == 'no_show') return true;
    return false;
  }
}

class RideDetailsPlace {
  RideDetailsLocation? location;
  int? index;
  String? status;
  String? subtaskId;
  dynamic arrivedAt;
  dynamic completedAt;
  double? lat;
  double? lng;
  String? address;

  RideDetailsPlace({
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

  factory RideDetailsPlace.fromJson(String str) =>
      RideDetailsPlace.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsPlace.fromMap(Map<String, dynamic> json) =>
      RideDetailsPlace(
        location: json["location"] == null
            ? null
            : RideDetailsLocation.fromMap(json["location"]),
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

class RideDetailsLocation {
  String? type;
  List<double>? coordinates;

  RideDetailsLocation({this.type, this.coordinates});

  factory RideDetailsLocation.fromJson(String str) =>
      RideDetailsLocation.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsLocation.fromMap(Map<String, dynamic> json) =>
      RideDetailsLocation(
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

class RideDetailsPickup {
  RideDetailsLocation? location;
  double? lat;
  double? lng;
  String? address;

  RideDetailsPickup({this.location, this.lat, this.lng, this.address});

  factory RideDetailsPickup.fromJson(String str) =>
      RideDetailsPickup.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsPickup.fromMap(Map<String, dynamic> json) =>
      RideDetailsPickup(
        location: json["location"] == null
            ? null
            : RideDetailsLocation.fromMap(json["location"]),
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

class RideDetailsDriverSnapshot {
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

  RideDetailsDriverSnapshot({
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

  factory RideDetailsDriverSnapshot.fromJson(String str) =>
      RideDetailsDriverSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsDriverSnapshot.fromMap(Map<String, dynamic> json) =>
      RideDetailsDriverSnapshot(
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

class RideDetailsVehicleSnapshot {
  String? vehicleType;
  String? vehicleName;
  String? displayName;

  RideDetailsVehicleSnapshot({
    this.vehicleType,
    this.vehicleName,
    this.displayName,
  });

  factory RideDetailsVehicleSnapshot.fromJson(String str) =>
      RideDetailsVehicleSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsVehicleSnapshot.fromMap(Map<String, dynamic> json) =>
      RideDetailsVehicleSnapshot(
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

class RideDetailsFareBreakdown {
  String? currency;
  int? baseFare;
  double? distanceKm;
  int? distanceCharge;
  int? durationMinutes;
  int? timeCharge;
  int? waypointCharge;
  /// Mid-ride only: fee for the most recently added stop. 0/absent otherwise.
  /// Prefer [stopCharges] for the full itemized UI; do not replace with this.
  int? stopAddedCharge;
  /// Per-stop fees for every stop on the ride (initial booking + later adds).
  /// Prefer over [waypointCharge] (legacy aggregate, kept for backward compat).
  List<FareStopCharge>? stopCharges;
  /// Extra amount when the minimum-fare floor applies. Render only when > 0.
  int? minimumFareAdjustment;
  int? minimumFare;
  bool? minimumFareApplied;
  int? originalFare;
  int? rideCharge;
  int? bookingFee;
  String? promoCode;
  int? promoDiscount;
  bool? promoAutoApplied;
  String? promoDescription;
  bool? isCashback;
  int? cashbackAmount;
  int? totalAmount;
  int? amountCharged;

  RideDetailsFareBreakdown({
    this.currency,
    this.baseFare,
    this.distanceKm,
    this.distanceCharge,
    this.durationMinutes,
    this.timeCharge,
    this.waypointCharge,
    this.stopAddedCharge,
    this.stopCharges,
    this.minimumFareAdjustment,
    this.minimumFare,
    this.minimumFareApplied,
    this.originalFare,
    this.rideCharge,
    this.bookingFee,
    this.promoCode,
    this.promoDiscount,
    this.promoAutoApplied,
    this.promoDescription,
    this.isCashback,
    this.cashbackAmount,
    this.totalAmount,
    this.amountCharged,
  });

  factory RideDetailsFareBreakdown.fromJson(String str) =>
      RideDetailsFareBreakdown.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsFareBreakdown.fromMap(Map<String, dynamic> json) =>
      RideDetailsFareBreakdown(
        currency: json["currency"] ?? '',
        baseFare: json["base_fare"] ?? 0,
        distanceKm: json["distance_km"]?.toDouble() ?? 0.0,
        distanceCharge: json["distance_charge"] ?? 0,
        durationMinutes: json["duration_minutes"] ?? 0,
        timeCharge: json["time_charge"] ?? 0,
        waypointCharge: json["waypoint_charge"] ?? 0,
        stopAddedCharge: json["stop_added_charge"] ?? 0,
        stopCharges: FareStopCharge.listFromJson(json["stop_charges"]),
        minimumFareAdjustment: json["minimum_fare_adjustment"] ?? 0,
        minimumFare: json["minimum_fare"] ?? 0,
        minimumFareApplied: json["minimum_fare_applied"] ?? false,
        originalFare: json["original_fare"] ?? 0,
        rideCharge: json["ride_charge"] ?? 0,
        bookingFee: json["booking_fee"] ?? 0,
        promoCode: json["promo_code"] ?? '',
        promoDiscount: json["promo_discount"] ?? 0,
        promoAutoApplied: json["promo_auto_applied"] ?? false,
        promoDescription: json["promo_description"] ?? '',
        isCashback: json["is_cashback"] ?? false,
        cashbackAmount: json["cashback_amount"] ?? 0,
        totalAmount: json["total_amount"] ?? 0,
        amountCharged: json["amount_charged"] ?? 0,
      );

  Map<String, dynamic> toMap() => {
    "currency": currency,
    "base_fare": baseFare,
    "distance_km": distanceKm,
    "distance_charge": distanceCharge,
    "duration_minutes": durationMinutes,
    "time_charge": timeCharge,
    "waypoint_charge": waypointCharge,
    "stop_added_charge": stopAddedCharge,
    "stop_charges": stopCharges?.map((e) => e.toMap()).toList() ?? [],
    "minimum_fare_adjustment": minimumFareAdjustment,
    "minimum_fare": minimumFare,
    "minimum_fare_applied": minimumFareApplied,
    "original_fare": originalFare,
    "ride_charge": rideCharge,
    "booking_fee": bookingFee,
    "promo_code": promoCode,
    "promo_discount": promoDiscount,
    "promo_auto_applied": promoAutoApplied,
    "promo_description": promoDescription,
    "is_cashback": isCashback,
    "cashback_amount": cashbackAmount,
    "total_amount": totalAmount,
    "amount_charged": amountCharged,
  };
}

class RideDetailsPreauth {
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
  RideDetailsPreauthRawResponse? rawResponse;
  dynamic captureResponse;
  String? settledAt;
  String? transid;
  int? amount;
  String? type;
  String? createdAt;

  RideDetailsPreauth({
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

  factory RideDetailsPreauth.fromJson(String str) =>
      RideDetailsPreauth.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsPreauth.fromMap(Map<String, dynamic> json) =>
      RideDetailsPreauth(
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
            : RideDetailsPreauthRawResponse.fromMap(json["raw_response"]),
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

class RideDetailsPreauthRawResponse {
  String? transid;
  String? result;
  String? resultcode;
  String? reference;
  String? message;
  String? currency;
  int? reserved;
  int? available;

  RideDetailsPreauthRawResponse({
    this.transid,
    this.result,
    this.resultcode,
    this.reference,
    this.message,
    this.currency,
    this.reserved,
    this.available,
  });

  factory RideDetailsPreauthRawResponse.fromJson(String str) =>
      RideDetailsPreauthRawResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsPreauthRawResponse.fromMap(Map<String, dynamic> json) =>
      RideDetailsPreauthRawResponse(
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

/// Full vehicle-type document for `vehicle_type_id` (matches
/// `vehicle_types_response.dart` `VehicleType`). Some payloads only send the
/// bare id string, so [fromMap] accepts either a [Map] or a [String].
class RideDetailsVehicleType {
  int? cancellationFee;
  int? bookingFee;
  int? waypointFee;
  int? cashbackPercent;
  int? maxDistanceKm;
  bool? bookAnyEligible;
  bool? isActive;
  int? sortOrder;
  String? id;
  String? name;
  int? baseFare;
  String? createdAt;
  String? displayName;
  String? key;
  int? maxPassengers;
  int? minimumFare;
  int? perKmRate;
  int? perMinRate;
  String? updatedAt;
  int? v;

  /// True when this instance was built from a bare id string (no nested
  /// vehicle-type document was returned by the API).
  final bool idOnly;

  RideDetailsVehicleType({
    this.cancellationFee,
    this.bookingFee,
    this.waypointFee,
    this.cashbackPercent,
    this.maxDistanceKm,
    this.bookAnyEligible,
    this.isActive,
    this.sortOrder,
    this.id,
    this.name,
    this.baseFare,
    this.createdAt,
    this.displayName,
    this.key,
    this.maxPassengers,
    this.minimumFare,
    this.perKmRate,
    this.perMinRate,
    this.updatedAt,
    this.v,
    this.idOnly = false,
  });

  /// Accepts a [Map] (full vehicle-type document) or a [String] (`_id` only).
  factory RideDetailsVehicleType.fromMap(dynamic source) {
    if (source is String) {
      return RideDetailsVehicleType(id: source, idOnly: true);
    }
    final json = source is Map<String, dynamic>
        ? source
        : Map<String, dynamic>.from(source as Map);
    return RideDetailsVehicleType(
      cancellationFee: json["cancellation_fee"],
      bookingFee: json["booking_fee"],
      waypointFee: json["waypoint_fee"],
      cashbackPercent: json["cashback_percent"],
      maxDistanceKm: json["max_distance_km"],
      bookAnyEligible: json["book_any_eligible"],
      isActive: json["is_active"],
      sortOrder: json["sort_order"],
      id: json["_id"]?.toString(),
      name: json["name"],
      baseFare: json["base_fare"],
      createdAt: json["createdAt"],
      displayName: json["display_name"],
      key: json["key"],
      maxPassengers: json["max_passengers"],
      minimumFare: json["minimum_fare"],
      perKmRate: json["per_km_rate"],
      perMinRate: json["per_min_rate"],
      updatedAt: json["updatedAt"],
      v: json["__v"],
    );
  }

  Map<String, dynamic> toMap() => {
    "cancellation_fee": cancellationFee,
    "booking_fee": bookingFee,
    "waypoint_fee": waypointFee,
    "cashback_percent": cashbackPercent,
    "max_distance_km": maxDistanceKm,
    "book_any_eligible": bookAnyEligible,
    "is_active": isActive,
    "sort_order": sortOrder,
    "_id": id,
    "name": name,
    "base_fare": baseFare,
    "createdAt": createdAt,
    "display_name": displayName,
    "key": key,
    "max_passengers": maxPassengers,
    "minimum_fare": minimumFare,
    "per_km_rate": perKmRate,
    "per_min_rate": perMinRate,
    "updatedAt": updatedAt,
    "__v": v,
  };
}

class RideDetailsPdfLink {
  String? url;
  String? token;
  String? originalName;
  String? expiresAt;
  String? uploadedAt;

  RideDetailsPdfLink({
    this.url,
    this.token,
    this.originalName,
    this.expiresAt,
    this.uploadedAt,
  });

  factory RideDetailsPdfLink.fromJson(String str) =>
      RideDetailsPdfLink.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsPdfLink.fromMap(Map<String, dynamic> json) =>
      RideDetailsPdfLink(
        url: json["url"],
        token: json["token"],
        originalName: json["original_name"],
        expiresAt: json["expires_at"],
        uploadedAt: json["uploaded_at"],
      );

  Map<String, dynamic> toMap() => {
    "url": url,
    "token": token,
    "original_name": originalName,
    "expires_at": expiresAt,
    "uploaded_at": uploadedAt,
  };
}

/// Backend-owned partial-charge state when a driver ends a trip mid-ride
/// (see `mid_ride_cancel_model.dart` for the in-app model counterpart).
class RideDetailsMidRideCancel {
  RideDetailsDaLastLocation? daLastLocation;
  String? reason;
  String? reasonText;
  double? distanceCoveredKm;
  String? distanceSource;
  int? elapsedMinutes;
  int? partialFare;
  String? captureAt;
  String? captureStatus;
  int? capturedAmount;
  String? message;
  bool? disputed;
  dynamic disputedAt;
  dynamic disputeReason;
  bool? waived;
  double? daDistanceKm;
  String? cancelledAt;
  int? netRefund;
  int? releasedAmount;
  String? disputeDeadline;
  bool? canDispute;

  RideDetailsMidRideCancel({
    this.daLastLocation,
    this.reason,
    this.reasonText,
    this.distanceCoveredKm,
    this.distanceSource,
    this.elapsedMinutes,
    this.partialFare,
    this.captureAt,
    this.captureStatus,
    this.capturedAmount,
    this.message,
    this.disputed,
    this.disputedAt,
    this.disputeReason,
    this.waived,
    this.daDistanceKm,
    this.cancelledAt,
    this.netRefund,
    this.releasedAmount,
    this.disputeDeadline,
    this.canDispute,
  });

  factory RideDetailsMidRideCancel.fromJson(String str) =>
      RideDetailsMidRideCancel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsMidRideCancel.fromMap(Map<String, dynamic> json) =>
      RideDetailsMidRideCancel(
        daLastLocation: json["da_last_location"] == null
            ? null
            : RideDetailsDaLastLocation.fromMap(json["da_last_location"]),
        reason: json["reason"],
        reasonText: json["reason_text"],
        distanceCoveredKm: json["distance_covered_km"]?.toDouble(),
        distanceSource: json["distance_source"],
        elapsedMinutes: json["elapsed_minutes"],
        partialFare: json["partial_fare"],
        captureAt: json["capture_at"],
        captureStatus: json["capture_status"],
        capturedAmount: json["captured_amount"],
        message: json["message"],
        disputed: json["disputed"],
        disputedAt: json["disputed_at"],
        disputeReason: json["dispute_reason"],
        waived: json["waived"],
        daDistanceKm: json["da_distance_km"]?.toDouble(),
        cancelledAt: json["cancelled_at"],
        netRefund: json["net_refund"],
        releasedAmount: json["released_amount"],
        disputeDeadline: json["dispute_deadline"],
        canDispute: json["can_dispute"],
      );

  Map<String, dynamic> toMap() => {
    "da_last_location": daLastLocation?.toMap(),
    "reason": reason,
    "reason_text": reasonText,
    "distance_covered_km": distanceCoveredKm,
    "distance_source": distanceSource,
    "elapsed_minutes": elapsedMinutes,
    "partial_fare": partialFare,
    "capture_at": captureAt,
    "capture_status": captureStatus,
    "captured_amount": capturedAmount,
    "message": message,
    "disputed": disputed,
    "disputed_at": disputedAt,
    "dispute_reason": disputeReason,
    "waived": waived,
    "da_distance_km": daDistanceKm,
    "cancelled_at": cancelledAt,
    "net_refund": netRefund,
    "released_amount": releasedAmount,
    "dispute_deadline": disputeDeadline,
    "can_dispute": canDispute,
  };

  bool get isDriverMidRideCancel => captureStatus != null || partialFare != null;

  int get displayChargeAmount => capturedAmount ?? partialFare ?? 0;

  /// Same decision logic as `MidRideCancelModel.needsLiveChargeScreen`.
  bool get needsLiveChargeScreen {
    switch (captureStatus) {
      case 'scheduled':
      case 'disputed':
        return true;
      case 'captured':
      case 'released':
      case 'waived':
        return false;
      default:
        return (canDispute ?? false) && (partialFare ?? 0) > 0;
    }
  }
}

class RideDetailsDaLastLocation {
  double? lat;
  double? lng;

  RideDetailsDaLastLocation({this.lat, this.lng});

  factory RideDetailsDaLastLocation.fromJson(String str) =>
      RideDetailsDaLastLocation.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsDaLastLocation.fromMap(Map<String, dynamic> json) =>
      RideDetailsDaLastLocation(
        lat: json["lat"]?.toDouble(),
        lng: json["lng"]?.toDouble(),
      );

  Map<String, dynamic> toMap() => {"lat": lat, "lng": lng};
}

/// Mirrors `PendingStopsUpdateModel` needs (`lib/core/data/models/ride_model.dart`)
/// so `RideModel.fromJson(ride.toMap())` can rebuild it directly.
class RideDetailsPendingStopsUpdate {
  List<RideDetailsPlace>? stops;
  String? status;
  int? deltaAmount;
  String? direction;
  int? newFare;
  String? validationId;
  String? expiresAt;
  String? idempotencyKey;

  RideDetailsPendingStopsUpdate({
    this.stops,
    this.status,
    this.deltaAmount,
    this.direction,
    this.newFare,
    this.validationId,
    this.expiresAt,
    this.idempotencyKey,
  });

  factory RideDetailsPendingStopsUpdate.fromJson(String str) =>
      RideDetailsPendingStopsUpdate.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideDetailsPendingStopsUpdate.fromMap(Map<String, dynamic> json) =>
      RideDetailsPendingStopsUpdate(
        stops: json["stops"] == null
            ? []
            : List<RideDetailsPlace>.from(
                json["stops"]!.map((x) => RideDetailsPlace.fromMap(x)),
              ),
        status: json["status"],
        deltaAmount: json["delta_amount"],
        direction: json["direction"],
        newFare: json["new_fare"] ?? json["new_fare_estimate"],
        validationId: json["block_update_validation_id"],
        expiresAt: json["expires_at"],
        idempotencyKey: json["idempotency_key"],
      );

  Map<String, dynamic> toMap() => {
    "stops": stops == null
        ? []
        : List<dynamic>.from(stops!.map((x) => x.toMap())),
    "status": status,
    "delta_amount": deltaAmount,
    "direction": direction,
    "new_fare": newFare,
    "block_update_validation_id": validationId,
    "expires_at": expiresAt,
    "idempotency_key": idempotencyKey,
  };
}
