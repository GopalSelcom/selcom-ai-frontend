import '../../domain/entities/ride_rating_ride_entity.dart';

/// Data model for last completed ride rating prompt.
class RideRatingRideModel extends RideRatingRideEntity {
  const RideRatingRideModel({
    required super.rideId,
    required super.driverName,
    required super.driverImage,
    required super.vehicleType,
    required super.dateTime,
  });

  factory RideRatingRideModel.fromJson(Map<String, dynamic> json) {
    return RideRatingRideModel(
      rideId: (json['rideId'] as String?)?.trim() ?? '',
      driverName: (json['driverName'] as String?)?.trim() ?? '',
      driverImage: (json['driverImage'] as String?)?.trim() ?? '',
      vehicleType: (json['vehicleType'] as String?)?.trim() ?? '',
      dateTime: (json['dateTime'] as String?)?.trim() ?? '',
    );
  }

  /// Temporary static payload until backend endpoint is available.
  factory RideRatingRideModel.mock() {
    return const RideRatingRideModel(
      rideId: '123',
      driverName: 'John Doe',
      driverImage: 'https://randomuser.me/api/portraits/men/1.jpg',
      vehicleType: 'Boda',
      dateTime: '05th Mar 2026 . 08:08PM',
    );
  }
}
