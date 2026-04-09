import '../../../domain/entities/location_entity.dart';

class FareEstimateRequest {
  final LocationEntity pickup;
  final LocationEntity destination;

  const FareEstimateRequest({required this.pickup, required this.destination});

  Map<String, dynamic> toJson() {
    return {
      'pickup': {
        'coordinates': [pickup.lng, pickup.lat],
        'address': pickup.address,
      },
      'destination': {
        'coordinates': [destination.lng, destination.lat],
        'address': destination.address,
      },
    };
  }
}
