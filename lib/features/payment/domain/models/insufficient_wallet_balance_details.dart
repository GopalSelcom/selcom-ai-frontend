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

  /// Parses insufficient-wallet payloads from ride payment / stop-update APIs.
  ///
  /// Supported `error_code` values: `PAY_INSUFFICIENT_FUNDS`, `INSUFFICIENT_BALANCE`.
  /// Expected `data`: `required` + `available`, or legacy balance field names.
  static const Set<String> _insufficientBalanceErrorCodes = {
    'PAY_INSUFFICIENT_FUNDS',
    'INSUFFICIENT_BALANCE',
  };

  static bool isInsufficientBalanceErrorCode(String? errorCode) {
    if (errorCode == null || errorCode.isEmpty) return false;
    return _insufficientBalanceErrorCodes.contains(errorCode);
  }

  static InsufficientWalletBalanceDetails? tryParseFromApiResponse(
    dynamic raw,
  ) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final errorCode = map['error_code'] as String?;
    if (errorCode != null && !isInsufficientBalanceErrorCode(errorCode)) {
      return null;
    }

    final payload = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;

    final current = _readAmount(payload, const [
      'available',
      'current_balance',
      'wallet_balance',
      'balance',
    ]);
    final required = _readAmount(payload, const [
      'required',
      'required_amount',
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
      if (!isInsufficientBalanceErrorCode(errorCode)) return null;
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
