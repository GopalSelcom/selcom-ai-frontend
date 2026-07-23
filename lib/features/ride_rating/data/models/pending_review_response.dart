import 'dart:convert';

class PendingReviewResponse {
  int? statusCode;
  PendingReviewData? data;

  PendingReviewResponse({this.statusCode, this.data});

  factory PendingReviewResponse.fromJson(String str) =>
      PendingReviewResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PendingReviewResponse.fromMap(Map<String, dynamic> json) =>
      PendingReviewResponse(
        statusCode: json["status_code"],
        data: json["data"] == null
            ? null
            : PendingReviewData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "data": data?.toMap(),
  };
}

class PendingReviewData {
  PendingReview? pendingReview;

  PendingReviewData({this.pendingReview});

  factory PendingReviewData.fromJson(String str) =>
      PendingReviewData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PendingReviewData.fromMap(Map<String, dynamic> json) =>
      PendingReviewData(
        pendingReview: json["pending_review"] == null
            ? null
            : PendingReview.fromMap(json["pending_review"]),
      );

  Map<String, dynamic> toMap() => {"pending_review": pendingReview?.toMap()};
}

class PendingReview {
  String? rideId;
  String? transid;
  DriverSnapshot? driverSnapshot;
  VehicleSnapshot? vehicleSnapshot;
  Pickup? pickup;
  PendingReviewDestination? destination;
  int? finalFare;
  String? rideCompletedAt;
  int? riderRating;

  PendingReview({
    this.rideId,
    this.transid,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.pickup,
    this.destination,
    this.finalFare,
    this.rideCompletedAt,
    this.riderRating,
  });

  factory PendingReview.fromJson(String str) =>
      PendingReview.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PendingReview.fromMap(Map<String, dynamic> json) => PendingReview(
    rideId: json["ride_id"],
    transid: json["transid"],
    driverSnapshot: json["driver_snapshot"] == null
        ? null
        : DriverSnapshot.fromMap(json["driver_snapshot"]),
    vehicleSnapshot: json["vehicle_snapshot"] == null
        ? null
        : VehicleSnapshot.fromMap(json["vehicle_snapshot"]),
    pickup: json["pickup"] == null ? null : Pickup.fromMap(json["pickup"]),
    destination: json["destination"] == null
        ? null
        : PendingReviewDestination.fromMap(json["destination"]),
    finalFare: json["final_fare"],
    rideCompletedAt: json["ride_completed_at"],
    riderRating: json["rider_rating"],
  );

  Map<String, dynamic> toMap() => {
    "ride_id": rideId,
    "transid": transid,
    "driver_snapshot": driverSnapshot?.toMap(),
    "vehicle_snapshot": vehicleSnapshot?.toMap(),
    "pickup": pickup?.toMap(),
    "destination": destination?.toMap(),
    "final_fare": finalFare,
    "ride_completed_at": rideCompletedAt,
    "rider_rating": riderRating,
  };
}

class PendingReviewDestination {
  Location? location;
  dynamic index;
  String? status;
  String? subtaskId;
  dynamic arrivedAt;
  dynamic completedAt;
  double? lat;
  double? lng;
  String? address;

  PendingReviewDestination({
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

  factory PendingReviewDestination.fromJson(String str) =>
      PendingReviewDestination.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PendingReviewDestination.fromMap(Map<String, dynamic> json) => PendingReviewDestination(
    location: json["location"] == null
        ? null
        : Location.fromMap(json["location"]),
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

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  factory Location.fromJson(String str) => Location.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Location.fromMap(Map<String, dynamic> json) => Location(
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

  factory DriverSnapshot.fromJson(String str) =>
      DriverSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory DriverSnapshot.fromMap(Map<String, dynamic> json) => DriverSnapshot(
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
  };
}

class Pickup {
  Location? location;
  double? lat;
  double? lng;
  String? address;

  Pickup({this.location, this.lat, this.lng, this.address});

  factory Pickup.fromJson(String str) => Pickup.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Pickup.fromMap(Map<String, dynamic> json) => Pickup(
    location: json["location"] == null
        ? null
        : Location.fromMap(json["location"]),
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

class VehicleSnapshot {
  String? vehicleType;
  String? vehicleName;
  String? displayName;

  VehicleSnapshot({this.vehicleType, this.vehicleName, this.displayName});

  factory VehicleSnapshot.fromJson(String str) =>
      VehicleSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory VehicleSnapshot.fromMap(Map<String, dynamic> json) => VehicleSnapshot(
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
