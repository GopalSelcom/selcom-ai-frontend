import '../entities/wallet_transaction_entity.dart';
import '../entities/wallet_transaction_filter.dart';
import '../repositories/wallet_repository.dart';

class GetWalletTransactionsUseCase {
  const GetWalletTransactionsUseCase(this._repository);

  final WalletRepository _repository;

  Future<List<WalletTransactionEntity>> call({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  }) =>
      _repository.getTransactions(filter: filter);
}
