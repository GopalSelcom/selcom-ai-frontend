import '../../../../shared/utils/selcom_pesa_phone_utils.dart';
import '../../../payment/domain/wallet_payment_phone_country.dart';
import '../../data/datasources/selcom_pesa_link_remote_data_source.dart';
import '../../data/models/selcom_pesa_link_models.dart';
import '../../domain/entities/selcom_pesa_balance_entity.dart';
import '../../domain/entities/selcom_pesa_linked_account_entity.dart';
import '../../domain/repositories/selcom_pesa_link_repository.dart';

class SelcomPesaLinkRepositoryImpl implements SelcomPesaLinkRepository {
  SelcomPesaLinkRepositoryImpl({
    required SelcomPesaLinkRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final SelcomPesaLinkRemoteDataSource _remoteDataSource;

  @override
  Future<SelcomPesaLinkedAccountEntity> sendLinkRequest({
    required String countryCode,
    required String mobileNumber,
  }) {
    return _remoteDataSource.sendLinkRequest(
      SelcomPesaSendLinkRequest(
        spCountryCode: countryCode,
        spMobileNumber: normalizeTzMobileForSelcomPesa(mobileNumber),
      ),
    );
  }

  @override
  Future<List<SelcomPesaLinkedAccountEntity>> getLinkedAccounts({
    SelcomPesaLinkStatus? statusFilter,
  }) async {
    final result = await _remoteDataSource.getLinkedAccounts(
      statusFilter: statusFilter,
    );
    return result.accounts;
  }

  @override
  Future<void> requestUnlink({required String mobileNumber}) {
    return _remoteDataSource.requestUnlink(
      SelcomPesaRequestUnlinkRequest(
        spMobileNumber: normalizeTzMobileForSelcomPesa(mobileNumber),
      ),
    );
  }

  @override
  Future<SelcomPesaBalanceEntity> getMainBalance({
    required String mobileNumber,
    required String countryCode,
  }) async {
    final request = SelcomPesaMainBalanceRequest(
      mobileNumber: normalizeTzMobileForSelcomPesa(mobileNumber),
      countryCode: countryCode.trim().isNotEmpty
          ? countryCode.trim()
          : WalletPaymentPhoneCountry.dialCodeDigits,
    );
    final result = await _remoteDataSource.getMainBalance(request);
    return SelcomPesaBalanceEntity(
      balance: result.balance,
      currency: result.currency,
    );
  }
}
