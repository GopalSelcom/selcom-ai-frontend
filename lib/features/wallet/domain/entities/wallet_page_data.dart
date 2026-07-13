import 'wallet_summary_entity.dart';
import 'wallet_transaction_entity.dart';

/// Summary and recent transactions loaded with a single card-balance request.
class WalletPageData {
  const WalletPageData({
    required this.summary,
    required this.transactions,
  });

  final WalletSummaryEntity summary;
  final List<WalletTransactionEntity> transactions;
}
