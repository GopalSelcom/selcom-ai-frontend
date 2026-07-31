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

class AppleSignInFailure extends Failure {
  const AppleSignInFailure(super.message, {this.isCancelled = false});

  final bool isCancelled;
}

class FacebookSignInFailure extends Failure {
  const FacebookSignInFailure(super.message, {this.isCancelled = false});

  final bool isCancelled;
}

class FirebaseAuthFailure extends Failure {
  const FirebaseAuthFailure(super.message, {this.code});

  final String? code;
}

class AccountLinkingFailure extends Failure {
  const AccountLinkingFailure(super.message);
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

/// `POST go/validate_ride_payment` business rejection (409, etc.).
class RidePaymentValidationFailure extends Failure {
  final String errorCode;
  final String? activeRideId;
  final String? activeRideStatus;

  const RidePaymentValidationFailure(
    super.message, {
    required this.errorCode,
    this.activeRideId,
    this.activeRideStatus,
  });
}

/// `PUT go/rides/:id/cancel` returned 409 `RIDE_ALREADY_FINALIZED`
/// (e.g. no-show timer fired at the same moment). Not a user-facing error.
class RideAlreadyFinalizedFailure extends Failure {
  final String errorCode;

  const RideAlreadyFinalizedFailure(
    super.message, {
    this.errorCode = 'RIDE_ALREADY_FINALIZED',
  });
}

/// `POST go/rides/:id/cancellation-request` returned 409 `RIDE_NOT_ACTIVE`.
class RideNotActiveFailure extends Failure {
  final String errorCode;

  const RideNotActiveFailure(
    super.message, {
    this.errorCode = 'RIDE_NOT_ACTIVE',
  });
}

/// `POST go/support/tickets/:id/withdraw-cancellation` returned 409
/// `ALREADY_DECIDED` (CC acted first).
class CancellationRequestAlreadyDecidedFailure extends Failure {
  final String errorCode;

  const CancellationRequestAlreadyDecidedFailure(
    super.message, {
    this.errorCode = 'ALREADY_DECIDED',
  });
}
