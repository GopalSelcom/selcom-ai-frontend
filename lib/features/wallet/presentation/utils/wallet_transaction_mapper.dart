import 'package:intl/intl.dart';

import '../../data/models/go_card_statement_response.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../models/wallet_transaction_item.dart';

WalletTransactionItem mapWalletTransactionToItem(
  TransactionDatum datum,
) {
  final fulltimestamp = datum.fulltimestamp ?? '';
  DateTime? parsedDate;
  if (fulltimestamp.isNotEmpty) {
    parsedDate = DateTime.tryParse(fulltimestamp) ??
        DateTime.tryParse(fulltimestamp.replaceFirst(' ', 'T'));
  }
  final dateLabel = parsedDate != null
      ? DateFormat('d MMM yyyy, hh:mm a').format(parsedDate.toLocal())
      : fulltimestamp;

  final normalizedType = (datum.transtype ?? '').trim().toUpperCase();
  final isRelease = normalizedType == 'RELEASE';
  final isCredit = normalizedType == 'CREDIT' ||
      normalizedType == 'CREDITED' ||
      isRelease;
  final parsedAmount = double.tryParse((datum.amount ?? '').trim()) ?? 0;

  final displayTransId = datum.transid?.trim().isNotEmpty == true
      ? datum.transid!.trim()
      : datum.reference?.trim().isNotEmpty == true
          ? datum.reference!.trim()
          : '—';

  final typeLabel = normalizedType.isNotEmpty
      ? '${normalizedType[0]}${normalizedType.substring(1).toLowerCase()}'
      : '—';

  final currency = datum.currency?.trim().isNotEmpty == true
      ? datum.currency!.trim()
      : 'TZS';

  return WalletTransactionItem(
    merchantName: displayTransId,
    categoryLabel: typeLabel,
    amount: parsedAmount,
    isCredit: isCredit,
    showAmountSign: !isRelease,
    createdAtLabel: dateLabel,
    currency: currency,
  );
}

Map<WalletTransactionFilter, List<WalletTransactionItem>>
groupWalletTransactionsByFilter(List<TransactionDatum> transactions) {
  final all = transactions.map(mapWalletTransactionToItem).toList(growable: false);
  return {
    WalletTransactionFilter.all: all,
    WalletTransactionFilter.received:
        all.where((item) => item.isCredit).toList(growable: false),
    WalletTransactionFilter.sent:
        all.where((item) => !item.isCredit).toList(growable: false),
  };
}
