import '../entities/wallet_details_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletDetailsUseCase {
  const GetWalletDetailsUseCase(this._repository);

  final WalletRepository _repository;

  Future<WalletDetailsEntity?> call() => _repository.getWalletDetails();
}
