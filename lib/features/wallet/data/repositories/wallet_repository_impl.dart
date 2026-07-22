import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../payment/data/datasources/selcom_pesa_topup_remote_data_source.dart';
import '../../../payment/data/datasources/wallet_payment_remote_data_source.dart';
import '../../../payment/data/models/go_other_payment_methods_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_models.dart';
import '../../../payment/data/models/selcom_pesa_topup_status_models.dart';
import '../models/go_card_balance_response.dart';
import '../../domain/entities/wallet_page_data.dart';
import '../../domain/entities/wallet_statement_email_result.dart';
import '../../domain/entities/wallet_transaction_filter.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/utils/wallet_statement_utils.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../models/go_card_statement_response.dart';
import '../models/go_email_card_statement_models.dart';
import '../models/go_wallet_card_model.dart';
import '../models/go_add_card_response_model.dart';
import '../models/go_init_card_session_response_model.dart' hide Datum;
import '../models/model_status_msg.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({
    required WalletRemoteDataSource remoteDataSource,
    required WalletPaymentRemoteDataSource paymentRemoteDataSource,
    required SelcomPesaTopupRemoteDataSource selcomPesaTopupRemoteDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _paymentRemoteDataSource = paymentRemoteDataSource,
       _selcomPesaTopupRemoteDataSource = selcomPesaTopupRemoteDataSource;

  final WalletRemoteDataSource _remoteDataSource;
  List<TransactionDatum>? _statementCache;
  final WalletPaymentRemoteDataSource _paymentRemoteDataSource;
  final SelcomPesaTopupRemoteDataSource _selcomPesaTopupRemoteDataSource;

  @override
  Future<GoCardBalanceResponseModel?> getCardBalance() =>
      _remoteDataSource.getCardBalance();

  @override
  Future<WalletPageData> getWalletPageData({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
  }) async {
    // Single card-balance fetch for wallet screen first paint (summary + statement).
    invalidateStatementCache();
    final balance = await _remoteDataSource.getCardBalance();
    final all = await _loadStatementTransactions(balance: balance);
    final transactions = switch (filter) {
      WalletTransactionFilter.all => all,
      WalletTransactionFilter.received =>
        all.where(_isDatumCredit).toList(growable: false),
      WalletTransactionFilter.sent =>
        all.where((datum) => !_isDatumCredit(datum)).toList(growable: false),
    };

    return WalletPageData(
      cardBalance: balance,
      transactions: List.unmodifiable(transactions),
    );
  }

  @override
  Future<List<TransactionDatum>> getTransactions({
    WalletTransactionFilter filter = WalletTransactionFilter.all,
    String? currencyOverride,
  }) async {
    final all = await _loadStatementTransactions(
      currencyOverride: currencyOverride,
    );
    final filtered = switch (filter) {
      WalletTransactionFilter.all => all,
      WalletTransactionFilter.received =>
        all.where(_isDatumCredit).toList(growable: false),
      WalletTransactionFilter.sent =>
        all.where((datum) => !_isDatumCredit(datum)).toList(growable: false),
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

  Future<List<TransactionDatum>> _loadStatementTransactions({
    GoCardBalanceResponseModel? balance,
    String? currencyOverride,
  }) async {
    if (_statementCache != null) {
      return _statementCache!;
    }

    final (startDate, endDate) = defaultWalletStatementDateRange();
    // Never call go_card_balance just to resolve currency for statements.
    // Callers that already fetched balance pass it; otherwise use override/default.
    final currency = currencyOverride?.trim().isNotEmpty == true
        ? currencyOverride!.trim()
        : balance?.currency.trim().isNotEmpty == true
            ? balance!.currency
            : 'TZS';
    final transactions = await _remoteDataSource.getCardStatement(
      startDate: startDate,
      endDate: endDate,
      currency: currency,
    );

    final sorted = List<TransactionDatum>.from(transactions?.response?.data ?? [])
      ..sort((a, b) => _parseTimestamp(b.fulltimestamp).compareTo(_parseTimestamp(a.fulltimestamp)));

    _statementCache = List.unmodifiable(sorted);
    return _statementCache!;
  }

  bool _isDatumCredit(TransactionDatum datum) {
    final type = (datum.transtype ?? '').trim().toUpperCase();
    return type == 'CREDIT' || type == 'CREDITED' || type == 'RELEASE';
  }

  DateTime _parseTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    final trimmed = timestamp.trim();
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) return direct;
    return DateTime.tryParse(trimmed.replaceFirst(' ', 'T')) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Future<WalletTopUpSession> initiateMobileMoneyTopUp(
    GoOtherPaymentMethodsRequest request,
  ) => _paymentRemoteDataSource.initiateMobileMoneyTopUp(request);

  @override
  Future<PaymentStatusResult> checkPaymentStatus({required String transid}) =>
      _paymentRemoteDataSource.checkPaymentStatus(transid: transid);

  @override
  Future<void> cancelUssdOrder({
    required String transid,
    required String paymentMethod,
  }) => _paymentRemoteDataSource.cancelUssdOrder(
    transid: transid,
    paymentMethod: paymentMethod,
  );

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

  @override
  Future<Either<Failure, List<Datum>>> fetchCards() async {
    try {
      final result = await _paymentRemoteDataSource.fetchCards();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GoAddCardResponseModel>> goAddCardNew({
    required int amount,
    required int newCard,
  }) async {
    try {
      final result = await _paymentRemoteDataSource.goAddCardNew(
        amount: amount,
        newCard: newCard,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> goPayByExistingCard({
    required String transId,
    required String cardToken,
  }) async {
    try {
      await _paymentRemoteDataSource.goPayByExistingCard(
        transId: transId,
        cardToken: cardToken,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final result = await _paymentRemoteDataSource.goInitCardSession(
        amount: amount,
        newCard: newCard,
        email: email,
        mobileNumber: mobileNumber,
        countryCode: countryCode,
        cardBin: cardBin,
        fname: fname,
        lname: lname,
        address: address,
        city: city,
        state: state,
        country: country,
        postalcode: postalcode,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ModelStatusMsg>> deleteCard({required int id}) async {
    try {
      final result = await _paymentRemoteDataSource.deleteCard(id: id);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
