/// Wallet amounts shown on the insufficient-balance dialog.
class InsufficientWalletBalanceDetails {
  const InsufficientWalletBalanceDetails({
    required this.currentBalance,
    required this.requiredAmount,
    required this.amountNeeded,
    required this.currency,
  });

  final double currentBalance;
  final double requiredAmount;
  final double amountNeeded;
  final String currency;

  /// Client-side guard until payment backend returns authoritative breakdown.
  ///
  /// TODO(payment-backend): Remove or demote when `POST go/validate_ride_payment`
  /// (or dedicated wallet sufficiency API) returns official amounts.
  factory InsufficientWalletBalanceDetails.fromClientCheck({
    required double currentBalance,
    required int requiredAmount,
    required String currency,
  }) {
    final required = requiredAmount.toDouble();
    final needed =
        (required - currentBalance).clamp(0.0, double.infinity).toDouble();
    return InsufficientWalletBalanceDetails(
      currentBalance: currentBalance,
      requiredAmount: required,
      amountNeeded: needed,
      currency: currency,
    );
  }

  /// Parses `PAY_INSUFFICIENT_FUNDS` payloads when payment backend is ready.
  ///
  /// Expected shape (flexible): `data` object or root with
  /// `current_balance`, `required_amount`, `amount_needed` (or `shortfall`).
  static InsufficientWalletBalanceDetails? tryParseFromApiResponse(
    dynamic raw,
  ) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final errorCode = map['error_code'] as String?;
    if (errorCode != null && errorCode != 'PAY_INSUFFICIENT_FUNDS') {
      return null;
    }

    final payload = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;

    final current = _readAmount(payload, const [
      'current_balance',
      'wallet_balance',
      'balance',
    ]);
    final required = _readAmount(payload, const [
      'required_amount',
      'required',
      'fare_estimate',
      'fare',
    ]);
    var needed = _readAmount(payload, const [
      'amount_needed',
      'shortfall',
      'deficit',
    ]);
    final currency =
        (payload['currency'] as String?)?.trim() ?? 'TZS';

    if (current == null || required == null) {
      if (errorCode != 'PAY_INSUFFICIENT_FUNDS') return null;
      return null;
    }

    needed ??=
        (required - current).clamp(0.0, double.infinity).toDouble();
    if (needed <= 0) return null;

    return InsufficientWalletBalanceDetails(
      currentBalance: current,
      requiredAmount: required,
      amountNeeded: needed,
      currency: currency,
    );
  }

  static double? _readAmount(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final v = map[key];
      if (v == null) continue;
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
