/// Entity representing a ride pending rider review.
class RideRatingRideEntity {
  final String rideId;
  final String transactionId;
  final String driverName;
  final String driverImage;
  final String vehicleType;
  final String vehicleDisplayName;
  final String pickupAddress;
  final String destinationAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final num finalFare;
  final int? riderRating;
  final DateTime? rideCompletedAt;

  const RideRatingRideEntity({
    required this.rideId,
    required this.transactionId,
    required this.driverName,
    required this.driverImage,
    required this.vehicleType,
    required this.vehicleDisplayName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.finalFare,
    required this.riderRating,
    required this.rideCompletedAt,
  });
}
