import '../../../domain/entities/location_entity.dart';

class BookRideRequest {
  final String validationId;
  final String idempotencyKey;
  final LocationEntity pickup;
  final LocationEntity? destination;
  final List<LocationEntity>? destinations;
  final String vehicleTypeId;
  final String paymentMethod;
  final bool isBookedForOther;
  final String? passengerName;
  final String? passengerPhone;

  const BookRideRequest({
    required this.validationId,
    required this.idempotencyKey,
    required this.pickup,
    this.destination,
    this.destinations,
    required this.vehicleTypeId,
    required this.paymentMethod,
    this.isBookedForOther = false,
    this.passengerName,
    this.passengerPhone,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'validation_id': validationId,
      'idempotency_key': idempotencyKey,
      'pickup': {
        'lat': pickup.lat,
        'lng': pickup.lng,
        'address': pickup.address,
      },
      'vehicle_type_id': vehicleTypeId,
      'payment_method': paymentMethod,
      'is_booked_for_other': isBookedForOther,
    };

    if (isBookedForOther) {
      if (passengerName != null) data['passenger_name'] = passengerName;
      if (passengerPhone != null) data['passenger_phone'] = passengerPhone;
    }

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

    return data;
  }
}
