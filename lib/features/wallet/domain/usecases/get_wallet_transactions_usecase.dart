import '../../data/models/go_card_statement_response.dart';
import '../entities/wallet_transaction_filter.dart';
import '../repositories/wallet_repository.dart';

class GetWalletTransactionsUseCase {
  const GetWalletTransactionsUseCase(this._repository);

  final WalletRepository _repository;

  Future<List<TransactionDatum>> call({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
    String? currencyOverride,
  }) =>
      _repository.getTransactions(
        filter: filter,
        currencyOverride: currencyOverride,
      );
}
