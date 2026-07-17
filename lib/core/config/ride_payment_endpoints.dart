import '../network/urls.dart';
import 'app_config.dart';

/// Resolves ride payment / mutation API paths from [URLS].
///
/// Bypass (`true`): canonical paths as defined in [URLS].
/// Production (`false`): same paths with `_new` appended (real wallet preauth).
abstract final class RidePaymentEndpoints {
  static const _productionSuffix = '_new';

  static String _forPaymentMode(String endpoint) =>
      AppConfig.ridePaymentBypass ? endpoint : '$endpoint$_productionSuffix';

  static String get validateRidePayment =>
      _forPaymentMode(URLS.payment.validateRidePayment);

  static String get bookRide => _forPaymentMode(URLS.ride.bookRide);

  static String updateDestination(String rideId) =>
      _forPaymentMode(URLS.ride.updateDestination(rideId));

  static String updateStops(String rideId) =>
      _forPaymentMode(URLS.ride.updateStops(rideId));
}
