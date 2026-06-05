import '../../data/models/activate_wallet_request.dart';
import '../../presentation/models/registration/client_success_model.dart';

abstract class ActiveWalletRepository {
  Future<ClientSuccessModel?> activateWallet(ActivateWalletRequest request);
}
