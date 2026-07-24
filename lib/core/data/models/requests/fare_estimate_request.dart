import '../../../domain/entities/location_entity.dart';

class FareEstimateRequest {
  final LocationEntity pickup;
  final LocationEntity destination;
  final List<LocationEntity> stops;
  final String? vehicleTypeId;
  final String? promoCode;

  /// When `true`, backend must not auto-apply promos (rider opted out).
  final bool disableAutoPromo;

  const FareEstimateRequest({
    required this.pickup,
    required this.destination,
    this.stops = const [],
    this.vehicleTypeId,
    this.promoCode,
    this.disableAutoPromo = false,
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

    if (disableAutoPromo) {
      data['disable_auto_promo'] = true;
    }

    return data;
  }

  static Map<String, dynamic> _locationJson(LocationEntity location) => {
        'lat': location.lat,
        'lng': location.lng,
        'address': location.address,
      };
}
