class WalletSummaryEntity {
  const WalletSummaryEntity({
    required this.balance,
    required this.walletNumber,
    required this.currency,
  });

  final double balance;
  final String walletNumber;
  final String currency;
}
