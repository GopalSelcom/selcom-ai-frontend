import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/entities/wallet_card_balance_entity.dart';
import '../../domain/entities/wallet_statement_email_result.dart';
import '../../domain/entities/wallet_transaction_entity.dart';
import '../models/go_card_balance_response.dart';
import '../models/go_card_statement_response.dart';
import '../models/go_email_card_statement_models.dart';

abstract class WalletRemoteDataSource {
  Future<WalletCardBalanceEntity?> getCardBalance();

  Future<List<WalletTransactionEntity>> getCardStatement({
    required String startDate,
    required String endDate,
    String currency = 'TZS',
  });

  Future<WalletStatementEmailResult> emailCardStatement(
    EmailCardStatementRequest request,
  );
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl();

  @override
  Future<WalletCardBalanceEntity?> getCardBalance() async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.cardBalance,
          method: ApiMethod.get,
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = GoCardBalanceResponseModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        if (model.isSuccess) {
          return model.response!.toEntity();
        }
        return null;
      }

      if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
        return null;
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d(
        'getCardBalance error (suppressed): $e',
        tag: 'WalletRemoteDataSource',
      );
    }
    return null;
  }

  @override
  Future<List<WalletTransactionEntity>> getCardStatement({
    required String startDate,
    required String endDate,
    String currency = 'TZS',
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.cardStatement,
          method: ApiMethod.get,
          queryParams: {
            'startdate': startDate,
            'enddate': endDate,
            'currency': currency,
          },
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = GoCardStatementResponseModel.fromJson(
          Map<String, dynamic>.from(response.data),
        );
        if (model.isSuccess) {
          return model.response!.toEntities();
        }
        return const [];
      }

      if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
        return const [];
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d(
        'getCardStatement error (suppressed): $e',
        tag: 'WalletRemoteDataSource',
      );
    }
    return const [];
  }

  @override
  Future<WalletStatementEmailResult> emailCardStatement(
    EmailCardStatementRequest request,
  ) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.wallet.emailCardStatement,
        method: ApiMethod.post,
        body: request.toJson(),
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final model = GoEmailCardStatementResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      if (model.isSuccess) {
        final message = model.message?.trim();
        return model.response!.toEntity(
          fallbackMessage: message?.isNotEmpty == true
              ? message!
              : AppStrings.walletStatementEmailedSuccess,
        );
      }
      throw WalletStatementEmailException(
        _messageFromResponse(response.data) ??
            AppStrings.walletStatementEmailFailed,
      );
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw WalletStatementEmailException(
        _messageFromResponse(response.data) ??
            AppStrings.walletStatementEmailFailed,
      );
    }

    throw WalletStatementEmailException(AppStrings.walletStatementEmailFailed);
  }

  String? _messageFromResponse(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message == null) return null;
    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class WalletStatementEmailException implements Exception {
  WalletStatementEmailException(this.message);

  final String message;
}
