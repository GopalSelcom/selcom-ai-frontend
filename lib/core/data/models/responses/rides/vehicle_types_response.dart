import 'dart:convert';

class VehicleTypesResponse {
  int? statusCode;
  String? message;
  VehicleTypeData? data;

  VehicleTypesResponse({this.statusCode, this.message, this.data});

  factory VehicleTypesResponse.fromJson(String str) =>
      VehicleTypesResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory VehicleTypesResponse.fromMap(Map<String, dynamic> json) =>
      VehicleTypesResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : VehicleTypeData.fromMap(
                Map<String, dynamic>.from(json["data"] as Map),
              ),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

class VehicleTypeData {
  List<VehicleType>? vehicleTypes;

  VehicleTypeData({this.vehicleTypes});

  factory VehicleTypeData.fromJson(String str) =>
      VehicleTypeData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory VehicleTypeData.fromMap(Map<String, dynamic> json) => VehicleTypeData(
    vehicleTypes: json["vehicle_types"] == null
        ? []
        : List<VehicleType>.from(
            json["vehicle_types"]!.map(
              (x) => VehicleType.fromMap(Map<String, dynamic>.from(x as Map)),
            ),
          ),
  );

  Map<String, dynamic> toMap() => {
    "vehicle_types": vehicleTypes == null
        ? []
        : List<dynamic>.from(vehicleTypes!.map((x) => x.toMap())),
  };
}

class VehicleType {
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

  VehicleType({
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
  });

  factory VehicleType.fromJson(String str) =>
      VehicleType.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory VehicleType.fromMap(Map<String, dynamic> json) => VehicleType(
    cancellationFee: json["cancellation_fee"],
    bookingFee: json["booking_fee"],
    waypointFee: json["waypoint_fee"],
    cashbackPercent: json["cashback_percent"],
    maxDistanceKm: json["max_distance_km"],
    bookAnyEligible: json["book_any_eligible"],
    isActive: json["is_active"],
    sortOrder: json["sort_order"],
    id: json["_id"],
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
  );

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
  };
}

extension VehicleTypesResponseX on VehicleTypesResponse {
  bool get isSuccess => statusCode == 200;

  List<VehicleType> get vehicleTypes => data?.vehicleTypes ?? const [];
}
