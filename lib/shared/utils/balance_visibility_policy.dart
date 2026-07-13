/// Shared timing and masking tokens for wallet / Selcom Pesa balance reveal flows.
abstract final class BalanceVisibilityPolicy {
  BalanceVisibilityPolicy._();

  /// How long a revealed balance stays visible before auto-masking again.
  static const Duration autoHideAfterReveal = Duration(seconds: 30);

  /// Masked digits when balance amount is hidden (currency shown separately).
  static const String hiddenBalancePlaceholder = '••••••';
}
