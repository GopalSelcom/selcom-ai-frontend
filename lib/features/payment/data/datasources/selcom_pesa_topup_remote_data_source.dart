import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../models/selcom_pesa_topup_models.dart';
import '../models/selcom_pesa_topup_status_models.dart';
import 'wallet_payment_remote_data_source.dart';

abstract class SelcomPesaTopupRemoteDataSource {
  Future<SelcomPesaTopupResult> sendTransferRequest(
    SelcomPesaTopupRequest request, {
    required bool requireShortCode,
  });

  Future<SelcomPesaTopupStatusResult> simulateTopUp(
    SelcomPesaTopupRequest request,
  );

  Future<SelcomPesaTopupStatusResult> checkTopUpStatus({
    required String transid,
  });
}

class SelcomPesaTopupRemoteDataSourceImpl
    implements SelcomPesaTopupRemoteDataSource {
  SelcomPesaTopupRemoteDataSourceImpl();

  @override
  Future<SelcomPesaTopupResult> sendTransferRequest(
    SelcomPesaTopupRequest request, {
    required bool requireShortCode,
  }) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.sendTransferRequestSelcomPesa,
        method: ApiMethod.post,
        body: request.toJson(),
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw WalletPaymentException(
          _messageFromResponse(data) ?? AppStrings.tanQrPaymentRequestFailed,
        );
      }

      final result = SelcomPesaTopupResult.fromJson(data);
      if (result.transid.trim().isEmpty) {
        throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
      }

      if (requireShortCode && result.shortCode.trim().isEmpty) {
        throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
      }

      return result;
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
  Future<SelcomPesaTopupStatusResult> simulateTopUp(
    SelcomPesaTopupRequest request,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.simulateSelcomPesaTopUp,
        method: ApiMethod.post,
        body: request.toJson(),
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw WalletPaymentException(
          _messageFromResponse(data) ?? AppStrings.tanQrPaymentRequestFailed,
        );
      }
      final result = SelcomPesaTopupStatusResult.fromEnvelope(data);
      if (!result.isPaid) {
        throw WalletPaymentException(
          result.message.trim().isNotEmpty
              ? result.message.trim()
              : AppStrings.selcomPesaPaymentProcessing,
        );
      }
      return result;
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
  Future<SelcomPesaTopupStatusResult> checkTopUpStatus({
    required String transid,
  }) async {
    final trimmedTransid = transid.trim();
    if (trimmedTransid.isEmpty) {
      throw WalletPaymentException(AppStrings.tanQrPaymentRequestFailed);
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.checkSelcomPesaTopUpStatus,
        method: ApiMethod.post,
        body: {'transid': trimmedTransid},
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 404) {
      throw WalletPaymentException(AppStrings.selcomPesaStatusNotFound);
    }

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw WalletPaymentException(
          _messageFromResponse(data) ?? AppStrings.tanQrPaymentRequestFailed,
        );
      }
      return SelcomPesaTopupStatusResult.fromEnvelope(data);
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      if (response.statusCode == 404) {
        throw WalletPaymentException(AppStrings.selcomPesaStatusNotFound);
      }
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
}
