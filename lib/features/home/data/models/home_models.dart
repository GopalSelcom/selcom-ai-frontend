class VehicleTypeModel {
  final String id;
  final String label;
  final int fare;
  final String currency;
  final int etaMinutes;
  final String imageUrl;

  VehicleTypeModel({
    required this.id,
    required this.label,
    required this.fare,
    required this.currency,
    required this.etaMinutes,
    required this.imageUrl,
  });

  factory VehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return VehicleTypeModel(
      id: json['vehicle_type'] ?? '',
      label: json['label'] ?? '',
      fare: (json['fare'] is int) ? json['fare'] : int.parse(json['fare'].toString()),
      currency: json['currency'] ?? 'TZS',
      etaMinutes: json['eta_pickup_min'] ?? 0,
      imageUrl: _getImageForType(json['vehicle_type']),
    );
  }

  static String _getImageForType(String? type) {
    switch (type) {
      case 'boda': return 'assets/images/boda.png';
      case 'bajaj': return 'assets/images/bajaj.png';
      case 'gari': return 'assets/images/gari.png';
      case 'gari_plus': return 'assets/images/gari_plus.png';
      default: return 'assets/images/gari.png';
    }
  }
}

class FareEstimateModel {
  final List<VehicleTypeModel> estimates;
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
              ?.map((e) => VehicleTypeModel.fromJson(e))
              .toList() ??
          [],
      distanceKm: (data['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMin: data['duration_min'] ?? 0,
    );
  }
}
