class WalletDetailsEntity {
  const WalletDetailsEntity({
    required this.accountNo,
    this.name,
    this.address,
    this.city,
    this.dob,
    this.maskedCard,
    this.expiry,
    this.status,
    this.isPrepaid = true,
    this.limitAmount,
    this.createdOn,
  });

  final String accountNo;
  final String? name;
  final String? address;
  final String? city;
  final String? dob;
  final String? maskedCard;
  final String? expiry;
  final int? status;
  final bool isPrepaid;
  final num? limitAmount;
  final DateTime? createdOn;

  bool get isActive => status == 1;

  bool get hasWallet => accountNo.trim().isNotEmpty;
}
