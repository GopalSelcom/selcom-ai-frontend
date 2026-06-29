class WalletTransactionEntity {
  const WalletTransactionEntity({
    required this.id,
    required this.merchantName,
    required this.categoryLabel,
    required this.amount,
    required this.isCredit,
    required this.showAmountSign,
    required this.createdAt,
    required this.currency,
  });

  final String id;
  final String merchantName;
  final String categoryLabel;
  final double amount;
  final bool isCredit;
  /// When false, amount is shown without `+` / `-` (e.g. RELEASE holds).
  final bool showAmountSign;
  final DateTime createdAt;
  final String currency;
}
