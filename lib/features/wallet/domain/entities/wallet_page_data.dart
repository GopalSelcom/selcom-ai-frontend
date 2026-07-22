import '../../data/models/go_card_balance_response.dart';
import '../../data/models/go_card_statement_response.dart';

/// Summary and recent transactions loaded with a single card-balance request.
class WalletPageData {
  const WalletPageData({
    this.cardBalance,
    required this.transactions,
  });

  final GoCardBalanceResponseModel? cardBalance;
  final List<TransactionDatum> transactions;
}
