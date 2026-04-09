import '../../../domain/entities/location_entity.dart';
import '../../../domain/entities/ride_entity.dart';

class BookRideRequest {
  final LocationEntity pickup;
  final LocationEntity destination;
  final String vehicleTypeId;
  final PaymentMethod paymentMethod;
  final String idempotencyKey;

  const BookRideRequest({
    required this.pickup,
    required this.destination,
    required this.vehicleTypeId,
    required this.paymentMethod,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'pickup': {
        'lat': pickup.lat,
        'lng': pickup.lng,
        'address': pickup.address,
      },
      'destination': {
        'lat': destination.lat,
        'lng': destination.lng,
        'address': destination.address,
      },
      'vehicle_type_id': vehicleTypeId,
      'payment_method': paymentMethod.name.toLowerCase(), // Ensure it matches backend enum
      'idempotency_key': idempotencyKey,
    };
  }
}
