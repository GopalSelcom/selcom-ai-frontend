import '../network/urls.dart';

/// Resolves ride payment / mutation API paths from [URLS].
///
/// Always uses the `_new` production suffix (real wallet preauth).
abstract final class RidePaymentEndpoints {
  static const _productionSuffix = '_new';

  static String _forPaymentMode(String endpoint) =>
      '$endpoint$_productionSuffix';

  static String get validateRidePayment =>
      _forPaymentMode(URLS.payment.validateRidePayment);

  static String get bookRide => _forPaymentMode(URLS.ride.bookRide);

  static String updateDestination(String rideId) =>
      _forPaymentMode(URLS.ride.updateDestination(rideId));

  static String updateStops(String rideId) =>
      _forPaymentMode(URLS.ride.updateStops(rideId));
}
