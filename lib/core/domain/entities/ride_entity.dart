enum RideStatus {
  searching,
  driverAssigned,
  driverArriving,
  driverArrived,
  rideStarted,
  rideInProgress,
  nearDestination,
  rideCompleted,
  cancelled,
  noDriverFound,
}

enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
}

enum PaymentMethod {
  wallet,
  selcomPesa,
  mobileMoney,
  card,
}

class LocationEntity {
  final double lat;
  final double lng;
  final String address;

  const LocationEntity({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class DriverSnapshotEntity {
  final String name;
  final String phone;
  final String? avatarUrl;
  final double rating;

  const DriverSnapshotEntity({
    required this.name,
    required this.phone,
    this.avatarUrl,
    required this.rating,
  });
}

class VehicleSnapshotEntity {
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String plateNumber;

  const VehicleSnapshotEntity({
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.plateNumber,
  });
}

class RideEntity {
  final String id;
  final String riderId;
  final String? driverId;
  final String vehicleTypeId;
  final RideStatus status;
  final LocationEntity pickup;
  final LocationEntity destination;
  final List<dynamic> stops;
  final int fareEstimate;
  final int? finalFare;
  final double distanceKm;
  final int durationMinutes;
  final String pinCode;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DriverSnapshotEntity? driverSnapshot;
  final VehicleSnapshotEntity? vehicleSnapshot;
  final DateTime createdAt;

  const RideEntity({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.vehicleTypeId,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.stops,
    required this.fareEstimate,
    this.finalFare,
    required this.distanceKm,
    required this.durationMinutes,
    required this.pinCode,
    required this.paymentMethod,
    required this.paymentStatus,
    this.driverSnapshot,
    this.vehicleSnapshot,
    required this.createdAt,
  });
}
