import '../../domain/entities/location_entity.dart';
import '../../domain/entities/ride_entity.dart';

class RideModel extends RideEntity {
  const RideModel({
    required super.id,
    required super.riderId,
    super.driverId,
    required super.vehicleTypeId,
    required super.status,
    required super.pickup,
    required super.destination,
    required super.stops,
    required super.fareEstimate,
    super.finalFare,
    required super.distanceKm,
    required super.durationMinutes,
    required super.pinCode,
    required super.paymentMethod,
    required super.paymentStatus,
    super.driverSnapshot,
    super.vehicleSnapshot,
    required super.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['_id'] ?? '',
      riderId: json['rider_id'] ?? '',
      driverId: json['driver_id'],
      vehicleTypeId: json['vehicle_type_id'] ?? '',
      status: RideStatus.values.firstWhere(
        (e) => e.name == _toCamelCase(json['status'] ?? 'searching'),
        orElse: () => RideStatus.searching,
      ),
      pickup: LocationModel.fromJson(json['pickup'] ?? {}),
      destination: LocationModel.fromJson(json['destination'] ?? {}),
      stops: json['stops'] ?? [],
      fareEstimate: json['fare_estimate'] ?? 0,
      finalFare: json['final_fare'],
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      durationMinutes: json['duration_minutes'] ?? 0,
      pinCode: json['pin_code'] ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == _toCamelCase(json['payment_method'] ?? 'wallet'),
        orElse: () => PaymentMethod.wallet,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (json['payment_status'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      driverSnapshot: json['driver_snapshot'] != null
          ? DriverSnapshotModel.fromJson(json['driver_snapshot'])
          : null,
      vehicleSnapshot: json['vehicle_snapshot'] != null
          ? VehicleSnapshotModel.fromJson(json['vehicle_snapshot'])
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  static String _toCamelCase(String snakeCase) {
    List<String> words = snakeCase.split('_');
    if (words.length == 1) return words[0];
    return words[0] + words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join('');
  }
}

class LocationModel extends LocationEntity {
  const LocationModel({required super.lat, required super.lng, required super.address});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
    );
  }
}

class DriverSnapshotModel extends DriverSnapshotEntity {
  const DriverSnapshotModel({required super.name, required super.phone, super.avatarUrl, required super.rating});

  factory DriverSnapshotModel.fromJson(Map<String, dynamic> json) {
    return DriverSnapshotModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}

class VehicleSnapshotModel extends VehicleSnapshotEntity {
  const VehicleSnapshotModel({
    required super.vehicleType,
    required super.vehicleMake,
    required super.vehicleModel,
    required super.vehicleColor,
    required super.plateNumber,
  });

  factory VehicleSnapshotModel.fromJson(Map<String, dynamic> json) {
    return VehicleSnapshotModel(
      vehicleType: json['vehicle_type'] ?? '',
      vehicleMake: json['vehicle_make'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleColor: json['vehicle_color'] ?? '',
      plateNumber: json['plate_number'] ?? '',
    );
  }
}
