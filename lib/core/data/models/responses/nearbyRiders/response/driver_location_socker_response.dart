// To parse this JSON data, do
//
//     final driverLocationSocketResponse = driverLocationSocketResponseFromJson(jsonString);

import 'dart:convert';

DriverLocationSocketResponse driverLocationSocketResponseFromJson(String str) => DriverLocationSocketResponse.fromJson(json.decode(str));

String driverLocationSocketResponseToJson(DriverLocationSocketResponse data) => json.encode(data.toJson());

class DriverLocationSocketResponse {
  double? latitude;
  double? longitude;
  dynamic heading;

  DriverLocationSocketResponse({
    this.latitude,
    this.longitude,
    this.heading,
  });

  factory DriverLocationSocketResponse.fromJson(Map<String, dynamic> json) => DriverLocationSocketResponse(
    latitude: json["latitude"]?.toDouble(),
    longitude: json["longitude"]?.toDouble(),
    heading: json["heading"],
  );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
    "heading": heading,
  };
}
