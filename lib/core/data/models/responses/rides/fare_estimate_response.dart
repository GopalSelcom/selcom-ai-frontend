/// Envelope for `POST go/rides/estimate`.
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
  final FareEstimateLocation? pickup;
  final List<FareEstimateLocation> stops;
  final FareEstimateLocation? destination;
  final bool? isMultiStop;
  final BookAnyEstimate? bookAny;

  FareEstimateData({
    this.estimates,
    this.routeGeometry,
    this.legs,
    this.pickup,
    this.stops = const [],
    this.destination,
    this.isMultiStop,
    this.bookAny,
  });

  factory FareEstimateData.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    return FareEstimateData(
      estimates: json['estimates'] != null
          ? (json['estimates'] as List)
                .map(
                  (e) => FareEstimateItem.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : null,
      routeGeometry: json['route_geometry'] != null
          ? RouteGeometry.fromJson(
              json['route_geometry'] is Map<String, dynamic>
                  ? json['route_geometry'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(json['route_geometry'] as Map),
            )
          : null,
      legs: json['legs'] != null
          ? (json['legs'] as List)
                .map(
                  (e) => FareLeg.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : null,
      pickup: json['pickup'] != null
          ? FareEstimateLocation.fromJson(
              json['pickup'] is Map<String, dynamic>
                  ? json['pickup'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(json['pickup'] as Map),
            )
          : null,
      stops: rawStops is List
          ? rawStops
                .whereType<Map>()
                .map(
                  (e) => FareEstimateLocation.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
      destination: json['destination'] != null
          ? FareEstimateLocation.fromJson(
              json['destination'] is Map<String, dynamic>
                  ? json['destination'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(json['destination'] as Map),
            )
          : null,
      isMultiStop: json['is_multi_stop'] as bool?,
      bookAny: json['book_any'] != null
          ? BookAnyEstimate.fromJson(
              json['book_any'] is Map<String, dynamic>
                  ? json['book_any'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(json['book_any'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimates': estimates?.map((e) => e.toJson()).toList(),
      'route_geometry': routeGeometry?.toJson(),
      'legs': legs?.map((e) => e.toJson()).toList(),
      'pickup': pickup?.toJson(),
      'stops': stops.map((e) => e.toJson()).toList(),
      'destination': destination?.toJson(),
      'is_multi_stop': isMultiStop,
      'book_any': bookAny?.toJson(),
    };
  }
}

/// `pickup` / `destination` / `stops[]` on `POST go/rides/estimate` `data`.
class FareEstimateLocation {
  final double? lat;
  final double? lng;
  final String? address;

  const FareEstimateLocation({this.lat, this.lng, this.address});

  factory FareEstimateLocation.fromJson(Map<String, dynamic> json) {
    return FareEstimateLocation(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'address': address,
  };
}

class BookAnyEstimate {
  final bool eligible;
  final int minFare;
  final int maxFare;
  final int blockAmount;
  final List<String> vehicleTypeIds;
  final String? currency;

  BookAnyEstimate({
    required this.eligible,
    required this.minFare,
    required this.maxFare,
    required this.blockAmount,
    this.vehicleTypeIds = const [],
    this.currency,
  });

  factory BookAnyEstimate.fromJson(Map<String, dynamic> json) {
    final range = json['fare_range'];
    int minFare = 0;
    int maxFare = 0;
    if (range is Map) {
      minFare = (range['min'] as num?)?.toInt() ?? 0;
      maxFare = (range['max'] as num?)?.toInt() ?? 0;
    }
    return BookAnyEstimate(
      eligible: json['eligible'] == true,
      minFare: minFare,
      maxFare: maxFare,
      blockAmount: (json['block_amount'] as num?)?.toInt() ?? maxFare,
      vehicleTypeIds: json['vehicle_type_ids'] != null
          ? (json['vehicle_type_ids'] as List)
                .map((e) => e.toString())
                .toList()
          : const [],
      currency: json['currency']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eligible': eligible,
      'fare_range': {'min': minFare, 'max': maxFare},
      'block_amount': blockAmount,
      'vehicle_type_ids': vehicleTypeIds,
      'currency': currency,
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
  /// Present when a promo code is applied to the estimate request.
  final bool? promoApplied;
  final int? promoDiscount;
  final int? discountedFare;
  final String? promoError;
  /// Client-only Book Any row — not returned on API estimate items.
  final bool isBookAnyOption;
  final int? bookAnyMinFare;
  final int? bookAnyMaxFare;

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
    this.promoApplied,
    this.promoDiscount,
    this.discountedFare,
    this.promoError,
    this.isBookAnyOption = false,
    this.bookAnyMinFare,
    this.bookAnyMaxFare,
  });

  /// Amount the rider pays when a promo applies; otherwise base estimate.
  int get displayFare {
    if (promoApplied == true &&
        discountedFare != null &&
        discountedFare! >= 0) {
      return discountedFare!;
    }
    return fareEstimate ?? 0;
  }

  int get originalFare => fareEstimate ?? 0;

  factory FareEstimateItem.fromJson(Map<String, dynamic> json) {
    bool? promoApplied;
    final raw = json['promo_applied'];
    if (raw is bool) {
      promoApplied = raw;
    } else if (raw != null) {
      promoApplied = raw == 1 || raw == '1' || raw == true;
    }

    return FareEstimateItem(
      vehicleTypeId: json['vehicle_type_id']?.toString(),
      vehicleName: json['vehicle_name']?.toString(),
      displayName: json['display_name']?.toString(),
      fareEstimate: (json['fare_estimate'] as num?)?.toInt(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      baseFare: (json['base_fare'] as num?)?.toInt(),
      perKmCharge: (json['per_km_charge'] as num?)?.toInt(),
      perMinCharge: (json['per_min_charge'] as num?)?.toInt(),
      minimumFare: (json['minimum_fare'] as num?)?.toInt(),
      waypointCharge: (json['waypoint_charge'] as num?)?.toInt(),
      maxPassengers: (json['max_passengers'] as num?)?.toInt(),
      currency: json['currency']?.toString(),
      promoApplied: promoApplied,
      promoDiscount: (json['promo_discount'] as num?)?.toInt(),
      discountedFare: (json['discounted_fare'] as num?)?.toInt(),
      promoError: json['promo_error']?.toString(),
      isBookAnyOption: json['is_book_any_option'] == true,
      bookAnyMinFare: (json['book_any_min_fare'] as num?)?.toInt(),
      bookAnyMaxFare: (json['book_any_max_fare'] as num?)?.toInt(),
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
      'promo_applied': promoApplied,
      'promo_discount': promoDiscount,
      'discounted_fare': discountedFare,
      'promo_error': promoError,
      'is_book_any_option': isBookAnyOption,
      'book_any_min_fare': bookAnyMinFare,
      'book_any_max_fare': bookAnyMaxFare,
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
          ?.map(
            (e) => (e as List).map((c) => (c as num).toDouble()).toList(),
          )
          .toList(),
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'coordinates': coordinates, 'type': type};
  }
}
