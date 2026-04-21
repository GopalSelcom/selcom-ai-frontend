class PaymentCard {
  final String brand;
  final String fullNumber;
  final String expiry;
  final String cvv;
  final String nickName;
  final bool isExpired;

  const PaymentCard({
    required this.brand,
    required this.fullNumber,
    required this.expiry,
    required this.cvv,
    required this.nickName,
    this.isExpired = false,
  });

  String get maskedNumber {
    final digitsOnly = fullNumber.replaceAll(' ', '');
    if (digitsOnly.length < 4) return fullNumber;
    final last4 = digitsOnly.substring(digitsOnly.length - 4);
    return '**** $last4';
  }
}
