import '../../domain/entities/wallet_details_entity.dart';
import '../../../payment/data/datasources/selcom_pesa_topup_remote_data_source.dart';
import '../../../payment/data/datasources/wallet_payment_remote_data_source.dart';
import '../../../payment/data/models/go_other_payment_methods_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_status_models.dart';
import '../../domain/entities/wallet_statement_email_result.dart';
import '../../domain/entities/wallet_summary_entity.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/utils/wallet_statement_utils.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../models/go_email_card_statement_models.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required WalletRemoteDataSource remoteDataSource,
    required WalletPaymentRemoteDataSource paymentRemoteDataSource,
    required SelcomPesaTopupRemoteDataSource selcomPesaTopupRemoteDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _paymentRemoteDataSource = paymentRemoteDataSource,
       _selcomPesaTopupRemoteDataSource = selcomPesaTopupRemoteDataSource;

  final WalletRemoteDataSource _remoteDataSource;
  List<WalletTransactionEntity>? _statementCache;
  final WalletPaymentRemoteDataSource _paymentRemoteDataSource;
  final SelcomPesaTopupRemoteDataSource _selcomPesaTopupRemoteDataSource;

  @override
  Future<WalletDetailsEntity?> getWalletDetails() async {
    final details = await _remoteDataSource.getWalletDetails();
    if (details != null && details.hasWallet) {
      return details;
    }

    final balance = await _remoteDataSource.getCardBalance();
    final pan = balance?.pan.trim() ?? '';
    if (pan.isEmpty) {
      return details;
    }

    return WalletDetailsEntity(
      accountNo: pan,
      firstName: balance?.holderName,
      status: 1,
    );
  }

  @override
  Future<WalletSummaryEntity> getWalletSummary() async {
    final balance = await _remoteDataSource.getCardBalance();
    final details = await _remoteDataSource.getWalletDetails();

    final walletNumber = _resolveWalletNumber(
      detailsAccountNo: details?.accountNo,
      balancePan: balance?.pan,
    );

    return WalletSummaryEntity(
      balance: balance?.available ?? 0,
      walletNumber: walletNumber,
      currency: balance?.currency ?? 'TZS',
    );
  }

  String _resolveWalletNumber({
    required String? detailsAccountNo,
    required String? balancePan,
  }) {
    final accountNo = detailsAccountNo?.trim() ?? '';
    if (accountNo.isNotEmpty) return accountNo;
    return balancePan?.trim() ?? '';
  }

  @override
  Future<List<WalletTransactionEntity>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  }) async {
    final all = await _loadStatementTransactions();
    final filtered = switch (filter) {
      WalletTransactionFilter.all => all,
      WalletTransactionFilter.received =>
        all
            .where((transaction) => transaction.isCredit)
            .toList(growable: false),
      WalletTransactionFilter.sent =>
        all
            .where((transaction) => !transaction.isCredit)
            .toList(growable: false),
    };
    return List.unmodifiable(filtered);
  }

  @override
  void invalidateStatementCache() {
    _statementCache = null;
  }

  @override
  Future<WalletStatementEmailResult> emailWalletStatement({
    required String email,
    required String startDate,
    required String endDate,
    required String currency,
  }) {
    return _remoteDataSource.emailCardStatement(
      EmailCardStatementRequest(
        email: email,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
      ),
    );
  }

  Future<List<WalletTransactionEntity>> _loadStatementTransactions() async {
    if (_statementCache != null) {
      return _statementCache!;
    }

    final (startDate, endDate) = defaultWalletStatementDateRange();
    final transactions = await _remoteDataSource.getCardStatement(
      startDate: startDate,
      endDate: endDate,
    );

    final sorted = List<WalletTransactionEntity>.from(transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _statementCache = List.unmodifiable(sorted);
    return _statementCache!;
  }

  @override
  Future<TanQrPaymentSession> initiateTanQrTopUp(
    GoOtherPaymentMethodsRequest request,
  ) => _paymentRemoteDataSource.initiateTanQrTopUp(request);

  @override
  Future<TanQrPaymentSession> initiateMobileMoneyTopUp(
    GoOtherPaymentMethodsRequest request,
  ) => _paymentRemoteDataSource.initiateMobileMoneyTopUp(request);

  @override
  Future<PaymentStatusResult> checkPaymentStatus({required String transid}) =>
      _paymentRemoteDataSource.checkPaymentStatus(transid: transid);

  @override
  Future<void> cancelUssdOrder({required String transid}) =>
      _paymentRemoteDataSource.cancelUssdOrder(transid: transid);

  @override
  Future<SelcomPesaTopupResult> sendSelcomPesaTopUpRequest(
    SelcomPesaTopupRequest request, {
    required bool requireShortCode,
  }) => _selcomPesaTopupRemoteDataSource.sendTransferRequest(
    request,
    requireShortCode: requireShortCode,
  );

  @override
  Future<SelcomPesaTopupStatusResult> simulateSelcomPesaTopUp(
    SelcomPesaTopupRequest request,
  ) => _selcomPesaTopupRemoteDataSource.simulateTopUp(request);

  @override
  Future<SelcomPesaTopupStatusResult> checkSelcomPesaTopUpStatus({
    required String transid,
  }) => _selcomPesaTopupRemoteDataSource.checkTopUpStatus(transid: transid);
}
