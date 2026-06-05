import 'package:flutter/foundation.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../domain/repositories/active_wallet_repository.dart';
import '../models/activate_wallet_request.dart';
import '../../presentation/models/registration/client_success_model.dart';

class ActiveWalletRepositoryImpl implements ActiveWalletRepository {
  @override
  Future<ClientSuccessModel?> activateWallet(ActivateWalletRequest request) async {
    final body = request.toJson();

    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.createWallet,
          method: ApiMethod.post,
          body: body,
        ),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return ClientSuccessModel(statusCode: response.statusCode);
      }

      return ClientSuccessModel.fromJson(data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: 'ActiveWalletRepositoryImpl.activateWallet failed',
        extraData: [body],
      );
      debugPrint('activateWallet Exception: $e');
      return null;
    }
  }
}
