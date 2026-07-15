class VehicleTypeEntity {
  final String id;
  final String name;
  final String key;
  final String displayName;
  final int maxPassengers;
  final int baseFare;
  final int perKmRate;
  final int perMinRate;
  final int minimumFare;
  final int? cancellationFee;
  final int? cashbackPercent;
  final int bookingFee;
  final int waypointFee;
  final int maxDistanceKm;
  final bool bookAnyEligible;
  final bool isActive;
  final int sortOrder;
  final String? createdAt;
  final String? updatedAt;

  const VehicleTypeEntity({
    required this.id,
    required this.name,
    required this.key,
    required this.displayName,
    required this.maxPassengers,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinRate,
    required this.minimumFare,
    this.cancellationFee,
    this.cashbackPercent,
    this.bookingFee = 0,
    this.waypointFee = 0,
    this.maxDistanceKm = 0,
    this.bookAnyEligible = false,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });
}
