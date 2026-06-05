import '../entities/wallet_details_entity.dart';
import '../entities/wallet_summary_entity.dart';
import '../entities/wallet_transaction_entity.dart';
import '../entities/wallet_transaction_filter.dart';

abstract class WalletRepository {
  Future<WalletDetailsEntity?> getWalletDetails();

  Future<WalletSummaryEntity> getWalletSummary();

  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  });
}
