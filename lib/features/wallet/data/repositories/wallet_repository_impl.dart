import '../../domain/entities/wallet_details_entity.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_data_source.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required WalletRemoteDataSource remoteDataSource,
    required WalletLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final WalletRemoteDataSource _remoteDataSource;
  final WalletLocalDataSource _localDataSource;

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
  }) =>
      _localDataSource.getTransactions(filter: filter);
}
