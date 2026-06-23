import '../../../domain/entities/location_entity.dart';

class BookRideRequest {
  final String validationId;
  final String idempotencyKey;
  final LocationEntity pickup;
  final LocationEntity destination;
  final List<LocationEntity> stops;
  final String? vehicleTypeId;
  final bool bookAny;
  final String paymentMethod;
  final bool isBookedForOther;
  final String? passengerName;
  final String? passengerPhone;
  final String note;
  final int? fareEstimate;
  final String? promoCode;

  const BookRideRequest({
    required this.validationId,
    required this.idempotencyKey,
    required this.pickup,
    required this.destination,
    this.stops = const [],
    this.vehicleTypeId,
    this.bookAny = false,
    required this.paymentMethod,
    this.isBookedForOther = false,
    this.passengerName,
    this.passengerPhone,
    this.note = '',
    this.fareEstimate,
    this.promoCode,
  });

  Map<String, dynamic> toJson() {
    if (bookAny) {
      final data = <String, dynamic>{
        'validation_id': validationId,
        'idempotency_key': idempotencyKey,
        'book_any': true,
        'payment_method': paymentMethod,
        'pickup': _locationJson(pickup),
        'stops': stops.map(_locationJson).toList(),
        'destination': _locationJson(destination),
      };
      if (isBookedForOther) {
        data['is_booked_for_other'] = true;
        if (passengerName != null) data['passenger_name'] = passengerName;
        if (passengerPhone != null) data['passenger_phone'] = passengerPhone;
      }
      return data;
    }

    final data = <String, dynamic>{
      'validation_id': validationId,
      'idempotency_key': idempotencyKey,
      'pickup': _locationJson(pickup),
    };

    if (stops.isNotEmpty) {
      data['stops'] = stops.map(_locationJson).toList();
    }

    data['destination'] = _locationJson(destination);

    if (vehicleTypeId != null && vehicleTypeId!.trim().isNotEmpty) {
      data['vehicle_type_id'] = vehicleTypeId;
    }

    data['payment_method'] = paymentMethod;
    data['is_booked_for_other'] = isBookedForOther;
    data['note'] = note;

    if (fareEstimate != null) {
      data['fare_estimate'] = fareEstimate;
    }

    final promo = promoCode?.trim();
    if (promo != null && promo.isNotEmpty) {
      data['promo_code'] = promo.toUpperCase();
    }

    if (isBookedForOther) {
      if (passengerName != null) data['passenger_name'] = passengerName;
      if (passengerPhone != null) data['passenger_phone'] = passengerPhone;
    }

    return data;
  }

  static Map<String, dynamic> _locationJson(LocationEntity location) => {
    'lat': location.lat,
    'lng': location.lng,
    'address': location.address,
  };
}
