import '../../../domain/entities/location_entity.dart';

class FareEstimateRequest {
  final LocationEntity pickup;
  final LocationEntity destination;
  final List<LocationEntity> stops;
  final String? vehicleTypeId;
  final String? promoCode;

  const FareEstimateRequest({
    required this.pickup,
    required this.destination,
    this.stops = const [],
    this.vehicleTypeId,
    this.promoCode,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'pickup': _locationJson(pickup),
    };

    if (stops.isNotEmpty) {
      data['stops'] = stops.map(_locationJson).toList();
    }

    data['destination'] = _locationJson(destination);

    final vehicleId = vehicleTypeId?.trim();
    if (vehicleId != null && vehicleId.isNotEmpty) {
      data['vehicle_type_id'] = vehicleId;
    }

    final code = promoCode?.trim();
    if (code != null && code.isNotEmpty) {
      data['promo_code'] = code.toUpperCase();
    }

    return data;
  }

  static Map<String, dynamic> _locationJson(LocationEntity location) => {
        'lat': location.lat,
        'lng': location.lng,
        'address': location.address,
      };
}
