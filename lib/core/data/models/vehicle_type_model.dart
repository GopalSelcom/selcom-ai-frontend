import '../../domain/entities/vehicle_type_entity.dart';

class VehicleTypeModel extends VehicleTypeEntity {
  const VehicleTypeModel({
    required super.id,
    required super.name,
    required super.key,
    required super.displayName,
    required super.maxPassengers,
    required super.baseFare,
    required super.perKmRate,
    required super.perMinRate,
    required super.minimumFare,
    super.cancellationFee,
    super.cashbackPercent,
    super.bookingFee = 0,
    super.waypointFee = 0,
    super.maxDistanceKm = 0,
    super.bookAnyEligible = false,
    required super.isActive,
    required super.sortOrder,
    super.createdAt,
    super.updatedAt,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      key: json['key'] ?? '',
      displayName: json['display_name'] ?? '',
      maxPassengers: json['max_passengers'] ?? 0,
      baseFare: json['base_fare'] ?? 0,
      perKmRate: json['per_km_rate'] ?? 0,
      perMinRate: json['per_min_rate'] ?? 0,
      minimumFare: json['minimum_fare'] ?? 0,
      cancellationFee: (json['cancellation_fee'] as num?)?.toInt(),
      cashbackPercent: (json['cashback_percent'] as num?)?.toInt(),
      bookingFee: (json['booking_fee'] as num?)?.toInt() ?? 0,
      waypointFee: (json['waypoint_fee'] as num?)?.toInt() ?? 0,
      maxDistanceKm: (json['max_distance_km'] as num?)?.toInt() ?? 0,
      bookAnyEligible: json['book_any_eligible'] == true,
      isActive: json['is_active'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'key': key,
      'display_name': displayName,
      'max_passengers': maxPassengers,
      'base_fare': baseFare,
      'per_km_rate': perKmRate,
      'per_min_rate': perMinRate,
      'minimum_fare': minimumFare,
      'cancellation_fee': cancellationFee,
      'cashback_percent': cashbackPercent,
      'booking_fee': bookingFee,
      'waypoint_fee': waypointFee,
      'max_distance_km': maxDistanceKm,
      'book_any_eligible': bookAnyEligible,
      'is_active': isActive,
      'sort_order': sortOrder,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
