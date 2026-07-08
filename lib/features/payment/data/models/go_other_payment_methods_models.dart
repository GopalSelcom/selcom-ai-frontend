class GoOtherPaymentMethodsRequest {
  const GoOtherPaymentMethodsRequest({
    required this.totalPrice,
    required this.ussdPhoneNumber,
    this.paymentMode = paymentModeMobileMoney,
    this.sqrAmount = 0,
  });

  static const String paymentModeMobileMoney = 'Mobile Money';

  /// `payment_method` values for [WalletRepository.cancelUssdOrder].
  static const String cancelUssdPaymentMethodMobileMoney = 'mobile_money';
  static const String cancelUssdPaymentMethodSelcomPesa = 'selcom_pesa';

  final int totalPrice;
  final String ussdPhoneNumber;
  final String paymentMode;
  final int sqrAmount;

  Map<String, dynamic> toJson() {
    return {
      'amount': totalPrice,
      // 'payment_mode': paymentMode,
      'mobile_number': ussdPhoneNumber,
      // 'sqr_amount': sqrAmount,
    };
  }
}

/// Session returned by wallet top-up initiate APIs (e.g. Mobile Money).
class WalletTopUpSession {
  const WalletTopUpSession({
    this.qr = '',
    this.orderId = '',
    this.paymentToken = '',
    this.transid = '',
  });

  final String qr;
  final String orderId;
  final String paymentToken;
  final String transid;

  factory WalletTopUpSession.fromJson(Map<String, dynamic> json) {
    return WalletTopUpSession(
      qr: json['qr']?.toString() ?? '',
      orderId: _readString(json, const ['order_id', 'orderId']),
      paymentToken: _readString(json, const ['payment_token', 'paymentToken']),
      transid: _readString(json, const ['transid', 'trans_id', 'transId']),
    );
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }
}

class PaymentStatusResult {
  const PaymentStatusResult({
    required this.isPaid,
    this.message = '',
  });

  final bool isPaid;
  final String message;

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    final isPaid = json['is_paid'] == true || json['isPaid'] == true;
    return PaymentStatusResult(
      isPaid: isPaid,
      message: json['message']?.toString() ?? '',
    );
  }
}

enum MobileMoneyTopupResult { success, cancelled }
