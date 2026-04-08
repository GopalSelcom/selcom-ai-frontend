/// This model represents the trip-specific estimate returned for each vehicle type.
class RideEstimateModel {
  final String vehicleType;
  final String label;
  final int fare;
  final String currency;
  final int etaMinutes;

  RideEstimateModel({
    required this.vehicleType,
    required this.label,
    required this.fare,
    required this.currency,
    required this.etaMinutes,
  });

  factory RideEstimateModel.fromJson(Map<String, dynamic> json) {
    return RideEstimateModel(
      vehicleType: json['vehicle_type'] ?? '',
      label: json['label'] ?? '',
      fare: (json['fare'] is int)
          ? json['fare']
          : int.tryParse(json['fare'].toString()) ?? 0,
      currency: json['currency'] ?? 'TZS',
      etaMinutes: json['eta_pickup_min'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType,
      'label': label,
      'fare': fare,
      'currency': currency,
      'eta_pickup_min': etaMinutes,
    };
  }
}

class FareEstimateModel {
  final List<RideEstimateModel> estimates;
  final double distanceKm;
  final int durationMin;

  FareEstimateModel({
    required this.estimates,
    required this.distanceKm,
    required this.durationMin,
  });

  factory FareEstimateModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return FareEstimateModel(
      estimates: (data['estimates'] as List?)
              ?.map((e) => RideEstimateModel.fromJson(e))
              .toList() ??
          [],
      distanceKm: (data['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMin: (data['duration_min'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimates': estimates.map((e) => e.toJson()).toList(),
      'distance_km': distanceKm,
      'duration_min': durationMin,
    };
  }
}
