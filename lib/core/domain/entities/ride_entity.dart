import 'location_entity.dart';

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

enum PaymentStatus { pending, blocked, completed, failed, refunded }

enum PaymentMethod { wallet, selcomPesa, mobileMoney, card }

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

class FareBreakdownEntity {
  final int rideCharge;
  final int bookingFee;
  final int totalAmount;

  const FareBreakdownEntity({
    required this.rideCharge,
    required this.bookingFee,
    required this.totalAmount,
  });
}

class RideStopEntity {
  final int index;
  final double lat;
  final double lng;
  final String address;
  final String status;
  final DateTime? arrivedAt;
  final DateTime? completedAt;

  const RideStopEntity({
    required this.index,
    required this.lat,
    required this.lng,
    required this.address,
    required this.status,
    this.arrivedAt,
    this.completedAt,
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
  final List<RideStopEntity> stops;
  final bool isMultiStop;
  final int currentStopIndex;
  final int fareEstimate;
  final int? finalFare;
  final double distanceKm;
  final int durationMinutes;
  final String pinCode;
  final bool pinRequired;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final int? cancellationFee;
  final int? riderRating;
  final bool showReviewUi;
  final FareBreakdownEntity? fareBreakdown;
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
    this.isMultiStop = false,
    this.currentStopIndex = 0,
    required this.fareEstimate,
    this.finalFare,
    required this.distanceKm,
    required this.durationMinutes,
    required this.pinCode,
    this.pinRequired = true,
    required this.paymentMethod,
    required this.paymentStatus,
    this.cancellationFee,
    this.riderRating,
    this.showReviewUi = true,
    this.fareBreakdown,
    this.driverSnapshot,
    this.vehicleSnapshot,
    required this.createdAt,
  });
}
