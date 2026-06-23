import '../entities/wallet_summary_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletSummaryUseCase {
  const GetWalletSummaryUseCase(this._repository);

  final WalletRepository _repository;

  Future<WalletSummaryEntity> call() => _repository.getWalletSummary();
}
