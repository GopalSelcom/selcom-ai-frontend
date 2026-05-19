// To parse this JSON data, do
//
//     final eventRiderStatusUpdateResponse = eventRiderStatusUpdateResponseFromJson(jsonString);

import 'dart:convert';

EventRiderStatusUpdateResponse? eventRiderStatusUpdateResponseFromJson(
  String str,
) => EventRiderStatusUpdateResponse.fromJson(json.decode(str));

String eventRiderStatusUpdateResponseToJson(
  EventRiderStatusUpdateResponse data,
) => json.encode(data.toJson());

class EventRiderStatusUpdateResponse {
  String? rideId;
  String? status;
  DriverSnapshot? driverSnapshot;
  VehicleSnapshot? vehicleSnapshot;
  dynamic finalFare;
  int? cancellationFee;
  EventRouteGeometry? routeGeometry;
  String? routeTarget;
  String? pinCode;
  bool? pinRequired;
  int? currentStopIndex;
  String? rideStopStatus;
  /// Root-level average from socket (e.g. `ride:status_update`).
  num? driverAvgRating;
  num? riderAvgRating;
  num? etaSeconds;

  EventRiderStatusUpdateResponse({
    this.rideId,
    this.status,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.finalFare,
    this.cancellationFee,
    this.routeGeometry,
    this.routeTarget,
    this.pinCode,
    this.pinRequired,
    this.currentStopIndex,
    this.rideStopStatus,
    this.driverAvgRating,
    this.riderAvgRating,
    this.etaSeconds,
  });

  factory EventRiderStatusUpdateResponse.fromJson(Map<String, dynamic> json) =>
      EventRiderStatusUpdateResponse(
        rideId: json["ride_id"] ?? json["rideId"],
        status: json["status"],
        driverSnapshot: json["driver_snapshot"] == null
            ? null
            : DriverSnapshot.fromJson(json["driver_snapshot"]),
        vehicleSnapshot: json["vehicle_snapshot"] == null
            ? null
            : VehicleSnapshot.fromJson(json["vehicle_snapshot"]),
        finalFare: json["final_fare"],
        cancellationFee: json["cancellation_fee"],
        routeGeometry: (json["route_geometry"] ?? json["routeGeometry"]) == null
            ? null
            : EventRouteGeometry.fromJson(
                json["route_geometry"] ?? json["routeGeometry"],
              ),
        routeTarget: json["route_target"] ?? json["routeTarget"],
        pinCode: json["pin_code"],
        pinRequired: json["pin_required"],
        currentStopIndex: json["current_stop_index"],
        rideStopStatus: json["ride_stop_status"] ?? json["status"],
        driverAvgRating: json["driver_avg_rating"] as num?,
        riderAvgRating: json["rider_avg_rating"] as num?,
        etaSeconds: json["eta_seconds"] as num?,
      );

  Map<String, dynamic> toJson() => {
    "ride_id": rideId,
    "status": status,
    "driver_snapshot": driverSnapshot?.toJson(),
    "vehicle_snapshot": vehicleSnapshot?.toJson(),
    "final_fare": finalFare,
    "cancellation_fee": cancellationFee,
    "route_geometry": routeGeometry?.toJson(),
    "route_target": routeTarget,
    "pin_code": pinCode,
    "pin_required": pinRequired,
    "current_stop_index": currentStopIndex,
    "ride_stop_status": rideStopStatus,
    "driver_avg_rating": driverAvgRating,
    "rider_avg_rating": riderAvgRating,
    "eta_seconds": etaSeconds,
  };
}

class EventRouteGeometry {
  List<List<double>>? coordinates;
  String? type;

  EventRouteGeometry({this.coordinates, this.type});

  factory EventRouteGeometry.fromJson(Map<String, dynamic> json) =>
      EventRouteGeometry(
        coordinates: json["coordinates"] == null
            ? []
            : List<List<double>>.from(
                json["coordinates"].map(
                  (x) => List<double>.from(x.map((v) => (v as num).toDouble())),
                ),
              ),
        type: json["type"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(
            coordinates!.map((x) => List<dynamic>.from(x.map((v) => v))),
          ),
    "type": type,
  };
}

class DriverSnapshot {
  String? driverId;
  int? fleetId;
  String? name;
  String? phone;
  String? avatarUrl;
  double? lat;
  double? lng;
  String? vehicleColor;
  String? vehicleModel;
  String? vehicleRegistrationNumber;
  String? vehicleType;
  String? vehicleYear;
  String? verificationCode;
  double? rating;

  DriverSnapshot({
    this.driverId,
    this.fleetId,
    this.name,
    this.phone,
    this.avatarUrl,
    this.lat,
    this.lng,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleRegistrationNumber,
    this.vehicleType,
    this.vehicleYear,
    this.verificationCode,
    this.rating,
  });

  factory DriverSnapshot.fromJson(Map<String, dynamic> json) => DriverSnapshot(
    driverId: json["driver_id"],
    fleetId: json["fleet_id"],
    name: json["name"],
    phone: json["phone"],
    avatarUrl: json["avatar_url"],
    lat: json["lat"],
    lng: json["lng"],
    vehicleColor: json["vehicle_color"],
    vehicleModel: json["vehicle_model"],
    vehicleRegistrationNumber: json["vehicle_registration_number"],
    vehicleType: json['vehicle_type'],
    vehicleYear: json["vehicle_year"],
    verificationCode: json["verification_code"],
    rating: (json["rating"] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "driver_id": driverId,
    "fleet_id": fleetId,
    "name": name,
    "phone": phone,
    "avatar_url": avatarUrl,
    "lat": lat,
    "lng": lng,
    "vehicle_color": vehicleColor,
    "vehicle_model": vehicleModel,
    "vehicle_registration_number": vehicleRegistrationNumber,
    "vehicle_type": vehicleType,
    "vehicle_year": vehicleYear,
    "verification_code": verificationCode,
    "rating": rating,
  };
}

class VehicleSnapshot {
  String? vehicleType;
  String? vehicleName;
  String? displayName;

  VehicleSnapshot({this.vehicleType, this.vehicleName, this.displayName});

  factory VehicleSnapshot.fromJson(Map<String, dynamic> json) =>
      VehicleSnapshot(
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
