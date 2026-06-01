import '../../features/payment/domain/models/insufficient_wallet_balance_details.dart';

/// Thrown from data layer when ride payment validation reports low wallet funds.
class InsufficientWalletBalanceException implements Exception {
  InsufficientWalletBalanceException(this.details);

  final InsufficientWalletBalanceDetails details;
}
