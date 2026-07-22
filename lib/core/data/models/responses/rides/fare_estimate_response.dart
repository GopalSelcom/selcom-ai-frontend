import 'dart:convert';

import '../../location_model.dart';

class FareEstimateResponseModel {
  final int? statusCode;
  final String? message;
  final String? errorCode;
  final FareEstimateData? data;

  const FareEstimateResponseModel({
    this.statusCode,
    this.message,
    this.errorCode,
    this.data,
  });

  factory FareEstimateResponseModel.fromRawJson(String str) =>
      FareEstimateResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FareEstimateResponseModel.fromJson(Map<String, dynamic> json) =>
      FareEstimateResponseModel(
        statusCode: json['status_code'],
        message: json['message'],
        errorCode: json['error_code'],
        data: json['data'] == null
            ? null
            : FareEstimateData.fromJson(json['data']),
      );

  bool get isSuccess => statusCode == 200 && data != null;

  List<FareEstimateItem> get estimates => data?.estimates ?? const [];

  RouteGeometry? get routeGeometry => data?.routeGeometry;

  List<FareLeg>? get legs => data?.legs;

  LocationModel get pickup => data?.pickup ?? LocationModel.fromJson({});

  List<LocationModel> get stops => data?.stops ?? const [];

  LocationModel get destination =>
      data?.destination ?? LocationModel.fromJson({});

  bool? get isMultiStop => data?.isMultiStop;

  BookAnyEstimate? get bookAny => data?.bookAny;

  Map<String, dynamic> toJson() => {
    'status_code': statusCode,
    'message': message,
    'error_code': errorCode,
    'data': data?.toJson(),
  };
}

class FareEstimateData {
  final List<FareEstimateItem>? estimates;
  final RouteGeometry? routeGeometry;
  final List<FareLeg>? legs;
  final LocationModel pickup;
  final List<LocationModel> stops;
  final LocationModel destination;
  final bool? isMultiStop;
  final BookAnyEstimate? bookAny;

  const FareEstimateData({
    this.estimates,
    this.routeGeometry,
    this.legs,
    required this.pickup,
    required this.stops,
    required this.destination,
    this.isMultiStop,
    this.bookAny,
  });

  factory FareEstimateData.fromRawJson(String str) =>
      FareEstimateData.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FareEstimateData.fromJson(Map<String, dynamic> json) =>
      FareEstimateData(
        estimates: json['estimates'] == null
            ? []
            : List<FareEstimateItem>.from(
                json['estimates'].map((x) => FareEstimateItem.fromJson(x)),
              ),
        routeGeometry: json['route_geometry'] == null
            ? null
            : RouteGeometry.fromJson(json['route_geometry']),
        legs: json['legs'] == null
            ? []
            : List<FareLeg>.from(json['legs'].map((x) => FareLeg.fromJson(x))),
        pickup: LocationModel.fromJson(json['pickup'] ?? {}),
        stops: json['stops'] == null
            ? []
            : List<LocationModel>.from(
                json['stops'].map((x) => LocationModel.fromJson(x)),
              ),
        destination: LocationModel.fromJson(json['destination'] ?? {}),
        isMultiStop: json['is_multi_stop'],
        bookAny: json['book_any'] == null
            ? null
            : BookAnyEstimate.fromJson(json['book_any']),
      );

  Map<String, dynamic> toJson() => {
    'estimates': estimates == null
        ? []
        : List<dynamic>.from(estimates!.map((x) => x.toJson())),
    'route_geometry': routeGeometry?.toJson(),
    'legs': legs == null
        ? []
        : List<dynamic>.from(legs!.map((x) => x.toJson())),
    'pickup': pickup.toJson(),
    'stops': List<dynamic>.from(stops.map((x) => x.toJson())),
    'destination': destination.toJson(),
    'is_multi_stop': isMultiStop,
    'book_any': bookAny?.toJson(),
  };
}

class BookAnyEstimate {
  final bool eligible;
  final FareRange? fareRange;
  final int? blockAmount;
  final List<String>? vehicleTypeIds;
  final String? currency;

  const BookAnyEstimate({
    this.eligible = false,
    this.fareRange,
    this.blockAmount,
    this.vehicleTypeIds,
    this.currency,
  });

  factory BookAnyEstimate.fromRawJson(String str) =>
      BookAnyEstimate.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookAnyEstimate.fromJson(Map<String, dynamic> json) =>
      BookAnyEstimate(
        eligible: json['eligible'] ?? false,
        fareRange: json['fare_range'] == null
            ? null
            : FareRange.fromJson(json['fare_range']),
        blockAmount: json['block_amount'],
        vehicleTypeIds: json['vehicle_type_ids'] == null
            ? []
            : List<String>.from(json['vehicle_type_ids'].map((x) => x)),
        currency: json['currency'],
      );

  int? get minFare => fareRange?.min;
  int? get maxFare => fareRange?.max;

  Map<String, dynamic> toJson() => {
    'eligible': eligible,
    'fare_range': fareRange?.toJson(),
    'block_amount': blockAmount,
    'vehicle_type_ids': vehicleTypeIds == null
        ? []
        : List<dynamic>.from(vehicleTypeIds!.map((x) => x)),
    'currency': currency,
  };
}

class FareRange {
  final int? min;
  final int? max;

  const FareRange({this.min, this.max});

  factory FareRange.fromRawJson(String str) =>
      FareRange.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FareRange.fromJson(Map<String, dynamic> json) =>
      FareRange(min: json['min'], max: json['max']);

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
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
  final int? waypointCharge;
  final int? minimumFare;
  final int? maxPassengers;
  final String? currency;
  final bool? promoApplied;
  final int? promoDiscount;
  final int? discountedFare;
  final String? promoError;
  final bool isBookAnyOption;
  final int? bookAnyMinFare;
  final int? bookAnyMaxFare;

  const FareEstimateItem({
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

  factory FareEstimateItem.fromRawJson(String str) =>
      FareEstimateItem.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory FareEstimateItem.fromJson(Map<String, dynamic> json) =>
      FareEstimateItem(
        vehicleTypeId: json['vehicle_type_id'],
        vehicleName: json['vehicle_name'],
        displayName: json['display_name'],
        fareEstimate: json['fare_estimate'],
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        durationMinutes: json['duration_minutes'],
        baseFare: json['base_fare'],
        perKmCharge: json['per_km_charge'],
        perMinCharge: json['per_min_charge'],
        waypointCharge: json['waypoint_charge'],
        minimumFare: json['minimum_fare'],
        maxPassengers: json['max_passengers'],
        currency: json['currency'],
        promoApplied: json['promo_applied'],
        promoDiscount: json['promo_discount'],
        discountedFare: json['discounted_fare'],
        promoError: json['promo_error'],
        isBookAnyOption: json['is_book_any_option'] ?? false,
        bookAnyMinFare: json['book_any_min_fare'],
        bookAnyMaxFare: json['book_any_max_fare'],
      );

  int get originalFare => fareEstimate ?? 0;
  int get displayFare => discountedFare ?? fareEstimate ?? 0;

  Map<String, dynamic> toJson() => {
    'vehicle_type_id': vehicleTypeId,
    'vehicle_name': vehicleName,
    'display_name': displayName,
    'fare_estimate': fareEstimate,
    'distance_km': distanceKm,
    'duration_minutes': durationMinutes,
    'base_fare': baseFare,
    'per_km_charge': perKmCharge,
    'per_min_charge': perMinCharge,
    'waypoint_charge': waypointCharge,
    'minimum_fare': minimumFare,
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

class RouteGeometry {
  final String? type;
  final List<List<double>>? coordinates;

  const RouteGeometry({this.type, this.coordinates});

  factory RouteGeometry.fromRawJson(String str) =>
      RouteGeometry.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory RouteGeometry.fromJson(Map<String, dynamic> json) => RouteGeometry(
    type: json['type'],
    coordinates: json['coordinates'] == null
        ? []
        : List<List<double>>.from(
            json['coordinates'].map(
              (x) => List<double>.from(
                x.map((value) => (value as num).toDouble()),
              ),
            ),
          ),
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates == null
        ? []
        : List<dynamic>.from(
            coordinates!.map((x) => List<dynamic>.from(x.map((x) => x))),
          ),
  };
}
