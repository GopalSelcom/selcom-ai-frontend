import '../entities/wallet_details_entity.dart';
import '../../../payment/data/models/go_other_payment_methods_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_models.dart';
import '../entities/wallet_summary_entity.dart';
import '../entities/wallet_transaction_entity.dart';
import '../entities/wallet_transaction_filter.dart';

abstract class WalletRepository {
  Future<WalletDetailsEntity?> getWalletDetails();

  Future<WalletSummaryEntity> getWalletSummary();

  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  });

  Future<TanQrPaymentSession> initiateTanQrTopUp(
    GoOtherPaymentMethodsRequest request,
  );

  Future<TanQrPaymentSession> initiateMobileMoneyTopUp(
    GoOtherPaymentMethodsRequest request,
  );

  Future<PaymentStatusResult> checkPaymentStatus({
    required String transid,
  });

  Future<void> cancelUssdOrder({required String transid});

  Future<SelcomPesaTopupResult> sendSelcomPesaTopUpRequest(
    SelcomPesaTopupRequest request, {
    required bool requireShortCode,
  });
}
