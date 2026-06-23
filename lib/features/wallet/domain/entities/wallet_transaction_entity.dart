class WalletTransactionEntity {
  const WalletTransactionEntity({
    required this.id,
    required this.merchantName,
    required this.categoryLabel,
    required this.amount,
    required this.isCredit,
    required this.createdAt,
    required this.currency,
  });

  final String id;
  final String merchantName;
  final String categoryLabel;
  final double amount;
  final bool isCredit;
  final DateTime createdAt;
  final String currency;
}
