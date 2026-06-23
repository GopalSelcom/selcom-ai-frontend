class WalletStatementEmailResult {
  const WalletStatementEmailResult({
    required this.message,
    required this.email,
    this.startDate,
    this.endDate,
    required this.records,
    required this.rangeCapped,
  });

  final String message;
  final String email;
  final String? startDate;
  final String? endDate;
  final int records;
  final bool rangeCapped;
}
