import '../../../../core/constants/params.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/entities/wallet_statement_email_result.dart';
import '../../../../core/data/models/user_model.dart';
import '../../../profile/data/models/profile_response_model.dart';
import '../models/go_card_balance_response.dart';
import '../models/go_card_statement_response.dart';
import '../models/go_email_card_statement_models.dart';

abstract class WalletRemoteDataSource {
  Future<GoCardBalanceResponseModel?> getCardBalance();

  Future<GoCardStatementResponseModel?> getCardStatement({
    required String startDate,
    required String endDate,
    String currency = 'TZS',
  });

  Future<WalletStatementEmailResult> emailCardStatement(
    EmailCardStatementRequest request,
  );

  Future<UserModel> getUserProfile();
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl();

  @override
  Future<GoCardBalanceResponseModel?> getCardBalance() async {
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
          return model;
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
  Future<GoCardStatementResponseModel?> getCardStatement({
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
            Params.startDate: startDate,
            Params.endDate: endDate,
            Params.currency: currency,
          },
          errorPresentationType: ErrorPresentationType.none,
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final model = GoCardStatementResponseModel.fromJson(response.data);
        if (model.statusCode==200) {
          return model;
        }
        return null;
      }

      if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
        return null;
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d(
        'getCardStatement error (suppressed): $e',
        tag: 'WalletRemoteDataSource',
      );
    }
    return null;
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

  @override
  Future<UserModel> getUserProfile() async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.profile.getProfile,
        method: ApiMethod.get,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final profileResponse = UserProfileResponseModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
      return profileResponse.data.toUserModel();
    }
    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      return const UserModel(id: '');
    }
    throw Exception('Failed to get profile');
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
