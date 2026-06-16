import '../../../domain/entities/location_entity.dart';

class ValidateRidePaymentRequest {
  final int fareEstimate;
  final String paymentMethod;
  final String vehicleTypeId;
  final LocationEntity pickup;
  final LocationEntity destination;
  final List<LocationEntity> stops;
  final bool isBookedForOther;
  final String? passengerName;
  final String? passengerPhone;

  const ValidateRidePaymentRequest({
    required this.fareEstimate,
    required this.paymentMethod,
    required this.vehicleTypeId,
    required this.pickup,
    required this.destination,
    this.stops = const [],
    this.isBookedForOther = false,
    this.passengerName,
    this.passengerPhone,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'fare_estimate': fareEstimate,
      'payment_method': paymentMethod,
      'vehicle_type_id': vehicleTypeId,
      'pickup': _locationJson(pickup),
    };

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

class DummyPaymentRequest {
  final String validationId;
  final String result;
  final String transId;

  DummyPaymentRequest({
    required this.result,
    required this.transId,
    required this.validationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'validation_id': validationId,
      'result': "SUCCESS",
      'transid': transId,
    };
  }
}
