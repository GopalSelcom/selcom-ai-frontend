import '../../data/models/go_card_balance_response.dart';
import '../repositories/wallet_repository.dart';

class GetWalletSummaryUseCase {
  const GetWalletSummaryUseCase(this._repository);

  final WalletRepository _repository;

  Future<GoCardBalanceResponseModel?> call() => _repository.getCardBalance();
}
