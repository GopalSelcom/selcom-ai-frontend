import 'dart:convert';

/// Envelope for `GET go/vehicles/types`.
class VehicleTypesResponseModel {
  final int? statusCode;
  final String? message;
  final List<VehicleTypeModel> vehicleTypes;

  const VehicleTypesResponseModel({
    this.statusCode,
    this.message,
    this.vehicleTypes = const [],
  });

  factory VehicleTypesResponseModel.fromRawJson(String str) =>
      VehicleTypesResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleTypesResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final rows = data is Map<String, dynamic> ? data['vehicle_types'] : null;

    return VehicleTypesResponseModel(
      statusCode: json['status_code'],
      message: json['message'],
      vehicleTypes: rows == null
          ? const []
          : List<VehicleTypeModel>.from(
              rows.map((x) => VehicleTypeModel.fromJson(x)),
            ),
    );
  }

  bool get isSuccess => statusCode == 200;

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
    'data': {
      'vehicle_types': List<dynamic>.from(vehicleTypes.map((x) => x.toJson())),
    },
  };
}

class VehicleTypeModel {
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

  const VehicleTypeModel({
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

  factory VehicleTypeModel.fromRawJson(String str) =>
      VehicleTypeModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) =>
      VehicleTypeModel(
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

  Map<String, dynamic> toJson() => {
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
