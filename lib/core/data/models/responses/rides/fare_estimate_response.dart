class FareEstimateResponseModel {
  final int? statusCode;
  final String? message;
  final FareEstimateData? data;

  FareEstimateResponseModel({this.statusCode, this.message, this.data});

  factory FareEstimateResponseModel.fromJson(Map<String, dynamic> json) {
    return FareEstimateResponseModel(
      statusCode: json['status_code'],
      message: json['message'],
      data: json['data'] != null
          ? FareEstimateData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'message': message,
      'data': data?.toJson(),
    };
  }

  bool get isSuccess => statusCode == 200;
}

class FareEstimateData {
  final List<FareEstimateItem>? estimates;
  final RouteGeometry? routeGeometry;

  FareEstimateData({this.estimates, this.routeGeometry});

  factory FareEstimateData.fromJson(Map<String, dynamic> json) {
    return FareEstimateData(
      estimates: json['estimates'] != null
          ? (json['estimates'] as List)
                .map((e) => FareEstimateItem.fromJson(e))
                .toList()
          : null,
      routeGeometry: json['route_geometry'] != null
          ? RouteGeometry.fromJson(json['route_geometry'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimates': estimates?.map((e) => e.toJson()).toList(),
      'route_geometry': routeGeometry?.toJson(),
    };
  }
}

class FareEstimateItem {
  final String? vehicleTypeId;
  final String? vehicleName;
  final String? displayName;
  final int? fareEstimate;
  final double? distanceKm;
  final int? durationMinutes;
  final int? baseFare;
  final int? perKmCharge;
  final int? perMinCharge;
  final int? minimumFare;
  final int? maxPassengers;
  final String? currency;

  FareEstimateItem({
    this.vehicleTypeId,
    this.vehicleName,
    this.displayName,
    this.fareEstimate,
    this.distanceKm,
    this.durationMinutes,
    this.baseFare,
    this.perKmCharge,
    this.perMinCharge,
    this.minimumFare,
    this.maxPassengers,
    this.currency,
  });

  factory FareEstimateItem.fromJson(Map<String, dynamic> json) {
    return FareEstimateItem(
      vehicleTypeId: json['vehicle_type_id'],
      vehicleName: json['vehicle_name'],
      displayName: json['display_name'],
      fareEstimate: (json['fare_estimate'] as num?)?.toInt(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      baseFare: (json['base_fare'] as num?)?.toInt(),
      perKmCharge: (json['per_km_charge'] as num?)?.toInt(),
      perMinCharge: (json['per_min_charge'] as num?)?.toInt(),
      minimumFare: (json['minimum_fare'] as num?)?.toInt(),
      maxPassengers: (json['max_passengers'] as num?)?.toInt(),
      currency: json['currency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type_id': vehicleTypeId,
      'vehicle_name': vehicleName,
      'display_name': displayName,
      'fare_estimate': fareEstimate,
      'distance_km': distanceKm,
      'duration_minutes': durationMinutes,
      'base_fare': baseFare,
      'per_km_charge': perKmCharge,
      'per_min_charge': perMinCharge,
      'minimum_fare': minimumFare,
      'max_passengers': maxPassengers,
      'currency': currency,
    };
  }
}

class RouteGeometry {
  final List<List<double>>? coordinates;
  final String? type;

  RouteGeometry({this.coordinates, this.type});

  factory RouteGeometry.fromJson(Map<String, dynamic> json) {
    return RouteGeometry(
      coordinates: (json['coordinates'] as List?)
          ?.map((e) => (e as List).map((c) => (c as num).toDouble()).toList())
          .toList(),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'coordinates': coordinates, 'type': type};
  }
}
