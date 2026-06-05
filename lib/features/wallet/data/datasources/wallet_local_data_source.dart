import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';

abstract class WalletLocalDataSource {
  Future<WalletSummaryEntity> getWalletSummary();

  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  });
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  static const _summary = WalletSummaryEntity(
    balance: 43829,
    walletNumber: '1601000000038',
    currency: 'TZS',
  );

  static final List<WalletTransactionEntity> _allTransactions = [
    WalletTransactionEntity(
      id: '1',
      merchantName: 'Selcom Paytech',
      categoryLabel: 'Debit - Ticketing',
      amount: 116,
      isCredit: false,
      createdAt: DateTime(2025, 4, 29, 17, 43),
    ),
    WalletTransactionEntity(
      id: '2',
      merchantName: 'Selcom Paytech',
      categoryLabel: 'Debit - Ticketing',
      amount: 116,
      isCredit: false,
      createdAt: DateTime(2025, 4, 28, 14, 20),
    ),
    WalletTransactionEntity(
      id: '3',
      merchantName: 'Selcom Paytech',
      categoryLabel: 'Debit - Ticketing',
      amount: 116,
      isCredit: false,
      createdAt: DateTime(2025, 4, 27, 9, 15),
    ),
    WalletTransactionEntity(
      id: '4',
      merchantName: 'Go Ride',
      categoryLabel: 'Credit - Refund',
      amount: 2500,
      isCredit: true,
      createdAt: DateTime(2025, 4, 26, 11, 0),
    ),
    WalletTransactionEntity(
      id: '5',
      merchantName: 'Mobile Money',
      categoryLabel: 'Credit - Top up',
      amount: 10000,
      isCredit: true,
      createdAt: DateTime(2025, 4, 25, 8, 30),
    ),
    WalletTransactionEntity(
      id: '6',
      merchantName: 'Go Ride',
      categoryLabel: 'Debit - Ride',
      amount: 4200,
      isCredit: false,
      createdAt: DateTime(2025, 4, 24, 19, 5),
    ),
  ];

  @override
  Future<WalletSummaryEntity> getWalletSummary() async => _summary;

  @override
  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return switch (filter) {
      WalletTransactionFilter.all => List.unmodifiable(_allTransactions),
      WalletTransactionFilter.received =>
        _allTransactions.where((t) => t.isCredit).toList(growable: false),
      WalletTransactionFilter.sent =>
        _allTransactions.where((t) => !t.isCredit).toList(growable: false),
    };
  }
}
