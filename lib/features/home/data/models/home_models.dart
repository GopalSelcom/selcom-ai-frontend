import '../../../../core/data/models/responses/rides/fare_estimate_response.dart';

class FareEstimateModel {
  final List<FareEstimateItem> estimates;
  final double distanceKm;
  final int durationMin;
  final RouteGeometry? routeGeometry;
  final BookAnyEstimate? bookAny;

  FareEstimateModel({
    required this.estimates,
    required this.distanceKm,
    required this.durationMin,
    this.routeGeometry,
    this.bookAny,
  });

  factory FareEstimateModel.fromResponse(FareEstimateResponseModel response) {
    final data = response.data;
    final estimates = data?.estimates ?? [];

    double distance = 0.0;
    int duration = 0;

    if (estimates.isNotEmpty) {
      // Using distance and duration from the first estimate as general trip info
      distance = estimates.first.distanceKm ?? 0.0;
      duration = estimates.first.durationMinutes ?? 0;
    }

    return FareEstimateModel(
      estimates: estimates,
      distanceKm: distance,
      durationMin: duration,
      routeGeometry: data?.routeGeometry,
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
      'distance_km': distanceKm,
      'duration_min': durationMin,
      'route_geometry': routeGeometry?.toJson(),
    };
  }
}
