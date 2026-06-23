import '../entities/wallet_statement_email_result.dart';
import '../repositories/wallet_repository.dart';

class EmailWalletStatementUseCase {
  const EmailWalletStatementUseCase(this._repository);

  final WalletRepository _repository;

  Future<WalletStatementEmailResult> call({
    required String email,
    required String startDate,
    required String endDate,
    required String currency,
  }) {
    return _repository.emailWalletStatement(
      email: email,
      startDate: startDate,
      endDate: endDate,
      currency: currency,
    );
  }
}
