import 'dart:convert';

class RideHistoryModelResponse {
  int? statusCode;
  Data? data;

  RideHistoryModelResponse({
    this.statusCode,
    this.data,
  });

  factory RideHistoryModelResponse.fromRawJson(String str) => RideHistoryModelResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory RideHistoryModelResponse.fromJson(Map<String, dynamic> json) => RideHistoryModelResponse(
    statusCode: json["status_code"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "data": data?.toJson(),
  };
}

class Data {
  List<Ride>? rides;
  Pagination? pagination;

  Data({
    this.rides,
    this.pagination,
  });

  factory Data.fromRawJson(String str) => Data.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    rides: json["rides"] == null ? [] : List<Ride>.from(json["rides"]!.map((x) => Ride.fromJson(x))),
    pagination: json["pagination"] == null ? null : Pagination.fromJson(json["pagination"]),
  );

  Map<String, dynamic> toJson() => {
    "rides": rides == null ? [] : List<dynamic>.from(rides!.map((x) => x.toJson())),
    "pagination": pagination?.toJson(),
  };
}

class Pagination {
  int? total;
  int? page;
  int? limit;
  int? totalPages;

  Pagination({
    this.total,
    this.page,
    this.limit,
    this.totalPages,
  });

  factory Pagination.fromRawJson(String str) => Pagination.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Pagination.fromJson(Map<String, dynamic> json) => Pagination(
    total: json["total"],
    page: json["page"],
    limit: json["limit"],
    totalPages: json["total_pages"],
  );

  Map<String, dynamic> toJson() => {
    "total": total,
    "page": page,
    "limit": limit,
    "total_pages": totalPages,
  };
}

class Ride {
  String? id;
  FareBreakdown? fareBreakdown;
  String? status;
  bool? isMultiStop;
  int? currentStopIndex;
  int? finalFare;
  String? paymentStatus;
  int? cancellationFee;
  MidRideCancel? midRideCancel;
  DriverSnapshot? driverSnapshot;
  VehicleSnapshot? vehicleSnapshot;
  int? riderRating;
  List<String>? ratingTags;
  VehicleTypeId? vehicleTypeId;
  Pickup? pickup;
  Destination? destination;
  List<Destination>? stops;
  int? fareEstimate;
  double? distanceKm;
  int? durationMinutes;
  String? paymentMethod;
  DateTime? createdAt;
  String? cancelledBy;

  Ride({
    this.id,
    this.fareBreakdown,
    this.status,
    this.isMultiStop,
    this.currentStopIndex,
    this.finalFare,
    this.paymentStatus,
    this.cancellationFee,
    this.midRideCancel,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.riderRating,
    this.ratingTags,
    this.vehicleTypeId,
    this.pickup,
    this.destination,
    this.stops,
    this.fareEstimate,
    this.distanceKm,
    this.durationMinutes,
    this.paymentMethod,
    this.createdAt,
    this.cancelledBy,
  });

  factory Ride.fromRawJson(String str) => Ride.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
    id: json["_id"],
    fareBreakdown: json["fare_breakdown"] == null ? null : FareBreakdown.fromJson(json["fare_breakdown"]),
    status:json["status"],
    isMultiStop: json["is_multi_stop"],
    currentStopIndex: json["current_stop_index"],
    finalFare: json["final_fare"],
    paymentStatus: json["payment_status"],
    cancellationFee: json["cancellation_fee"],
    midRideCancel: json["mid_ride_cancel"] == null ? null : MidRideCancel.fromJson(json["mid_ride_cancel"]),
    driverSnapshot: json["driver_snapshot"] == null ? null : DriverSnapshot.fromJson(json["driver_snapshot"]),
    vehicleSnapshot: json["vehicle_snapshot"] == null ? null : VehicleSnapshot.fromJson(json["vehicle_snapshot"]),
    riderRating: json["rider_rating"],
    ratingTags: json["rating_tags"] == null ? [] : List<String>.from(json["rating_tags"]!.map((x) => x)),
    vehicleTypeId: json["vehicle_type_id"] == null ? null : VehicleTypeId.fromJson(json["vehicle_type_id"]),
    pickup: json["pickup"] == null ? null : Pickup.fromJson(json["pickup"]),
    destination: json["destination"] == null ? null : Destination.fromJson(json["destination"]),
    stops: json["stops"] == null ? [] : List<Destination>.from(json["stops"]!.map((x) => Destination.fromJson(x))),
    fareEstimate: json["fare_estimate"],
    distanceKm: json["distance_km"]?.toDouble(),
    durationMinutes: json["duration_minutes"],
    paymentMethod: json["payment_method"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    cancelledBy: json["cancelled_by"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "fare_breakdown": fareBreakdown?.toJson(),
    "status": status,
    "is_multi_stop": isMultiStop,
    "current_stop_index": currentStopIndex,
    "final_fare": finalFare,
    "payment_status": paymentStatus,
    "cancellation_fee": cancellationFee,
    "mid_ride_cancel": midRideCancel?.toJson(),
    "driver_snapshot": driverSnapshot?.toJson(),
    "vehicle_snapshot": vehicleSnapshot?.toJson(),
    "rider_rating": riderRating,
    "rating_tags": ratingTags == null ? [] : List<dynamic>.from(ratingTags!.map((x) => x)),
    "vehicle_type_id": vehicleTypeId?.toJson(),
    "pickup": pickup?.toJson(),
    "destination": destination?.toJson(),
    "stops": stops == null ? [] : List<dynamic>.from(stops!.map((x) => x.toJson())),
    "fare_estimate": fareEstimate,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
    "payment_method": paymentMethod,
    "createdAt": createdAt?.toIso8601String(),
    "cancelled_by": cancelledBy,
  };
}

class Destination {
  Location? location;
  int? index;
  String? status;
  String? subtaskId;
  DateTime? arrivedAt;
  DateTime? completedAt;
  double? lat;
  double? lng;
  String? address;

  Destination({
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

  factory Destination.fromRawJson(String str) => Destination.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
    location: json["location"] == null ? null : Location.fromJson(json["location"]),
    index: json["index"],
    status: json["status"],
    subtaskId: json["subtask_id"],
    arrivedAt: json["arrived_at"] == null ? null : DateTime.parse(json["arrived_at"]),
    completedAt: json["completed_at"] == null ? null : DateTime.parse(json["completed_at"]),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
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

class Location {
  String? type;
  List<double>? coordinates;

  Location({
    this.type,
    this.coordinates,
  });

  factory Location.fromRawJson(String str) => Location.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    type: json["type"],
    coordinates: json["coordinates"] == null ? [] : List<double>.from(json["coordinates"]!.map((x) => x?.toDouble())),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "coordinates": coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}



class DriverSnapshot {
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

  DriverSnapshot({
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
  });

  factory DriverSnapshot.fromRawJson(String str) => DriverSnapshot.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DriverSnapshot.fromJson(Map<String, dynamic> json) => DriverSnapshot(
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
    vehicleYear: json["vehicle_year"],
    rating: json["rating"],
  );

  Map<String, dynamic> toJson() => {
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
  };
}



class FareBreakdown {
  int? rideCharge;
  int? bookingFee;
  int? totalAmount;

  FareBreakdown({
    this.rideCharge,
    this.bookingFee,
    this.totalAmount,
  });

  factory FareBreakdown.fromRawJson(String str) => FareBreakdown.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FareBreakdown.fromJson(Map<String, dynamic> json) => FareBreakdown(
    rideCharge: json["ride_charge"],
    bookingFee: json["booking_fee"],
    totalAmount: json["total_amount"],
  );

  Map<String, dynamic> toJson() => {
    "ride_charge": rideCharge,
    "booking_fee": bookingFee,
    "total_amount": totalAmount,
  };
}

class MidRideCancel {
  DaLastLocation? daLastLocation;
  String? reason;
  dynamic reasonText;
  double? distanceCoveredKm;
  String? distanceSource;
  int? elapsedMinutes;
  int? partialFare;
  DateTime? captureAt;
  String? captureStatus;
  int? capturedAmount;
  String? message;
  bool? disputed;
  dynamic disputedAt;
  dynamic disputeReason;
  bool? waived;
  double? daDistanceKm;
  DateTime? cancelledAt;

  MidRideCancel({
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
  });

  factory MidRideCancel.fromRawJson(String str) => MidRideCancel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory MidRideCancel.fromJson(Map<String, dynamic> json) => MidRideCancel(
    daLastLocation: json["da_last_location"] == null ? null : DaLastLocation.fromJson(json["da_last_location"]),
    reason: json["reason"],
    reasonText: json["reason_text"],
    distanceCoveredKm: json["distance_covered_km"]?.toDouble(),
    distanceSource: json["distance_source"],
    elapsedMinutes: json["elapsed_minutes"],
    partialFare: json["partial_fare"],
    captureAt: json["capture_at"] == null ? null : DateTime.parse(json["capture_at"]),
    captureStatus: json["capture_status"],
    capturedAmount: json["captured_amount"],
    message: json["message"],
    disputed: json["disputed"],
    disputedAt: json["disputed_at"],
    disputeReason: json["dispute_reason"],
    waived: json["waived"],
    daDistanceKm: json["da_distance_km"]?.toDouble(),
    cancelledAt: json["cancelled_at"] == null ? null : DateTime.parse(json["cancelled_at"]),
  );

  Map<String, dynamic> toJson() => {
    "da_last_location": daLastLocation?.toJson(),
    "reason": reason,
    "reason_text": reasonText,
    "distance_covered_km": distanceCoveredKm,
    "distance_source": distanceSource,
    "elapsed_minutes": elapsedMinutes,
    "partial_fare": partialFare,
    "capture_at": captureAt?.toIso8601String(),
    "capture_status": captureStatus,
    "captured_amount": capturedAmount,
    "message": message,
    "disputed": disputed,
    "disputed_at": disputedAt,
    "dispute_reason": disputeReason,
    "waived": waived,
    "da_distance_km": daDistanceKm,
    "cancelled_at": cancelledAt?.toIso8601String(),
  };
}

class DaLastLocation {
  double? lat;
  double? lng;

  DaLastLocation({
    this.lat,
    this.lng,
  });

  factory DaLastLocation.fromRawJson(String str) => DaLastLocation.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory DaLastLocation.fromJson(Map<String, dynamic> json) => DaLastLocation(
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "lat": lat,
    "lng": lng,
  };
}



class Pickup {
  Location? location;
  double? lat;
  double? lng;
  String? address;

  Pickup({
    this.location,
    this.lat,
    this.lng,
    this.address,
  });

  factory Pickup.fromRawJson(String str) => Pickup.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Pickup.fromJson(Map<String, dynamic> json) => Pickup(
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



class VehicleSnapshot {
  String? vehicleType;
  String? vehicleName;
  String? displayName;

  VehicleSnapshot({
    this.vehicleType,
    this.vehicleName,
    this.displayName,
  });

  factory VehicleSnapshot.fromRawJson(String str) => VehicleSnapshot.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleSnapshot.fromJson(Map<String, dynamic> json) => VehicleSnapshot(
    vehicleType: json["vehicle_type"],
    vehicleName: json["vehicle_name"],
    displayName: json["display_name"],
  );

  Map<String, dynamic> toJson() => {
    "vehicle_type": vehicleType,
    "vehicle_name": vehicleName,
    "display_name": displayName,
  };
}


class VehicleTypeId {
  String? id;
  String? name;
  int? v;
  int? cancellationFee;
  int? cashbackPercent;
  DateTime? createdAt;
  String? displayName;
  bool? isActive;
  String? key;
  int? maxPassengers;
  int? sortOrder;
  DateTime? updatedAt;
  int? maxDistanceKm;
  bool? bookAnyEligible;

  VehicleTypeId({
    this.id,
    this.name,
    this.v,
    this.cancellationFee,
    this.cashbackPercent,
    this.createdAt,
    this.displayName,
    this.isActive,
    this.key,
    this.maxPassengers,
    this.sortOrder,
    this.updatedAt,
    this.maxDistanceKm,
    this.bookAnyEligible,
  });

  factory VehicleTypeId.fromRawJson(String str) => VehicleTypeId.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleTypeId.fromJson(Map<String, dynamic> json) => VehicleTypeId(
    id: json["_id"],
    name: json["name"],
    v: json["__v"],
    cancellationFee: json["cancellation_fee"],
    cashbackPercent: json["cashback_percent"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    displayName: json["display_name"],
    isActive: json["is_active"],
    key: json["key"],
    maxPassengers: json["max_passengers"],
    sortOrder: json["sort_order"],
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    maxDistanceKm: json["max_distance_km"],
    bookAnyEligible: json["book_any_eligible"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "__v": v,
    "cancellation_fee": cancellationFee,
    "cashback_percent": cashbackPercent,
    "createdAt": createdAt?.toIso8601String(),
    "display_name":displayName,
    "is_active": isActive,
    "key": key,
    "max_passengers": maxPassengers,
    "sort_order": sortOrder,
    "updatedAt": updatedAt?.toIso8601String(),
    "max_distance_km": maxDistanceKm,
    "book_any_eligible": bookAnyEligible,
  };
}

