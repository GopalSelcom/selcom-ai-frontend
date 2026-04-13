// To parse this JSON data, do
//
//     final ridersResponseSocket = ridersResponseSocketFromJson(jsonString);

import 'dart:convert';

RidersResponseSocket ridersResponseSocketFromJson(String str) => RidersResponseSocket.fromJson(json.decode(str));

String ridersResponseSocketToJson(RidersResponseSocket data) => json.encode(data.toJson());

class RidersResponseSocket {
  List<Driver>? drivers;

  RidersResponseSocket({
    this.drivers,
  });

  RidersResponseSocket copyWith({
    List<Driver>? drivers,
  }) =>
      RidersResponseSocket(
        drivers: drivers ?? this.drivers,
      );

  factory RidersResponseSocket.fromJson(Map<String, dynamic> json) => RidersResponseSocket(
    drivers: json["drivers"] == null ? [] : List<Driver>.from(json["drivers"]!.map((x) => Driver.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "drivers": drivers == null ? [] : List<dynamic>.from(drivers!.map((x) => x.toJson())),
  };
}

class Driver {
  String? fleetId;
  String? lat;
  String? lng;
  String? vehicleType;
  double? distanceKm;

  Driver({
    this.fleetId,
    this.lat,
    this.lng,
    this.vehicleType,
    this.distanceKm,
  });

  Driver copyWith({
    String? fleetId,
    String? lat,
    String? lng,
    String? vehicleType,
    double? distanceKm,
  }) =>
      Driver(
        fleetId: fleetId ?? this.fleetId,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        vehicleType: vehicleType ?? this.vehicleType,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    fleetId: json["fleet_id"],
    lat: json["lat"],
    lng: json["lng"],
    vehicleType: json["vehicle_type"],
    distanceKm: double.parse((json["distance_km"]??0).toString()),
  );

  Map<String, dynamic> toJson() => {
    "fleet_id": fleetId,
    "lat": lat,
    "lng": lng,
    "vehicle_type": vehicleType,
    "distance_km": distanceKm,
  };
}
