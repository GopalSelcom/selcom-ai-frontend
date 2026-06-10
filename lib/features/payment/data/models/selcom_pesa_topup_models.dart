class SelcomPesaTopupRequest {
  const SelcomPesaTopupRequest({
    required this.cardNo,
    required this.amount,
    required this.accountNo,
    required this.mobileNumber,
    required this.name,
  });

  final String cardNo;
  final int amount;
  final String accountNo;
  final String mobileNumber;
  final String name;

  Map<String, dynamic> toJson() {
    return {
      // 'card_no': cardNo,
      'amount': amount,
      'account_no': accountNo,
      'mobile_number': mobileNumber,
      'name': name,
    };
  }
}

class SelcomPesaTopupResult {
  const SelcomPesaTopupResult({
    required this.transid,
    required this.message,
    this.shortCode = '',
    this.result = '',
    this.resultCode = '',
    this.utilityRef = '',
    this.cardId = '',
  });

  final String transid;
  final String message;
  final String shortCode;
  final String result;
  final String resultCode;
  final String utilityRef;
  final String cardId;

  factory SelcomPesaTopupResult.fromJson(Map<String, dynamic> json) {
    final payload = json['response'];
    final nested = payload is Map<String, dynamic> ? payload : null;
    final data = nested?['data'];
    final dataMap = data is Map<String, dynamic> ? data : null;

    return SelcomPesaTopupResult(
      transid: _readTransid(json, nested),
      message: json['message']?.toString() ?? '',
      shortCode: nested?['shortCode']?.toString() ??
          nested?['short_code']?.toString() ??
          '',
      result: nested?['result']?.toString() ?? '',
      resultCode: nested?['resultCode']?.toString() ??
          nested?['resultcode']?.toString() ??
          '',
      utilityRef: dataMap?['utility_ref']?.toString() ?? '',
      cardId: dataMap?['card_id']?.toString() ?? '',
    );
  }

  static String _readTransid(
    Map<String, dynamic> json,
    Map<String, dynamic>? nested,
  ) {
    for (final source in [json, nested]) {
      if (source == null) continue;
      final value = source['transid']?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}
