class SelcomPesaTopupStatusResult {
  const SelcomPesaTopupStatusResult({
    required this.transid,
    required this.amount,
    required this.mobileNumber,
    required this.accountNo,
    required this.status,
    required this.fundedStatus,
    required this.isPaid,
    this.message = '',
  });

  final String transid;
  final int amount;
  final String mobileNumber;
  final String accountNo;
  final String status;
  final String fundedStatus;
  final bool isPaid;
  final String message;

  factory SelcomPesaTopupStatusResult.fromEnvelope(Map<String, dynamic> json) {
    final payload = json['response'];
    final data = payload is Map<String, dynamic> ? payload : json;
    return SelcomPesaTopupStatusResult(
      transid: data['transid']?.toString() ?? '',
      amount: _parseInt(data['amount']) ?? 0,
      mobileNumber: data['mobile_number']?.toString() ?? '',
      accountNo: data['account_no']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      fundedStatus: data['funded_status']?.toString() ?? '',
      isPaid: data['is_paid'] == true,
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isUssdTerminalFailure {
    final normalized = status.trim().toUpperCase();
    return normalized == 'REJECTED' || normalized == 'FAILED';
  }

  bool get isFundCreditTerminalFailure {
    if (status.trim().toUpperCase() != 'ACCEPTED') return false;
    final funded = fundedStatus.trim().toLowerCase();
    return funded == 'failed' ||
        funded == 'wallet_missing' ||
        funded == 'error';
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
