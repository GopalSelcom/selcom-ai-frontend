import '../../../domain/entities/location_entity.dart';

class ValidateRidePaymentRequest {
  final int? fareEstimate;
  final String? vehicleTypeId;
  final bool bookAny;
  final String paymentMethod;
  final LocationEntity pickup;
  final LocationEntity destination;
  final List<LocationEntity> stops;
  final bool isBookedForOther;
  final String? passengerName;
  final String? passengerPhone;

  const ValidateRidePaymentRequest({
    this.fareEstimate,
    this.vehicleTypeId,
    this.bookAny = false,
    required this.paymentMethod,
    required this.pickup,
    required this.destination,
    this.stops = const [],
    this.isBookedForOther = false,
    this.passengerName,
    this.passengerPhone,
  });

  Map<String, dynamic> toJson() {
    if (bookAny) {
      final data = <String, dynamic>{
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
      'payment_method': paymentMethod,
      'pickup': _locationJson(pickup),
    };

    if (fareEstimate != null) {
      data['fare_estimate'] = fareEstimate;
    }
    if (vehicleTypeId != null && vehicleTypeId!.trim().isNotEmpty) {
      data['vehicle_type_id'] = vehicleTypeId;
    }

    if (stops.isNotEmpty) {
      data['stops'] = stops.map(_locationJson).toList();
    }

    data['destination'] = _locationJson(destination);

    if (isBookedForOther) {
      data['is_booked_for_other'] = true;
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
