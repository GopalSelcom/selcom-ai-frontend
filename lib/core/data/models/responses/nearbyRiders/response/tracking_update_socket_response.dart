// To parse this JSON data, do
//
//     final trackingUpdateSocketResponse = trackingUpdateSocketResponseFromJson(jsonString);

import 'dart:convert';

TrackingUpdateSocketResponse? trackingUpdateSocketResponseFromJson(
  String str,
) => TrackingUpdateSocketResponse.fromJson(json.decode(str));

String trackingUpdateSocketResponseToJson(TrackingUpdateSocketResponse data) =>
    json.encode(data.toJson());

class TrackingUpdateSocketResponse {
  String? rideId;
  String? status;
  int? eta;
  RouteGeometry? routeGeometry;
  String? routeTarget;

  /// Chained assignment: driver is still finishing another nearby trip.
  /// Defaults to `false` when the socket omits the field or sends null
  /// (`json["driver_finishing_nearby"] == true` is the only truthy path).
  bool driverFinishingNearby;

  TrackingUpdateSocketResponse({
    this.rideId,
    this.status,
    this.eta,
    this.routeGeometry,
    this.routeTarget,
    this.driverFinishingNearby = false,
  });

  factory TrackingUpdateSocketResponse.fromJson(Map<String, dynamic> json) =>
      TrackingUpdateSocketResponse(
        rideId: json["ride_id"]?.toString() ?? json["rideId"]?.toString(),
        status: json["status"],
        eta: json["eta"],
        routeGeometry: (json["route_geometry"] ?? json["routeGeometry"]) == null
            ? null
            : RouteGeometry.fromJson(
                json["route_geometry"] ?? json["routeGeometry"],
              ),
        routeTarget: json["route_target"] ?? json["routeTarget"],
        driverFinishingNearby: json["driver_finishing_nearby"] == true,
      );

  Map<String, dynamic> toJson() => {
    "ride_id": rideId,
    "status": status,
    "eta": eta,
    "route_geometry": routeGeometry?.toJson(),
    "route_target": routeTarget,
    "driver_finishing_nearby": driverFinishingNearby,
  };
}

class RouteGeometry {
  List<List<double>>? coordinates;
  String? type;

  RouteGeometry({this.coordinates, this.type});

  factory RouteGeometry.fromJson(Map<String, dynamic> json) => RouteGeometry(
    coordinates: json["coordinates"] == null
        ? []
        : List<List<double>>.from(
            json["coordinates"]!.map(
              (x) => List<double>.from(x.map((x) => x?.toDouble())),
            ),
          ),
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(
            coordinates!.map((x) => List<dynamic>.from(x.map((x) => x))),
          ),
    "type": type,
  };
}
