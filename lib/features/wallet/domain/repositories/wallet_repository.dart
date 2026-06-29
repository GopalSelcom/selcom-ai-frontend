import '../../../payment/data/models/go_other_payment_methods_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_status_models.dart';
import '../entities/wallet_details_entity.dart';
import '../entities/wallet_statement_email_result.dart';
import '../entities/wallet_summary_entity.dart';
import '../entities/wallet_transaction_entity.dart';
import '../entities/wallet_transaction_filter.dart';

abstract class WalletRepository {
  Future<WalletDetailsEntity?> getWalletDetails();

  Future<WalletSummaryEntity> getWalletSummary();

  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  });

  void invalidateStatementCache();

  Future<WalletStatementEmailResult> emailWalletStatement({
    required String email,
    required String startDate,
    required String endDate,
    required String currency,
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

  Future<void> cancelUssdOrder({
    required String transid,
    required String paymentMethod,
  });

  Future<SelcomPesaTopupResult> sendSelcomPesaTopUpRequest(
    SelcomPesaTopupRequest request, {
    required bool requireShortCode,
  });

  Future<SelcomPesaTopupStatusResult> simulateSelcomPesaTopUp(
    SelcomPesaTopupRequest request,
  );

  Future<SelcomPesaTopupStatusResult> checkSelcomPesaTopUpStatus({
    required String transid,
  });
}
