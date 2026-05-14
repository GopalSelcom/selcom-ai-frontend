class FareEstimateResponseModel {
  final int? statusCode;
  final String? message;
  final String? errorCode;
  final FareEstimateData? data;

  FareEstimateResponseModel({
    this.statusCode,
    this.message,
    this.errorCode,
    this.data,
  });

  factory FareEstimateResponseModel.fromJson(Map<String, dynamic> json) {
    final scRaw = json['status_code'];
    final int? statusCode = switch (scRaw) {
      null => null,
      final int i => i,
      final num n => n.toInt(),
      final String s => int.tryParse(s.trim()),
      _ => int.tryParse(scRaw.toString()),
    };

    FareEstimateData? data;
    final dataRaw = json['data'];
    if (dataRaw != null && dataRaw is Map) {
      try {
        data = FareEstimateData.fromJson(
          dataRaw is Map<String, dynamic>
              ? dataRaw
              : Map<String, dynamic>.from(dataRaw),
        );
      } catch (_) {
        data = null;
      }
    }

    return FareEstimateResponseModel(
      statusCode: statusCode,
      message: json['message']?.toString(),
      errorCode: json['error_code']?.toString(),
      data: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status_code': statusCode,
      'message': message,
      'error_code': errorCode,
      'data': data?.toJson(),
    };
  }

  bool get isSuccess => statusCode == 200;
}

class FareEstimateData {
  final List<FareEstimateItem>? estimates;
  final RouteGeometry? routeGeometry;
  final List<FareLeg>? legs;
  final bool? isMultiStop;

  FareEstimateData({
    this.estimates,
    this.routeGeometry,
    this.legs,
    this.isMultiStop,
  });

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
      legs: json['legs'] != null
          ? (json['legs'] as List).map((e) => FareLeg.fromJson(e)).toList()
          : null,
      isMultiStop: json['is_multi_stop'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimates': estimates?.map((e) => e.toJson()).toList(),
      'route_geometry': routeGeometry?.toJson(),
      'legs': legs?.map((e) => e.toJson()).toList(),
      'is_multi_stop': isMultiStop,
    };
  }
}

class FareLeg {
  final double? distance;
  final int? duration;

  FareLeg({this.distance, this.duration});

  factory FareLeg.fromJson(Map<String, dynamic> json) {
    return FareLeg(
      distance: (json['distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'distance': distance, 'duration': duration};
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
  final int? waypointCharge;
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
    this.waypointCharge,
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
      waypointCharge: (json['waypoint_charge'] as num?)?.toInt(),
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
      'waypoint_charge': waypointCharge,
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
