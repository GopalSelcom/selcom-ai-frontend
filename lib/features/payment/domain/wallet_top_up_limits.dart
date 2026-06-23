/// Wallet top-up validation limits.
///
/// Replace [maxTopUpAmount] when the production limit is available from API/settings.
class WalletTopUpLimits {
  const WalletTopUpLimits._();

  static const int maxTopUpAmount = 5000000;
}
