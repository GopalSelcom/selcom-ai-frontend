import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/login_pin_models.dart';
import '../repositories/login_pin_repository.dart';

// Thin use cases for login PIN — one class per repository operation.
// Wired in [LoginPinBinding], [SettingsBinding], [AuthController] (delete PIN).

/// Reads server PIN/biometric state for gate, settings, and lock UI.
class GetLoginPinStatusUseCase {
  GetLoginPinStatusUseCase(this._repository);

  final LoginPinRepository _repository;

  Future<Either<Failure, LoginPinStatusModel>> call() =>
      _repository.getPinStatus();
}

/// `POST pin/setup` after OTP when user completes enter + confirm.
class SetupLoginPinUseCase {
  SetupLoginPinUseCase(this._repository);

  final LoginPinRepository _repository;

  Future<Either<Failure, void>> call(String pin) => _repository.setupPin(pin);
}

/// `POST pin/verify` on returning-user login screen.
class VerifyLoginPinUseCase {
  VerifyLoginPinUseCase(this._repository);

  final LoginPinRepository _repository;

  Future<Either<Failure, LoginPinVerifyResultModel>> call(String pin) =>
      _repository.verifyPin(pin);
}

/// `POST pin/change` from settings change-PIN flow.
class ChangeLoginPinUseCase {
  ChangeLoginPinUseCase(this._repository);

  final LoginPinRepository _repository;

  Future<Either<Failure, void>> call({
    required String oldPin,
    required String newPin,
  }) => _repository.changePin(oldPin: oldPin, newPin: newPin);
}

/// `DELETE pin` during forgot-PIN re-auth (before forced setup).
class DeleteLoginPinUseCase {
  DeleteLoginPinUseCase(this._repository);

  final LoginPinRepository _repository;

  Future<Either<Failure, void>> call() => _repository.deletePin();
}

/// `POST /auth/biometric` from settings toggle (after local biometric auth).
class SetLoginBiometricUseCase {
  SetLoginBiometricUseCase(this._repository);

  final LoginPinRepository _repository;

  Future<Either<Failure, bool>> call(bool enabled) =>
      _repository.setBiometricEnabled(enabled);
}

/// Refreshes tokens after successful biometric unlock on cold start.
class RefreshLoginSessionUseCase {
  RefreshLoginSessionUseCase(this._repository);

  final LoginPinRepository _repository;

  Future<bool> call() => _repository.refreshSessionTokens();
}
