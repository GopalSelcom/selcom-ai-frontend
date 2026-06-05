import '../../domain/entities/wallet_details_entity.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/utils/wallet_statement_utils.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required WalletRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final WalletRemoteDataSource _remoteDataSource;
  List<WalletTransactionEntity>? _statementCache;

  @override
  Future<WalletDetailsEntity?> getWalletDetails() =>
      _remoteDataSource.getWalletDetails();

  @override
  Future<WalletSummaryEntity> getWalletSummary() async {
    final details = await _remoteDataSource.getWalletDetails();
    final balance = await _remoteDataSource.getCardBalance();

    final walletNumber =
        details?.accountNo.trim().isNotEmpty == true
            ? details!.accountNo
            : balance?.pan ?? '';

    return WalletSummaryEntity(
      balance: balance?.available ?? 0,
      walletNumber: walletNumber,
      currency: balance?.currency ?? 'TZS',
    );
  }

  @override
  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  }) async {
    final all = await _loadStatementTransactions();
    final filtered = switch (filter) {
      WalletTransactionFilter.all => all,
      WalletTransactionFilter.received =>
        all.where((transaction) => transaction.isCredit).toList(growable: false),
      WalletTransactionFilter.sent =>
        all.where((transaction) => !transaction.isCredit).toList(growable: false),
    };
    return List.unmodifiable(filtered);
  }

  Future<List<WalletTransactionEntity>> _loadStatementTransactions() async {
    if (_statementCache != null) {
      return _statementCache!;
    }

    final (startDate, endDate) = defaultWalletStatementDateRange();
    final transactions = await _remoteDataSource.getCardStatement(
      startDate: startDate,
      endDate: endDate,
    );

    final sorted = List<WalletTransactionEntity>.from(transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _statementCache = List.unmodifiable(sorted);
    return _statementCache!;
  }
}
