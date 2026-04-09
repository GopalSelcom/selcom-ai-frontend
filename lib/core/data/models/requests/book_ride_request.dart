import '../../../domain/entities/location_entity.dart';

class BookRideRequest {
  final String validationId;
  final String idempotencyKey;
  final LocationEntity pickup;
  final LocationEntity destination;
  final String vehicleTypeId;
  final String paymentMethod;

  const BookRideRequest({
    required this.validationId,
    required this.idempotencyKey,
    required this.pickup,
    required this.destination,
    required this.vehicleTypeId,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'validation_id': validationId,
      'idempotency_key': idempotencyKey,
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
      'payment_method': paymentMethod,
    };
  }
}
