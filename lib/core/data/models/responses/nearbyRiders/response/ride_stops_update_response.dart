import 'package:selcom_rides_frontend/core/data/models/ride_model.dart';

class RideStopsUpdatedResponse {
  final String rideId;
  final List<RideStopModel> stops;
  final int fareEstimate;
  final int currentStopIndex;
  final double distanceKm;
  final int durationMinutes;

  RideStopsUpdatedResponse({
    required this.rideId,
    required this.stops,
    required this.fareEstimate,
    required this.currentStopIndex,
    required this.distanceKm,
    required this.durationMinutes,
  });

  factory RideStopsUpdatedResponse.fromJson(Map<String, dynamic> json) {
    final stopsJson = json['stops'] as List? ?? [];
    final stops = stopsJson.map((e) => RideStopModel.fromJson(e)).toList();

    return RideStopsUpdatedResponse(
      rideId: json['ride_id'] ?? '',
      stops: stops,
      fareEstimate: json['fare_estimate'] ?? 0,
      currentStopIndex: json['current_stop_index'] ?? 0,
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 0,
    );
  }
}

class RideStopsUpdateFailedResponse {
  final String rideId;
  final String reason;
  final String errorCode;
  final String? rollbackBlockStatus;

  RideStopsUpdateFailedResponse({
    required this.rideId,
    required this.reason,
    required this.errorCode,
    this.rollbackBlockStatus,
  });

  factory RideStopsUpdateFailedResponse.fromJson(Map<String, dynamic> json) {
    return RideStopsUpdateFailedResponse(
      rideId: json['ride_id'] ?? '',
      reason: json['reason'] ?? '',
      errorCode: json['error_code'] ?? '',
      rollbackBlockStatus: json['rollback_block_status'],
    );
  }
}
