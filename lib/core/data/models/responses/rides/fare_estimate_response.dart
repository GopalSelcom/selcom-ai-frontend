import 'dart:convert';

/// Models for `POST go/rides/estimate` (from `model/model.dart` + missing fields only).
class FareEstimateResponse {
  int? statusCode;
  String? message;
  String? errorCode;
  FareEstimateData? data;

  FareEstimateResponse({
    this.statusCode,
    this.message,
    this.errorCode,
    this.data,
  });

  factory FareEstimateResponse.fromJson(String str) =>
      FareEstimateResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FareEstimateResponse.fromMap(Map<String, dynamic> json) =>
      FareEstimateResponse(
        statusCode: json["status_code"],
        message: json["message"],
        errorCode: json["error_code"],
        data: json["data"] == null
            ? null
            : FareEstimateData.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "message": message,
    "error_code": errorCode,
    "data": data?.toMap(),
  };
}

class FareEstimateData {
  List<FareEstimateItem>? estimates;
  EstimateRouteGeometry? routeGeometry;
  List<FareLeg>? legs;
  EstimatePlace? pickup;
  List<dynamic>? stops;
  EstimatePlace? destination;
  bool? isMultiStop;
  BookAny? bookAny;
  String? promoCode;

  FareEstimateData({
    this.estimates,
    this.routeGeometry,
    this.legs,
    this.pickup,
    this.stops,
    this.destination,
    this.isMultiStop,
    this.bookAny,
    this.promoCode,
  });

  factory FareEstimateData.fromJson(String str) =>
      FareEstimateData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FareEstimateData.fromMap(Map<String, dynamic> json) =>
      FareEstimateData(
        estimates: json["estimates"] == null
            ? []
            : List<FareEstimateItem>.from(
                json["estimates"]!.map((x) => FareEstimateItem.fromMap(x)),
              ),
        routeGeometry: json["route_geometry"] == null
            ? null
            : EstimateRouteGeometry.fromMap(json["route_geometry"]),
        legs: json["legs"],
        pickup: json["pickup"] == null
            ? null
            : EstimatePlace.fromMap(json["pickup"]),
        stops: json["stops"] == null
            ? []
            : List<dynamic>.from(json["stops"]!.map((x) => x)),
        destination: json["destination"] == null
            ? null
            : EstimatePlace.fromMap(json["destination"]),
        isMultiStop: json["is_multi_stop"],
        bookAny: json["book_any"] == null
            ? null
            : BookAny.fromMap(json["book_any"]),
        promoCode: json["promo_code"],
      );

  Map<String, dynamic> toMap() => {
    "estimates": estimates == null
        ? []
        : List<dynamic>.from(estimates!.map((x) => x.toMap())),
    "route_geometry": routeGeometry?.toMap(),
    "legs": legs,
    "pickup": pickup?.toMap(),
    "stops": stops == null ? [] : List<dynamic>.from(stops!.map((x) => x)),
    "destination": destination?.toMap(),
    "is_multi_stop": isMultiStop,
    "book_any": bookAny?.toMap(),
    "promo_code": promoCode,
  };
}

class BookAny {
  bool? eligible;
  FareRange? fareRange;
  int? blockAmount;
  List<String>? vehicleTypeIds;
  String? currency;

  BookAny({
    this.eligible,
    this.fareRange,
    this.blockAmount,
    this.vehicleTypeIds,
    this.currency,
  });

  factory BookAny.fromJson(String str) => BookAny.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BookAny.fromMap(Map<String, dynamic> json) => BookAny(
    eligible: json["eligible"],
    fareRange: json["fare_range"] == null
        ? null
        : FareRange.fromMap(json["fare_range"]),
    blockAmount: json["block_amount"],
    vehicleTypeIds: json["vehicle_type_ids"] == null
        ? []
        : List<String>.from(json["vehicle_type_ids"]!.map((x) => x)),
    currency: json["currency"],
  );

  Map<String, dynamic> toMap() => {
    "eligible": eligible,
    "fare_range": fareRange?.toMap(),
    "block_amount": blockAmount,
    "vehicle_type_ids": vehicleTypeIds == null
        ? []
        : List<dynamic>.from(vehicleTypeIds!.map((x) => x)),
    "currency": currency,
  };
}

class FareRange {
  int? min;
  int? max;

  FareRange({this.min, this.max});

  factory FareRange.fromJson(String str) => FareRange.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FareRange.fromMap(Map<String, dynamic> json) =>
      FareRange(min: json["min"], max: json["max"]);

  Map<String, dynamic> toMap() => {"min": min, "max": max};
}

class EstimatePlace {
  double? lat;
  double? lng;
  String? address;

  EstimatePlace({this.lat, this.lng, this.address});

  factory EstimatePlace.fromJson(String str) =>
      EstimatePlace.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory EstimatePlace.fromMap(Map<String, dynamic> json) => EstimatePlace(
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toMap() => {"lat": lat, "lng": lng, "address": address};
}

class FareEstimateItem {
  String? vehicleTypeId;
  String? vehicleName;
  String? displayName;
  int? fareEstimate;
  double? distanceKm;
  int? durationMinutes;
  int? baseFare;
  int? perKmCharge;
  int? perMinCharge;
  int? waypointCharge;
  int? minimumFare;
  int? maxPassengers;
  String? currency;
  bool? promoApplied;
  int? promoDiscount;
  int? discountedFare;
  String? promoError;
  bool isBookAnyOption;
  int? bookAnyMinFare;
  int? bookAnyMaxFare;

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
    this.waypointCharge,
    this.minimumFare,
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

  factory FareEstimateItem.fromJson(String str) =>
      FareEstimateItem.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FareEstimateItem.fromMap(Map<String, dynamic> json) =>
      FareEstimateItem(
        vehicleTypeId: json["vehicle_type_id"],
        vehicleName: json["vehicle_name"],
        displayName: json["display_name"],
        fareEstimate: json["fare_estimate"],
        distanceKm: json["distance_km"]?.toDouble(),
        durationMinutes: json["duration_minutes"],
        baseFare: json["base_fare"],
        perKmCharge: json["per_km_charge"],
        perMinCharge: json["per_min_charge"],
        waypointCharge: json["waypoint_charge"],
        minimumFare: json["minimum_fare"],
        maxPassengers: json["max_passengers"],
        currency: json["currency"],
        promoApplied: json["promo_applied"],
        promoDiscount: json["promo_discount"],
        discountedFare: json["discounted_fare"],
        promoError: json["promo_error"],
        isBookAnyOption: json["is_book_any_option"] ?? false,
        bookAnyMinFare: json["book_any_min_fare"],
        bookAnyMaxFare: json["book_any_max_fare"],
      );

  Map<String, dynamic> toMap() => {
    "vehicle_type_id": vehicleTypeId,
    "vehicle_name": vehicleName,
    "display_name": displayName,
    "fare_estimate": fareEstimate,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
    "base_fare": baseFare,
    "per_km_charge": perKmCharge,
    "per_min_charge": perMinCharge,
    "waypoint_charge": waypointCharge,
    "minimum_fare": minimumFare,
    "max_passengers": maxPassengers,
    "currency": currency,
    "promo_applied": promoApplied,
    "promo_discount": promoDiscount,
    "discounted_fare": discountedFare,
    "promo_error": promoError,
    "is_book_any_option": isBookAnyOption,
    "book_any_min_fare": bookAnyMinFare,
    "book_any_max_fare": bookAnyMaxFare,
  };
}

class FareLeg {
  final double? distance;
  final int? duration;

  const FareLeg({this.distance, this.duration});

  factory FareLeg.fromRawJson(String str) => FareLeg.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FareLeg.fromJson(Map<String, dynamic> json) => FareLeg(
    distance: (json['distance'] as num?)?.toDouble(),
    duration: json['duration'],
  );

  Map<String, dynamic> toJson() => {'distance': distance, 'duration': duration};
}

class EstimateRouteGeometry {
  List<List<double>>? coordinates;
  String? type;

  EstimateRouteGeometry({this.coordinates, this.type});

  factory EstimateRouteGeometry.fromJson(String str) =>
      EstimateRouteGeometry.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory EstimateRouteGeometry.fromMap(Map<String, dynamic> json) =>
      EstimateRouteGeometry(
        coordinates: json["coordinates"] == null
            ? []
            : List<List<double>>.from(
                json["coordinates"]!.map(
                  (x) => List<double>.from(x.map((x) => x?.toDouble())),
                ),
              ),
        type: json["type"],
      );

  Map<String, dynamic> toMap() => {
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(
            coordinates!.map((x) => List<dynamic>.from(x.map((x) => x))),
          ),
    "type": type,
  };
}
