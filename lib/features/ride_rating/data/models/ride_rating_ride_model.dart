import '../../domain/entities/ride_rating_ride_entity.dart';

class RideRatingRideModel extends RideRatingRideEntity {
  const RideRatingRideModel({
    required super.rideId,
    required super.transactionId,
    required super.driverName,
    required super.driverImage,
    required super.vehicleType,
    required super.vehicleDisplayName,
    required super.pickupAddress,
    required super.destinationAddress,
    required super.pickupLat,
    required super.pickupLng,
    required super.destinationLat,
    required super.destinationLng,
    required super.finalFare,
    required super.rideCompletedAt,
  });

  factory RideRatingRideModel.fromPendingReviewJson(Map<String, dynamic> json) {
    final driverSnapshot =
        (json['driver_snapshot'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final vehicleSnapshot =
        (json['vehicle_snapshot'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final pickup =
        (json['pickup'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final destination =
        (json['destination'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return RideRatingRideModel(
      rideId: (json['ride_id'] as String?)?.trim() ?? '',
      transactionId: (json['transid'] as String?)?.trim() ?? '',
      driverName: (driverSnapshot['name'] as String?)?.trim() ?? '',
      driverImage: (driverSnapshot['avatar_url'] as String?)?.trim() ?? '',
      vehicleType:
          (vehicleSnapshot['vehicle_name'] as String?)?.trim() ??
          (driverSnapshot['vehicle_type'] as String?)?.trim() ??
          '',
      vehicleDisplayName:
          (vehicleSnapshot['display_name'] as String?)?.trim() ??
          (vehicleSnapshot['vehicle_name'] as String?)?.trim() ??
          '',
      pickupAddress: (pickup['address'] as String?)?.trim() ?? '',
      destinationAddress: (destination['address'] as String?)?.trim() ?? '',
      pickupLat: (pickup['lat'] as num?)?.toDouble(),
      pickupLng: (pickup['lng'] as num?)?.toDouble(),
      destinationLat: (destination['lat'] as num?)?.toDouble(),
      destinationLng: (destination['lng'] as num?)?.toDouble(),
      finalFare: (json['final_fare'] as num?) ?? 0,
      rideCompletedAt: DateTime.tryParse(
        (json['ride_completed_at'] as String?)?.trim() ?? '',
      ),
    );
  }
}
