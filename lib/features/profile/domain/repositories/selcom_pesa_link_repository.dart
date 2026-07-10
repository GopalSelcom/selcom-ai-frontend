import '../../data/models/selcom_pesa_link_models.dart';
import '../../data/models/sp_link_response.dart';
import '../entities/selcom_pesa_balance_entity.dart';
import '../entities/selcom_pesa_linked_account_entity.dart';

abstract class SelcomPesaLinkRepository {
  Future<SpLinkResponse> sendLinkRequest({
    required String countryCode,
    required String mobileNumber,
  });

  Future<SelcomPesaLinkedAccountsResult> getLinkedAccounts({
    SelcomPesaLinkStatus? statusFilter,
  });

  Future<SpMainBalanceResponse> getMainBalance({
    required String mobileNumber,
    required String countryCode,
  });

  Future<void> requestUnlink({required String mobileNumber});

  Future<void> setDefaultAccount({required String mobileNumber});
}
