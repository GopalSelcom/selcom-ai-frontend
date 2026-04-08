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
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });
}
