// To parse this JSON data, do
//
//     final trackingUpdateSocketResponse = trackingUpdateSocketResponseFromJson(jsonString);

import 'dart:convert';

TrackingUpdateSocketResponse? trackingUpdateSocketResponseFromJson(String str) => TrackingUpdateSocketResponse.fromJson(json.decode(str));

String trackingUpdateSocketResponseToJson(TrackingUpdateSocketResponse data) => json.encode(data.toJson());

class TrackingUpdateSocketResponse {
  String? status;
  int? eta;
  RouteGeometry? routeGeometry;
  String? routeTarget;

  TrackingUpdateSocketResponse({
    this.status,
    this.eta,
    this.routeGeometry,
    this.routeTarget,
  });

  factory TrackingUpdateSocketResponse.fromJson(Map<String, dynamic> json) => TrackingUpdateSocketResponse(
    status: json["status"],
    eta: json["eta"],
    routeGeometry: json["route_geometry"] == null ? null : RouteGeometry.fromJson(json["route_geometry"]),
    routeTarget: json["route_target"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "eta": eta,
    "route_geometry": routeGeometry?.toJson(),
    "route_target": routeTarget,
  };
}

class RouteGeometry {
  List<List<double>>? coordinates;
  String? type;

  RouteGeometry({
    this.coordinates,
    this.type,
  });

  factory RouteGeometry.fromJson(Map<String, dynamic> json) => RouteGeometry(
    coordinates: json["coordinates"] == null ? [] : List<List<double>>.from(json["coordinates"]!.map((x) => List<double>.from(x.map((x) => x?.toDouble())))),
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "coordinates": coordinates == null ? [] : List<dynamic>.from(coordinates!.map((x) => List<dynamic>.from(x.map((x) => x)))),
    "type": type,
  };
}
