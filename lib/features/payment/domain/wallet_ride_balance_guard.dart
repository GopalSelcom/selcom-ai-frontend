import 'models/insufficient_wallet_balance_details.dart';

/// Pre-book wallet sufficiency checks until payment backend is authoritative.
///
/// TODO(payment-backend):
/// 1. Add dedicated sufficiency check on `POST go/validate_ride_payment` (or new
///    `go/wallet/check-ride-payment`) returning `PAY_INSUFFICIENT_FUNDS` with
///    `current_balance`, `required_amount`, `amount_needed`.
/// 2. Prefer server amounts over [fromClientCheck]; remove client compare when stable.
/// 3. Replace [walletDummyPaymentRequest] dev bypass with real wallet debit callback.
/// 4. Wire top-up to the production wallet load / Selcom Pesa flow (not only profile).
class WalletRideBalanceGuard {
  const WalletRideBalanceGuard._();

  /// Returns breakdown when [currentBalance] is below [requiredAmount].
  static InsufficientWalletBalanceDetails? insufficientDetails({
    required double currentBalance,
    required int requiredAmount,
    required String currency,
  }) {
    if (requiredAmount <= 0) return null;
    if (currentBalance >= requiredAmount) return null;
    return InsufficientWalletBalanceDetails.fromClientCheck(
      currentBalance: currentBalance,
      requiredAmount: requiredAmount,
      currency: currency,
    );
  }
}
