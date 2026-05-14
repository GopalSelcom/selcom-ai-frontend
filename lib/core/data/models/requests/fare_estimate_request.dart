import '../../../domain/entities/location_entity.dart';

class FareEstimateRequest {
  final LocationEntity pickup;
  final LocationEntity? destination;
  final List<LocationEntity>? destinations;
  /// When set, estimate API returns per-vehicle promo fields.
  final String? promoCode;

  const FareEstimateRequest({
    required this.pickup,
    this.destination,
    this.destinations,
    this.promoCode,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'pickup': {
        'lat': pickup.lat,
        'lng': pickup.lng,
        'address': pickup.address,
      },
    };

    if (destinations != null && destinations!.isNotEmpty) {
      data['destinations'] = destinations!
          .map((d) => {'lat': d.lat, 'lng': d.lng, 'address': d.address})
          .toList();
    } else if (destination != null) {
      data['destination'] = {
        'lat': destination!.lat,
        'lng': destination!.lng,
        'address': destination!.address,
      };
    }

    final code = promoCode?.trim();
    if (code != null && code.isNotEmpty) {
      data['promo_code'] = code.toUpperCase();
    }

    return data;
  }
}
