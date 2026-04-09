class ValidateRidePaymentRequest {
  final int fareEstimate;
  final String paymentMethod;
  final String vehicleTypeId;

  const ValidateRidePaymentRequest({
    required this.fareEstimate,
    required this.paymentMethod,
    required this.vehicleTypeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fare_estimate': fareEstimate,
      'payment_method': paymentMethod,
      'vehicle_type_id': vehicleTypeId,
    };
  }
}
