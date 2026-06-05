class WalletOtherPaymentTopupRequest {
  const WalletOtherPaymentTopupRequest({
    required this.totalPrice,
    required this.paymentMode,
    required this.ussdPhoneNumber,
    required this.sqrAmount,
  });

  final int totalPrice;
  final String paymentMode;
  final int ussdPhoneNumber;
  final int sqrAmount;

  Map<String, dynamic> toJson() => {
    'total_price': totalPrice,
    'payment_mode': paymentMode,
    'ussd_phone_number': ussdPhoneNumber,
    'sqr_amount': sqrAmount,
  };
}
