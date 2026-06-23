class WalletTransactionItem {
  const WalletTransactionItem({
    required this.merchantName,
    required this.categoryLabel,
    required this.amount,
    required this.isCredit,
    required this.createdAtLabel,
    required this.currency,
  });

  final String merchantName;
  final String categoryLabel;
  final double amount;
  final bool isCredit;
  final String createdAtLabel;
  final String currency;
}
