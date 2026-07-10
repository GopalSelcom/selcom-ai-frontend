import 'package:selcom_rides_frontend/features/profile/data/models/sp_link_response.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/selcom_pesa_link_headers.dart';
import '../../../../core/network/urls.dart';
import '../../domain/entities/selcom_pesa_balance_entity.dart';
import '../../domain/entities/selcom_pesa_linked_account_entity.dart';
import '../models/selcom_pesa_link_models.dart';

abstract class SelcomPesaLinkRemoteDataSource {
  Future<SpLinkResponse> sendLinkRequest(
    SelcomPesaSendLinkRequest request,
  );

  Future<SelcomPesaLinkedAccountsResult> getLinkedAccounts({
    SelcomPesaLinkStatus? statusFilter,
  });

  Future<SpMainBalanceResponse> getMainBalance([
    SelcomPesaMainBalanceRequest? request,
  ]);

  Future<void> requestUnlink(SelcomPesaRequestUnlinkRequest request);

  Future<void> setDefaultAccount(SelcomPesaSetDefaultRequest request);
}

class SelcomPesaLinkException implements Exception {
  SelcomPesaLinkException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SelcomPesaLinkRemoteDataSourceImpl
    implements SelcomPesaLinkRemoteDataSource {
  SelcomPesaLinkRemoteDataSourceImpl();

  @override
  Future<SpLinkResponse> sendLinkRequest(
    SelcomPesaSendLinkRequest request,
  ) async {
    final linkHeaders = await selcomPesaLinkRequestHeaders();
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.selcomPesa.sendLinkRequest,
        method: ApiMethod.post,
        body: request.toJson(),
        headers: linkHeaders,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw SelcomPesaLinkException(
          _messageFromResponse(data) ??
              AppStrings.somethingWentWrongPleaseTryAgain,
        );
      }
      return SpLinkResponse.fromJson(data);
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw SelcomPesaLinkException(
        _messageFromResponse(response.data) ??
            AppStrings.somethingWentWrongPleaseTryAgain,
      );
    }

    throw SelcomPesaLinkException(AppStrings.somethingWentWrongPleaseTryAgain);
  }

  @override
  Future<SelcomPesaLinkedAccountsResult> getLinkedAccounts({
    SelcomPesaLinkStatus? statusFilter,
  }) async {
    final queryParams = <String, dynamic>{};
    if (statusFilter != null && statusFilter != SelcomPesaLinkStatus.unknown) {
      queryParams['status'] = statusFilter.name.toUpperCase();
    }

    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.selcomPesa.linkedAccounts,
        method: ApiMethod.get,
        queryParams: queryParams.isEmpty ? null : queryParams,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw SelcomPesaLinkException(
          _messageFromResponse(data) ??
              AppStrings.somethingWentWrongPleaseTryAgain,
        );
      }
      return SelcomPesaLinkedAccountsResult.fromJson(data);
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw SelcomPesaLinkException(
        _messageFromResponse(response.data) ??
            AppStrings.somethingWentWrongPleaseTryAgain,
      );
    }

    throw SelcomPesaLinkException(AppStrings.somethingWentWrongPleaseTryAgain);
  }

  @override
  Future<void> requestUnlink(SelcomPesaRequestUnlinkRequest request) async {
    final linkHeaders = await selcomPesaLinkRequestHeaders();
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.selcomPesa.requestUnlink,
        method: ApiMethod.post,
        body: request.toJson(),
        headers: linkHeaders,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw SelcomPesaLinkException(
          _messageFromResponse(data) ??
              AppStrings.somethingWentWrongPleaseTryAgain,
        );
      }
      return;
    }
    if(response.statusCode==400){
      throw SelcomPesaLinkException(
        _messageFromResponse(response.data) ??
            AppStrings.somethingWentWrongPleaseTryAgain,
      );
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw SelcomPesaLinkException(
        _messageFromResponse(response.data) ??
            AppStrings.somethingWentWrongPleaseTryAgain,
      );
    }

    throw SelcomPesaLinkException(AppStrings.somethingWentWrongPleaseTryAgain);
  }

  @override
  Future<void> setDefaultAccount(SelcomPesaSetDefaultRequest request) async {
    final linkHeaders = await selcomPesaLinkRequestHeaders();
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.selcomPesa.setDefaultAccount,
        method: ApiMethod.post,
        body: request.toJson(),
        headers: linkHeaders,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw SelcomPesaLinkException(
          _messageFromResponse(data) ??
              AppStrings.somethingWentWrongPleaseTryAgain,
        );
      }
      return;
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw SelcomPesaLinkException(
        _messageFromResponse(response.data) ??
            AppStrings.somethingWentWrongPleaseTryAgain,
      );
    }

    throw SelcomPesaLinkException(AppStrings.somethingWentWrongPleaseTryAgain);
  }

  @override
  Future<SpMainBalanceResponse> getMainBalance([
    SelcomPesaMainBalanceRequest? request,
  ]) async {
    final body = request?.toJson() ?? const <String, dynamic>{};
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.selcomPesa.mainBalance,
        method: ApiMethod.post,
        body: body.isEmpty ? null : body,
        errorPresentationType: ErrorPresentationType.none,
      ),
    );

    if (response.statusCode == 404) {
      throw SelcomPesaLinkException(
        _messageFromResponse(response.data) ??
            AppStrings.selcomPesaStatusNotFound,
      );
    }

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(response.data as Map);
      final statusCode = data['status_code'];
      if (statusCode is int && statusCode != 200) {
        throw SelcomPesaLinkException(
          _messageFromResponse(data) ??
              AppStrings.somethingWentWrongPleaseTryAgain,
        );
      }
      return SpMainBalanceResponse.fromJson(data);
    }

    if (isExpectedClientBusinessHttpStatus(response.statusCode)) {
      throw SelcomPesaLinkException(
        _messageFromResponse(response.data) ??
            AppStrings.somethingWentWrongPleaseTryAgain,
      );
    }

    throw SelcomPesaLinkException(AppStrings.somethingWentWrongPleaseTryAgain);
  }

  String? _messageFromResponse(dynamic data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message == null) return null;
    final text = message.toString().trim();
    return text.isEmpty ? null : text;
  }
}
