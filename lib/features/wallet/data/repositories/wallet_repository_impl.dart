import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required WalletLocalDataSource localDataSource})
    : _localDataSource = localDataSource;

  final WalletLocalDataSource _localDataSource;

  @override
  Future<WalletSummaryEntity> getWalletSummary() =>
      _localDataSource.getWalletSummary();

  @override
  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  }) =>
      _localDataSource.getTransactions(filter: filter);
}
