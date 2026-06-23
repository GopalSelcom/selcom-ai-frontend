import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
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

  Future<void> cancelUssdOrder({required String transid});
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
  Future<void> cancelUssdOrder({required String transid}) async {
    final trimmedTransid = transid.trim();
    if (trimmedTransid.isEmpty) {
      throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.cancelUssdOrder,
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
}

class WalletPaymentException implements Exception {
  WalletPaymentException(this.message);

  final String message;

  @override
  String toString() => message;
}
