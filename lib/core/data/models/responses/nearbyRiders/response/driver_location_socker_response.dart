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
  double? speed;
  double? accuracy;
  String? recordedAt;

  DriverLocationSocketResponse({
    this.latitude,
    this.longitude,
    this.heading,
    this.speed,
    this.accuracy,
    this.recordedAt,
  });

  factory DriverLocationSocketResponse.fromJson(Map<String, dynamic> json) => DriverLocationSocketResponse(
    latitude: (json["latitude"] ?? json["lat"])?.toDouble(),
    longitude: (json["longitude"] ?? json["lng"])?.toDouble(),
    heading: json["heading"],
    speed: (json["speed"])?.toDouble(),
    accuracy: (json["accuracy"])?.toDouble(),
    recordedAt: json["recorded_at"],
  );

  Map<String, dynamic> toJson() => {
    "latitude": latitude,
    "longitude": longitude,
    "heading": heading,
    "speed": speed,
    "accuracy": accuracy,
    "recorded_at": recordedAt,
  };
}
