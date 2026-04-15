/// Entity representing the last completed ride to be rated.
class RideRatingRideEntity {
  final String rideId;
  final String driverName;
  final String driverImage;
  final String vehicleType;
  final String dateTime;

  const RideRatingRideEntity({
    required this.rideId,
    required this.driverName,
    required this.driverImage,
    required this.vehicleType,
    required this.dateTime,
  });
}
