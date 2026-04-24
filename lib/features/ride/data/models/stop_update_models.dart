import '../../../../core/data/models/ride_model.dart';

class StopUpdatePreviewModel {
  final bool fareChanged;
  final int oldFareEstimate;
  final int newFareEstimate;
  final int deltaAmount;
  final String direction;
  final double newDistanceKm;
  final int newDurationMin;
  final int waypointCharge;
  final Map<String, dynamic>? routeGeometry;
  final List<StopUpdateLegModel> legs;
  final StopUpdateDiffModel stopsDiff;

  StopUpdatePreviewModel({
    required this.fareChanged,
    required this.oldFareEstimate,
    required this.newFareEstimate,
    required this.deltaAmount,
    required this.direction,
    required this.newDistanceKm,
    required this.newDurationMin,
    required this.waypointCharge,
    this.routeGeometry,
    required this.legs,
    required this.stopsDiff,
  });

  factory StopUpdatePreviewModel.fromJson(Map<String, dynamic> json) {
    final legsJson = json['legs'] as List? ?? [];
    final legs = legsJson.map((e) => StopUpdateLegModel.fromJson(e)).toList();

    return StopUpdatePreviewModel(
      fareChanged: json['fare_changed'] ?? false,
      oldFareEstimate: json['old_fare_estimate'] ?? 0,
      newFareEstimate: json['new_fare_estimate'] ?? 0,
      deltaAmount: json['delta_amount'] ?? 0,
      direction: json['direction'] ?? '',
      newDistanceKm: (json['new_distance_km'] ?? 0.0).toDouble(),
      newDurationMin: json['new_duration_min'] ?? 0,
      waypointCharge: json['waypoint_charge'] ?? 0,
      routeGeometry: json['route_geometry'],
      legs: legs,
      stopsDiff: StopUpdateDiffModel.fromJson(json['stops_diff'] ?? {}),
    );
  }
}

class StopUpdateLegModel {
  final double distance;
  final int duration;

  StopUpdateLegModel({required this.distance, required this.duration});

  factory StopUpdateLegModel.fromJson(Map<String, dynamic> json) {
    return StopUpdateLegModel(
      distance: (json['distance'] ?? 0.0).toDouble(),
      duration: json['duration'] ?? 0,
    );
  }
}

class StopUpdateDiffModel {
  final List<StopDiffItemModel> added;
  final List<dynamic> removed;
  final bool reordered;

  StopUpdateDiffModel({
    required this.added,
    required this.removed,
    required this.reordered,
  });

  factory StopUpdateDiffModel.fromJson(Map<String, dynamic> json) {
    final addedJson = json['added'] as List? ?? [];
    final added = addedJson.map((e) => StopDiffItemModel.fromJson(e)).toList();

    return StopUpdateDiffModel(
      added: added,
      removed: json['removed'] as List? ?? [],
      reordered: json['reordered'] ?? false,
    );
  }
}

class StopDiffItemModel {
  final int targetIndex;
  final String address;

  StopDiffItemModel({required this.targetIndex, required this.address});

  factory StopDiffItemModel.fromJson(Map<String, dynamic> json) {
    return StopDiffItemModel(
      targetIndex: json['target_index'] ?? 0,
      address: json['address'] ?? '',
    );
  }
}

class StopUpdateAppliedModel {
  final String rideId;
  final int fareEstimate;
  final List<RideStopModel> stops;
  final bool blockUpdateRequired;
  final String? blockUpdateValidationId;
  final String? socketRoom;
  final int deltaAmount;
  final String direction;
  final DateTime? expiresAt;

  StopUpdateAppliedModel({
    required this.rideId,
    required this.fareEstimate,
    required this.stops,
    required this.blockUpdateRequired,
    this.blockUpdateValidationId,
    this.socketRoom,
    required this.deltaAmount,
    required this.direction,
    this.expiresAt,
  });

  factory StopUpdateAppliedModel.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List? ?? [];
    final stops = stopsJson.map((e) => RideStopModel.fromJson(e)).toList();

    return StopUpdateAppliedModel(
      rideId: json['ride_id'] ?? '',
      fareEstimate: json['fare_estimate'] ?? 0,
      stops: stops,
      blockUpdateRequired: json['block_update_required'] ?? false,
      blockUpdateValidationId: json['block_update_validation_id'],
      socketRoom: json['socket_room'],
      deltaAmount: json['delta_amount'] ?? 0,
      direction: json['direction'] ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
    );
  }
}
