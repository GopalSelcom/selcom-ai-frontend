import 'package:intl/intl.dart';

/// Wallet screen shows up to this many recent transactions before "View all".
const int walletRecentTransactionPreviewLimit = 3;

/// Card statement default lookback (see [walletStatementDefaultDays] in domain utils).
const int walletStatementDefaultDays = 30;

(String startDate, String endDate) defaultWalletStatementDateRange({
  int days = walletStatementDefaultDays,
  DateTime? end,
}) {
  final rangeEnd = end ?? DateTime.now();
  final rangeStart = rangeEnd.subtract(Duration(days: days));
  final formatter = DateFormat('yyyy-MM-dd');
  return (formatter.format(rangeStart), formatter.format(rangeEnd));
}
