import 'dart:convert';

import '../../../../core/data/models/fare_stop_charge.dart';

/// Envelope for `PUT .../stops` with `confirm: false`.
class UpdateStopsPreviewResponse {
  int? statusCode;
  String? message;
  StopUpdatePreviewModel? data;

  UpdateStopsPreviewResponse({this.statusCode, this.message, this.data});

  factory UpdateStopsPreviewResponse.fromJson(String str) =>
      UpdateStopsPreviewResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UpdateStopsPreviewResponse.fromMap(Map<String, dynamic> json) =>
      UpdateStopsPreviewResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : StopUpdatePreviewModel.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

/// `data` for confirm=false preview.
class StopUpdatePreviewModel {
  bool? fareChanged;
  int? oldFareEstimate;
  int? newFareEstimate;
  int? deltaAmount;
  String? direction;
  double? newDistanceKm;
  int? newDurationMin;
  int? waypointCharge;
  StopUpdateRouteGeometry? routeGeometry;
  List<StopUpdateLegModel>? legs;
  StopUpdateDiffModel? stopsDiff;

  StopUpdatePreviewModel({
    this.fareChanged,
    this.oldFareEstimate,
    this.newFareEstimate,
    this.deltaAmount,
    this.direction,
    this.newDistanceKm,
    this.newDurationMin,
    this.waypointCharge,
    this.routeGeometry,
    this.legs,
    this.stopsDiff,
  });

  factory StopUpdatePreviewModel.fromJson(String str) =>
      StopUpdatePreviewModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdatePreviewModel.fromMap(Map<String, dynamic> json) =>
      StopUpdatePreviewModel(
        fareChanged: json["fare_changed"],
        oldFareEstimate: json["old_fare_estimate"],
        newFareEstimate: json["new_fare_estimate"],
        deltaAmount: json["delta_amount"],
        direction: json["direction"],
        newDistanceKm: json["new_distance_km"]?.toDouble(),
        newDurationMin: json["new_duration_min"],
        waypointCharge: json["waypoint_charge"],
        routeGeometry: json["route_geometry"] == null
            ? null
            : StopUpdateRouteGeometry.fromMap(json["route_geometry"]),
        legs: json["legs"] == null
            ? []
            : List<StopUpdateLegModel>.from(
                json["legs"]!.map((x) => StopUpdateLegModel.fromMap(x)),
              ),
        stopsDiff: json["stops_diff"] == null
            ? null
            : StopUpdateDiffModel.fromMap(json["stops_diff"]),
      );

  Map<String, dynamic> toMap() => {
    "fare_changed": fareChanged,
    "old_fare_estimate": oldFareEstimate,
    "new_fare_estimate": newFareEstimate,
    "delta_amount": deltaAmount,
    "direction": direction,
    "new_distance_km": newDistanceKm,
    "new_duration_min": newDurationMin,
    "waypoint_charge": waypointCharge,
    "route_geometry": routeGeometry?.toMap(),
    "legs": legs == null
        ? []
        : List<dynamic>.from(legs!.map((x) => x.toMap())),
    "stops_diff": stopsDiff?.toMap(),
  };
}

class StopUpdateRouteGeometry {
  String? type;
  List<List<double>>? coordinates;

  StopUpdateRouteGeometry({this.type, this.coordinates});

  factory StopUpdateRouteGeometry.fromJson(String str) =>
      StopUpdateRouteGeometry.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdateRouteGeometry.fromMap(Map<String, dynamic> json) =>
      StopUpdateRouteGeometry(
        type: json["type"],
        coordinates: json["coordinates"] == null
            ? []
            : List<List<double>>.from(
                json["coordinates"]!.map(
                  (x) => List<double>.from(x.map((e) => e?.toDouble())),
                ),
              ),
      );

  Map<String, dynamic> toMap() => {
    "type": type,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(
            coordinates!.map((x) => List<dynamic>.from(x.map((e) => e))),
          ),
  };
}

class StopUpdateLegModel {
  double? distance;
  int? duration;

  StopUpdateLegModel({this.distance, this.duration});

  factory StopUpdateLegModel.fromJson(String str) =>
      StopUpdateLegModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdateLegModel.fromMap(Map<String, dynamic> json) =>
      StopUpdateLegModel(
        distance: json["distance"]?.toDouble(),
        duration: json["duration"],
      );

  Map<String, dynamic> toMap() => {
    "distance": distance,
    "duration": duration,
  };
}

class StopUpdateDiffModel {
  List<StopDiffItemModel>? added;
  List<dynamic>? removed;
  bool? reordered;

  StopUpdateDiffModel({this.added, this.removed, this.reordered});

  factory StopUpdateDiffModel.fromJson(String str) =>
      StopUpdateDiffModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdateDiffModel.fromMap(Map<String, dynamic> json) =>
      StopUpdateDiffModel(
        added: json["added"] == null
            ? []
            : List<StopDiffItemModel>.from(
                json["added"]!.map((x) => StopDiffItemModel.fromMap(x)),
              ),
        removed: json["removed"] == null
            ? []
            : List<dynamic>.from(json["removed"]!.map((x) => x)),
        reordered: json["reordered"],
      );

  Map<String, dynamic> toMap() => {
    "added": added == null
        ? []
        : List<dynamic>.from(added!.map((x) => x.toMap())),
    "removed": removed == null
        ? []
        : List<dynamic>.from(removed!.map((x) => x)),
    "reordered": reordered,
  };
}

class StopDiffItemModel {
  int? targetIndex;
  String? address;

  StopDiffItemModel({this.targetIndex, this.address});

  factory StopDiffItemModel.fromJson(String str) =>
      StopDiffItemModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopDiffItemModel.fromMap(Map<String, dynamic> json) =>
      StopDiffItemModel(
        targetIndex: json["target_index"],
        address: json["address"],
      );

  Map<String, dynamic> toMap() => {
    "target_index": targetIndex,
    "address": address,
  };
}

/// Envelope for `PUT .../stops` with `confirm: true`.
class UpdateStopsConfirmResponse {
  int? statusCode;
  String? message;
  StopUpdateAppliedModel? data;

  UpdateStopsConfirmResponse({this.statusCode, this.message, this.data});

  factory UpdateStopsConfirmResponse.fromJson(String str) =>
      UpdateStopsConfirmResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UpdateStopsConfirmResponse.fromMap(Map<String, dynamic> json) =>
      UpdateStopsConfirmResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : StopUpdateAppliedModel.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

/// `data` for confirm=true apply (keys from API sample).
class StopUpdateAppliedModel {
  String? rideId;
  int? fareEstimate;
  StopUpdateFareBreakdown? fareBreakdown;
  List<StopUpdateStopModel>? stops;
  bool? blockUpdateRequired;
  int? deltaAmount;
  String? direction;

  StopUpdateAppliedModel({
    this.rideId,
    this.fareEstimate,
    this.fareBreakdown,
    this.stops,
    this.blockUpdateRequired,
    this.deltaAmount,
    this.direction,
  });

  factory StopUpdateAppliedModel.fromJson(String str) =>
      StopUpdateAppliedModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdateAppliedModel.fromMap(Map<String, dynamic> json) =>
      StopUpdateAppliedModel(
        rideId: json["ride_id"],
        fareEstimate: json["fare_estimate"],
        fareBreakdown: json["fare_breakdown"] == null
            ? null
            : StopUpdateFareBreakdown.fromMap(json["fare_breakdown"]),
        stops: json["stops"] == null
            ? []
            : List<StopUpdateStopModel>.from(
                json["stops"]!.map((x) => StopUpdateStopModel.fromMap(x)),
              ),
        blockUpdateRequired: json["block_update_required"],
        deltaAmount: json["delta_amount"],
        direction: json["direction"],
      );

  Map<String, dynamic> toMap() => {
    "ride_id": rideId,
    "fare_estimate": fareEstimate,
    "fare_breakdown": fareBreakdown?.toMap(),
    "stops": stops == null
        ? []
        : List<dynamic>.from(stops!.map((x) => x.toMap())),
    "block_update_required": blockUpdateRequired,
    "delta_amount": deltaAmount,
    "direction": direction,
  };
}

class StopUpdateFareBreakdown {
  int? rideCharge;
  int? bookingFee;
  int? totalAmount;
  int? waypointCharge;
  /// Mid-ride only: fee for the most recently added stop. 0/absent otherwise.
  /// Prefer [stopCharges] for the full itemized UI; do not replace with this.
  int? stopAddedCharge;
  /// Per-stop fees for every stop on the ride (initial booking + later adds).
  /// Prefer over [waypointCharge] (legacy aggregate, kept for backward compat).
  List<FareStopCharge>? stopCharges;
  /// Extra amount when the minimum-fare floor applies. Render only when > 0.
  int? minimumFareAdjustment;

  StopUpdateFareBreakdown({
    this.rideCharge,
    this.bookingFee,
    this.totalAmount,
    this.waypointCharge,
    this.stopAddedCharge,
    this.stopCharges,
    this.minimumFareAdjustment,
  });

  factory StopUpdateFareBreakdown.fromJson(String str) =>
      StopUpdateFareBreakdown.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdateFareBreakdown.fromMap(Map<String, dynamic> json) =>
      StopUpdateFareBreakdown(
        rideCharge: json["ride_charge"],
        bookingFee: json["booking_fee"],
        totalAmount: json["total_amount"],
        waypointCharge: json["waypoint_charge"],
        stopAddedCharge: json["stop_added_charge"] ?? 0,
        stopCharges: FareStopCharge.listFromJson(json["stop_charges"]),
        minimumFareAdjustment: json["minimum_fare_adjustment"] ?? 0,
      );

  Map<String, dynamic> toMap() => {
    "ride_charge": rideCharge,
    "booking_fee": bookingFee,
    "total_amount": totalAmount,
    "waypoint_charge": waypointCharge,
    "stop_added_charge": stopAddedCharge,
    "stop_charges": stopCharges?.map((e) => e.toMap()).toList() ?? [],
    "minimum_fare_adjustment": minimumFareAdjustment,
  };
}

class StopUpdateStopModel {
  int? index;
  double? lat;
  double? lng;
  String? address;
  StopUpdateLocation? location;
  String? status;
  dynamic subtaskId;
  dynamic arrivedAt;
  dynamic completedAt;

  StopUpdateStopModel({
    this.index,
    this.lat,
    this.lng,
    this.address,
    this.location,
    this.status,
    this.subtaskId,
    this.arrivedAt,
    this.completedAt,
  });

  factory StopUpdateStopModel.fromJson(String str) =>
      StopUpdateStopModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdateStopModel.fromMap(Map<String, dynamic> json) =>
      StopUpdateStopModel(
        index: json["index"],
        lat: json["lat"]?.toDouble(),
        lng: json["lng"]?.toDouble(),
        address: json["address"],
        location: json["location"] == null
            ? null
            : StopUpdateLocation.fromMap(json["location"]),
        status: json["status"],
        subtaskId: json["subtask_id"],
        arrivedAt: json["arrived_at"],
        completedAt: json["completed_at"],
      );

  Map<String, dynamic> toMap() => {
    "index": index,
    "lat": lat,
    "lng": lng,
    "address": address,
    "location": location?.toMap(),
    "status": status,
    "subtask_id": subtaskId,
    "arrived_at": arrivedAt,
    "completed_at": completedAt,
  };
}

class StopUpdateLocation {
  String? type;
  List<double>? coordinates;

  StopUpdateLocation({this.type, this.coordinates});

  factory StopUpdateLocation.fromJson(String str) =>
      StopUpdateLocation.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory StopUpdateLocation.fromMap(Map<String, dynamic> json) =>
      StopUpdateLocation(
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
