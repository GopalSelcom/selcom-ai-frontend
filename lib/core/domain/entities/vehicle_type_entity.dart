class VehicleTypeEntity {
  final String id;
  final String name;
  final String key;
  final String displayName;
  final String? iconUrl;
  final int maxPassengers;
  final int baseFare;
  final int perKmRate;
  final int perMinRate;
  final int minimumFare;
  final int? cancellationFee;
  final bool isActive;
  final int sortOrder;

  const VehicleTypeEntity({
    required this.id,
    required this.name,
    required this.key,
    required this.displayName,
    this.iconUrl,
    required this.maxPassengers,
    required this.baseFare,
    required this.perKmRate,
    required this.perMinRate,
    required this.minimumFare,
    this.cancellationFee,
    required this.isActive,
    required this.sortOrder,
  });
}
