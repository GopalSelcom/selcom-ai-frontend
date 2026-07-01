class WalletSummaryEntity {
  const WalletSummaryEntity({
    required this.balance,
    required this.walletNumber,
    required this.currency,
    this.reserved = 0,
  });

  final double balance;
  final String walletNumber;
  final String currency;
  final double reserved;
}
