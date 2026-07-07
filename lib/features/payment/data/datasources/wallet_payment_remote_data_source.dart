import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../wallet/data/models/go_wallet_card_model.dart';
import '../../../wallet/data/models/go_add_card_response_model.dart';
import '../models/go_other_payment_methods_models.dart';

abstract class WalletPaymentRemoteDataSource {
  Future<TanQrPaymentSession> initiateOtherPayment(
    GoOtherPaymentMethodsRequest request, {
    required bool requireQr,
  });

  Future<TanQrPaymentSession> initiateTanQrTopUp(
    GoOtherPaymentMethodsRequest request,
  ) =>
      initiateOtherPayment(request, requireQr: true);

  Future<TanQrPaymentSession> initiateMobileMoneyTopUp(
    GoOtherPaymentMethodsRequest request,
  ) =>
      initiateOtherPayment(request, requireQr: false);

  Future<PaymentStatusResult> checkPaymentStatus({
    required String transid,
  });

  Future<void> cancelUssdOrder({
    required String transid,
    required String paymentMethod,
  });

  Future<List<GoWalletCardModel>> fetchCards();

  Future<GoAddCardResponseModel> goAddCardNew({
    required int amount,
    required int newCard,
  });

  Future<void> goPayByExistingCard({
    required String transId,
    required String cardToken,
  });
}

class WalletPaymentRemoteDataSourceImpl
    implements WalletPaymentRemoteDataSource {
  WalletPaymentRemoteDataSourceImpl();

  @override
  Future<TanQrPaymentSession> initiateOtherPayment(
    GoOtherPaymentMethodsRequest request, {
    required bool requireQr,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.walletTopUp,
        method: ApiMethod.post,
        body: request.toJson(),
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final session = _parsePaymentSession(
          data,
          requireQr: requireQr,
        );
        if (session != null) {
          return session;
        }
      }
      throw WalletPaymentException(
        _messageFromResponse(response.data) ??
            AppStrings.tanQrPaymentRequestFailed,
      );
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw WalletPaymentException(
        _messageFromResponse(response.data) ??
            AppStrings.tanQrPaymentRequestFailed,
      );
    }

    throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
  }

  @override
  Future<TanQrPaymentSession> initiateTanQrTopUp(
    GoOtherPaymentMethodsRequest request,
  ) =>
      initiateOtherPayment(request, requireQr: true);

  @override
  Future<TanQrPaymentSession> initiateMobileMoneyTopUp(
    GoOtherPaymentMethodsRequest request,
  ) =>
      initiateOtherPayment(request, requireQr: false);

  @override
  Future<PaymentStatusResult> checkPaymentStatus({
    required String transid,
  }) async {
    final trimmedTransid = transid.trim();
    if (trimmedTransid.isEmpty) {
      throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.checkWalletPaymentTopUpStatus,
        method: ApiMethod.post,
        body: {'transid': trimmedTransid},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final status = data['status'] ?? data['status_code'];
        if (status is int && status != 200) {
          throw WalletPaymentException(
            _messageFromResponse(data) ??
                AppStrings.tanQrPaymentRequestFailed,
          );
        }
        return PaymentStatusResult.fromJson(data);
      }
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw WalletPaymentException(
        _messageFromResponse(response.data) ??
            AppStrings.tanQrPaymentRequestFailed,
      );
    }

    throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
  }

  @override
  Future<void> cancelUssdOrder({
    required String transid,
    required String paymentMethod,
  }) async {
    final trimmedTransid = transid.trim();
    final trimmedPaymentMethod = paymentMethod.trim();
    if (trimmedTransid.isEmpty || trimmedPaymentMethod.isEmpty) {
      throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.cancelUssdOrder,
        method: ApiMethod.post,
        body: {
          'transid': trimmedTransid,
          'payment_method': trimmedPaymentMethod,
        },
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final status = data['status'] ?? data['status_code'];
        if (status is int && status != 200) {
          throw WalletPaymentException(
            _messageFromResponse(data) ??
                AppStrings.tanQrPaymentRequestFailed,
          );
        }
        return;
      }
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw WalletPaymentException(
        _messageFromResponse(response.data) ??
            AppStrings.tanQrPaymentRequestFailed,
      );
    }

    throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
  }

  String? _messageFromResponse(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is List) {
      for (final item in errors) {
        if (item is! Map) continue;
        final errorMessage = item['message']?.toString().trim();
        if (errorMessage != null && errorMessage.isNotEmpty) {
          return errorMessage;
        }
      }
    }
    final message = data['message'];
    if (message == null) return null;
    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }

  TanQrPaymentSession? _parsePaymentSession(
    Map<String, dynamic> data, {
    required bool requireQr,
  }) {
    final bodyStatusCode = data['status_code'];
    if (bodyStatusCode is int && bodyStatusCode != 200) {
      return null;
    }

    bool isValid(TanQrPaymentSession session) {
      if (requireQr) return session.qr.trim().isNotEmpty;
      return session.transid.trim().isNotEmpty;
    }

    final payload = data['response'];
    if (payload is Map<String, dynamic>) {
      final result = payload['result']?.toString().toUpperCase();
      if (result != null && result != 'SUCCESS') {
        return null;
      }
      final session = TanQrPaymentSession.fromJson(payload);
      if (isValid(session)) {
        return session;
      }
    }

    final list = data['data'];
    if (list is List && list.isNotEmpty) {
      final first = list.first;
      if (first is Map<String, dynamic>) {
        final session = TanQrPaymentSession.fromJson(first);
        if (isValid(session)) {
          return session;
        }
      }
    }

    final direct = TanQrPaymentSession.fromJson(data);
    if (isValid(direct)) {
      return direct;
    }

    return null;
  }

  @override
  Future<List<GoWalletCardModel>> fetchCards() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.fetchCards,
        method: ApiMethod.get,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final resultcode = data['resultcode']?.toString();
        if (resultcode == '404') {
          return [];
        }
        final list = data['data'];
        if (list is List) {
          return list
              .map((e) => GoWalletCardModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return [];
    }

    throw WalletPaymentException(
      _messageFromResponse(response.data) ?? 'Failed to fetch cards',
    );
  }

  @override
  Future<GoAddCardResponseModel> goAddCardNew({
    required int amount,
    required int newCard,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.goAddCardNew,
        method: ApiMethod.post,
        body: {
          'amount': amount,
          'newCard': newCard,
        },
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final statusCode = data['status_code'] ?? data['status'];
        if (statusCode == 200) {
          return GoAddCardResponseModel.fromJson(data);
        }
        throw WalletPaymentException(
          data['errorMsg']?.toString() ??
              data['message']?.toString() ??
              'Failed to start card transaction',
        );
      }
    }

    throw WalletPaymentException(
      _messageFromResponse(response.data) ?? 'Failed to start card transaction',
    );
  }

  @override
  Future<void> goPayByExistingCard({
    required String transId,
    required String cardToken,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.goPayByExistingCard,
        method: ApiMethod.post,
        body: {
          'transid': transId,
          'card_token': cardToken,
        },
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final statusCode = data['status_code'] ?? data['status'];
        if (statusCode == 200) {
          return;
        }
        final message = data['message']?.toString() ?? 'Debit failed';
        throw WalletPaymentException(message);
      }
    }

    throw WalletPaymentException(
      _messageFromResponse(response.data) ?? 'Debit failed',
    );
  }
}

class WalletPaymentException implements Exception {
  WalletPaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}
