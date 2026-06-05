class WalletCardBalanceEntity {
  const WalletCardBalanceEntity({
    required this.available,
    required this.reserved,
    required this.currency,
    required this.pan,
  });

  final double available;
  final double reserved;
  final String currency;
  final String pan;
}
