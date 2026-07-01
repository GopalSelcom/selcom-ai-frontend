import 'package:intl/intl.dart';

import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../models/wallet_transaction_item.dart';

WalletTransactionItem mapWalletTransactionToItem(
  WalletTransactionEntity entity,
) {
  return WalletTransactionItem(
    merchantName: entity.merchantName,
    categoryLabel: entity.categoryLabel,
    amount: entity.amount,
    isCredit: entity.isCredit,
    showAmountSign: entity.showAmountSign,
    createdAtLabel: DateFormat(
      'd MMM yyyy, hh:mm a',
    ).format(entity.createdAt.toLocal()),
    currency: entity.currency,
  );
}

Map<WalletTransactionFilter, List<WalletTransactionItem>>
groupWalletTransactionsByFilter(List<WalletTransactionEntity> transactions) {
  final all = transactions.map(mapWalletTransactionToItem).toList(growable: false);
  return {
    WalletTransactionFilter.all: all,
    WalletTransactionFilter.received:
        all.where((item) => item.isCredit).toList(growable: false),
    WalletTransactionFilter.sent:
        all.where((item) => !item.isCredit).toList(growable: false),
  };
}
