import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';

class FareEstimateModel {
  final List<FareEstimateItem> estimates;
  final RouteGeometry? routeGeometry;
  final List<FareLeg>? legs;
  final FareEstimateLocation? pickup;
  final List<FareEstimateLocation> stops;
  final FareEstimateLocation? destination;
  final bool? isMultiStop;
  final BookAnyEstimate? bookAny;

  FareEstimateModel({
    required this.estimates,
    this.routeGeometry,
    this.legs,
    this.pickup,
    this.stops = const [],
    this.destination,
    this.isMultiStop,
    this.bookAny,
  });

  factory FareEstimateModel.fromResponse(FareEstimateResponseModel response) {
    final data = response.data;
    return FareEstimateModel(
      estimates: data?.estimates ?? const [],
      routeGeometry: data?.routeGeometry,
      legs: data?.legs,
      pickup: data?.pickup,
      stops: data?.stops ?? const [],
      destination: data?.destination,
      isMultiStop: data?.isMultiStop,
      bookAny: data?.bookAny,
    );
  }

  factory FareEstimateModel.fromJson(Map<String, dynamic> json) {
    return FareEstimateModel.fromResponse(
      FareEstimateResponseModel.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimates': estimates.map((e) => e.toJson()).toList(),
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
