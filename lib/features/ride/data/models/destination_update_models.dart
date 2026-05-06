class DestinationUpdatePreviewModel {
  final bool fareChanged;
  final int oldFareEstimate;
  final int newFareEstimate;
  final double newDistanceKm;
  final int newDurationMin;

  DestinationUpdatePreviewModel({
    required this.fareChanged,
    required this.oldFareEstimate,
    required this.newFareEstimate,
    required this.newDistanceKm,
    required this.newDurationMin,
  });

  int get deltaAmount => (newFareEstimate - oldFareEstimate).abs();

  factory DestinationUpdatePreviewModel.fromJson(Map<String, dynamic> json) {
    return DestinationUpdatePreviewModel(
      fareChanged: json['fare_changed'] == true,
      oldFareEstimate: (json['old_fare_estimate'] as num?)?.toInt() ?? 0,
      newFareEstimate: (json['new_fare_estimate'] as num?)?.toInt() ?? 0,
      newDistanceKm: (json['new_distance_km'] as num?)?.toDouble() ?? 0,
      newDurationMin: (json['new_duration_min'] as num?)?.toInt() ?? 0,
    );
  }
}

class DestinationUpdateAppliedModel {
  final int fareEstimate;
  final double distanceKm;
  final int durationMinutes;
  final bool blockUpdateRequired;
  final String? blockUpdateValidationId;
  final String? socketRoom;

  DestinationUpdateAppliedModel({
    required this.fareEstimate,
    required this.distanceKm,
    required this.durationMinutes,
    required this.blockUpdateRequired,
    this.blockUpdateValidationId,
    this.socketRoom,
  });

  factory DestinationUpdateAppliedModel.fromJson(Map<String, dynamic> json) {
    return DestinationUpdateAppliedModel(
      fareEstimate: (json['fare_estimate'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      blockUpdateRequired: json['block_update_required'] == true,
      blockUpdateValidationId: json['block_update_validation_id']?.toString(),
      socketRoom: json['socket_room']?.toString(),
    );
  }
}
