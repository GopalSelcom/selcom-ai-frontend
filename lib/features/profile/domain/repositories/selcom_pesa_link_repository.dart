import '../entities/selcom_pesa_balance_entity.dart';
import '../entities/selcom_pesa_linked_account_entity.dart';

abstract class SelcomPesaLinkRepository {
  Future<SelcomPesaLinkedAccountEntity> sendLinkRequest({
    required String countryCode,
    required String mobileNumber,
  });

  Future<List<SelcomPesaLinkedAccountEntity>> getLinkedAccounts({
    SelcomPesaLinkStatus? statusFilter,
  });

  Future<SelcomPesaBalanceEntity> getMainBalance({
    required String mobileNumber,
    required String countryCode,
  });
}
