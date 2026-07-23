import 'dart:convert';

/// Envelope for `PUT .../update-destination` with `confirm: false`.
class UpdateDestinationPreviewResponse {
  int? statusCode;
  String? message;
  DestinationUpdatePreviewModel? data;

  UpdateDestinationPreviewResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory UpdateDestinationPreviewResponse.fromJson(String str) =>
      UpdateDestinationPreviewResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UpdateDestinationPreviewResponse.fromMap(Map<String, dynamic> json) =>
      UpdateDestinationPreviewResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : DestinationUpdatePreviewModel.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

/// `data` for confirm=false preview.
class DestinationUpdatePreviewModel {
  bool? fareChanged;
  int? oldFareEstimate;
  int? newFareEstimate;
  double? newDistanceKm;
  int? newDurationMin;

  DestinationUpdatePreviewModel({
    this.fareChanged,
    this.oldFareEstimate,
    this.newFareEstimate,
    this.newDistanceKm,
    this.newDurationMin,
  });

  int get deltaAmount =>
      ((newFareEstimate ?? 0) - (oldFareEstimate ?? 0)).abs();

  factory DestinationUpdatePreviewModel.fromJson(String str) =>
      DestinationUpdatePreviewModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory DestinationUpdatePreviewModel.fromMap(Map<String, dynamic> json) =>
      DestinationUpdatePreviewModel(
        fareChanged: json["fare_changed"],
        oldFareEstimate: json["old_fare_estimate"],
        newFareEstimate: json["new_fare_estimate"],
        newDistanceKm: json["new_distance_km"]?.toDouble(),
        newDurationMin: json["new_duration_min"],
      );

  Map<String, dynamic> toMap() => {
    "fare_changed": fareChanged,
    "old_fare_estimate": oldFareEstimate,
    "new_fare_estimate": newFareEstimate,
    "new_distance_km": newDistanceKm,
    "new_duration_min": newDurationMin,
  };
}

/// Envelope for `PUT .../update-destination` with `confirm: true`.
class UpdateDestinationConfirmResponse {
  int? statusCode;
  String? message;
  DestinationUpdateAppliedModel? data;

  UpdateDestinationConfirmResponse({
    this.statusCode,
    this.message,
    this.data,
  });

  factory UpdateDestinationConfirmResponse.fromJson(String str) =>
      UpdateDestinationConfirmResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UpdateDestinationConfirmResponse.fromMap(Map<String, dynamic> json) =>
      UpdateDestinationConfirmResponse(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : DestinationUpdateAppliedModel.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toMap(),
  };
}

/// `data` for confirm=true apply.
class DestinationUpdateAppliedModel {
  int? fareEstimate;
  double? distanceKm;
  int? durationMinutes;

  DestinationUpdateAppliedModel({
    this.fareEstimate,
    this.distanceKm,
    this.durationMinutes,
  });

  factory DestinationUpdateAppliedModel.fromJson(String str) =>
      DestinationUpdateAppliedModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory DestinationUpdateAppliedModel.fromMap(Map<String, dynamic> json) =>
      DestinationUpdateAppliedModel(
        fareEstimate: json["fare_estimate"],
        distanceKm: json["distance_km"]?.toDouble(),
        durationMinutes: json["duration_minutes"],
      );

  Map<String, dynamic> toMap() => {
    "fare_estimate": fareEstimate,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
  };
}
