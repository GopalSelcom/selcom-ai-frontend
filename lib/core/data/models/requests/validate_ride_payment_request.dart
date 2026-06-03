import '../../../domain/entities/location_entity.dart';

class ValidateRidePaymentRequest {
  final int fareEstimate;
  final String paymentMethod;
  final String vehicleTypeId;
  final LocationEntity pickup;

  /// Ordered drop points: last item is the final destination.
  /// Single-stop rides send one entry; multi-stop sends intermediates then final.
  final List<LocationEntity> destinations;

  const ValidateRidePaymentRequest({
    required this.fareEstimate,
    required this.paymentMethod,
    required this.vehicleTypeId,
    required this.pickup,
    required this.destinations,
  });

  Map<String, dynamic> toJson() {
    return {
      'fare_estimate': fareEstimate,
      'payment_method': paymentMethod,
      'vehicle_type_id': vehicleTypeId,
      'pickup': {
        'coordinates': [pickup.lng, pickup.lat],
      },
      'destinations': destinations
          .map(
            (d) => {
              'lat': d.lat,
              'lng': d.lng,
              'address': d.address,
            },
          )
          .toList(),
    };
  }
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
