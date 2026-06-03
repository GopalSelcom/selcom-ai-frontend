import '../../features/payment/domain/models/insufficient_wallet_balance_details.dart';

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Promo validate (`POST go/promo/validate`) — carries server [errorCode].
class PromoValidationFailure extends Failure {
  final String? errorCode;

  const PromoValidationFailure(super.message, {this.errorCode});
}

/// Wallet cannot cover ride fare (`PAY_INSUFFICIENT_FUNDS` or client guard).
class InsufficientWalletBalanceFailure extends Failure {
  final InsufficientWalletBalanceDetails details;

  const InsufficientWalletBalanceFailure(
    super.message, {
    required this.details,
  });
}
