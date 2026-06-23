/// Thrown when ride payment validation returns a business error (e.g. 409).
class RidePaymentValidationException implements Exception {
  RidePaymentValidationException({
    required this.errorCode,
    required this.message,
    this.activeRideId,
    this.activeRideStatus,
  });

  final String errorCode;
  final String message;
  final String? activeRideId;
  final String? activeRideStatus;
}
