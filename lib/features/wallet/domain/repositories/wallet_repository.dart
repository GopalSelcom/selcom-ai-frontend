import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../payment/data/models/go_other_payment_methods_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_status_models.dart';
import '../../data/models/go_wallet_card_model.dart';
import '../../data/models/go_add_card_response_model.dart';
import '../../data/models/go_init_card_session_response_model.dart' hide Datum;
import '../../data/models/model_status_msg.dart';
import '../entities/wallet_details_entity.dart';
import '../entities/wallet_page_data.dart';
import '../entities/wallet_statement_email_result.dart';
import '../entities/wallet_summary_entity.dart';
import '../entities/wallet_transaction_entity.dart';
import '../entities/wallet_transaction_filter.dart';

abstract class WalletRepository {
  Future<WalletDetailsEntity?> getWalletDetails();

  Future<WalletSummaryEntity> getWalletSummary();

  /// Loads wallet summary and statement transactions with one card-balance call.
  Future<WalletPageData> getWalletPageData({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  });

  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
    String? currencyOverride,
  });

  void invalidateStatementCache();

  Future<WalletStatementEmailResult> emailWalletStatement({
    required String email,
    required String startDate,
    required String endDate,
    required String currency,
  });

  Future<WalletTopUpSession> initiateMobileMoneyTopUp(
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

  Future<Either<Failure, List<Datum>>> fetchCards();

  Future<Either<Failure, GoAddCardResponseModel>> goAddCardNew({
    required int amount,
    required int newCard,
  });

  Future<Either<Failure, void>> goPayByExistingCard({
    required String transId,
    required String cardToken,
  });

  Future<Either<Failure, InitSessionCardModel>> goInitCardSession({
    required int amount,
    required int newCard,
    required String email,
    required String mobileNumber,
    required String countryCode,
    required String cardBin,
    String? fname,
    String? lname,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalcode,
  });

  Future<Either<Failure, ModelStatusMsg>> deleteCard({
    required int id,
  });
}
