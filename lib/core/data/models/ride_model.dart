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
    required super.pinRequired,
    required super.paymentMethod,
    required super.paymentStatus,
    super.cancellationFee,
    super.riderRating,
    super.showReviewUi,
    super.fareBreakdown,
    super.driverSnapshot,
    super.vehicleSnapshot,
    required super.createdAt,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    // Backend may return createdAt or created_at
    final createdAtStr =
        json['createdAt'] ??
        json['created_at'] ??
        DateTime.now().toIso8601String();

    final driverSnapshotJson = json['driver_snapshot'];
    final driverSnapshot = driverSnapshotJson != null
        ? DriverSnapshotModel.fromJson(driverSnapshotJson)
        : null;

    // Use top-level pin_code or fallback to verification_code from driver_snapshot
    final pin =
        (json['pin_code']?.toString() ?? driverSnapshot?.verificationCode ?? '')
            .trim();
    final pinRequiredRaw = json['pin_required'];
    final bool pinRequired =
        pinRequiredRaw == null
        ? true
        : (pinRequiredRaw == true ||
              pinRequiredRaw == 1 ||
              pinRequiredRaw.toString().toLowerCase() == 'true');
    final fareBreakdownJson = json['fare_breakdown'];
    final fareBreakdown = fareBreakdownJson is Map<String, dynamic>
        ? FareBreakdownModel.fromJson(fareBreakdownJson)
        : fareBreakdownJson is Map
            ? FareBreakdownModel.fromJson(
                Map<String, dynamic>.from(fareBreakdownJson),
              )
            : null;

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
      pinCode: pin,
      pinRequired: pinRequired,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == _toCamelCase(json['payment_method'] ?? 'wallet'),
        orElse: () => PaymentMethod.wallet,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (json['payment_status'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      cancellationFee: json['cancellation_fee'],
      riderRating: (json['rider_rating'] as num?)?.toInt(),
      showReviewUi: json['show_review_ui'] is bool
          ? json['show_review_ui'] as bool
          : true,
      fareBreakdown: fareBreakdown,
      driverSnapshot: driverSnapshot,
      vehicleSnapshot: json['vehicle_snapshot'] != null
          ? VehicleSnapshotModel.fromJson(json['vehicle_snapshot'])
          : null,
      createdAt: DateTime.parse(createdAtStr),
    );
  }

  static String _toCamelCase(String snakeCase) {
    List<String> words = snakeCase.split('_');
    if (words.length == 1) return words[0];
    return words[0] +
        words.skip(1).map((w) => w[0].toUpperCase() + w.substring(1)).join('');
  }
}

class LocationModel extends LocationEntity {
  const LocationModel({
    required super.lat,
    required super.lng,
    required super.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
    );
  }
}

class DriverSnapshotModel extends DriverSnapshotEntity {
  final String? verificationCode;
  final String? vehicleRegistrationNumber;
  final String? vehicleModel;
  final String? vehicleType;
  final String? vehicleColor;

  const DriverSnapshotModel({
    required super.name,
    required super.phone,
    super.avatarUrl,
    required super.rating,
    this.verificationCode,
    this.vehicleRegistrationNumber,
    this.vehicleModel,
    this.vehicleType,
    this.vehicleColor,
  });

  factory DriverSnapshotModel.fromJson(Map<String, dynamic> json) {
    return DriverSnapshotModel(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      verificationCode: json['verification_code']?.toString(),
      vehicleRegistrationNumber: json['vehicle_registration_number']
          ?.toString(),
      vehicleModel: json['vehicle_model']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      vehicleColor: json['vehicle_color']?.toString(),
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
      vehicleType:
          json['display_name'] ??
          json['vehicle_name'] ??
          json['vehicle_type'] ??
          '',
      vehicleMake: json['vehicle_make'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleColor: json['vehicle_color'] ?? '',
      plateNumber: json['plate_number'] ?? '',
    );
  }
}

class FareBreakdownModel extends FareBreakdownEntity {
  const FareBreakdownModel({
    required super.rideCharge,
    required super.bookingFee,
    required super.totalAmount,
  });

  factory FareBreakdownModel.fromJson(Map<String, dynamic> json) {
    return FareBreakdownModel(
      rideCharge: ((json['ride_charge'] ?? 0) as num).toInt(),
      bookingFee: ((json['booking_fee'] ?? 0) as num).toInt(),
      totalAmount: ((json['total_amount'] ?? 0) as num).toInt(),
    );
  }
}
