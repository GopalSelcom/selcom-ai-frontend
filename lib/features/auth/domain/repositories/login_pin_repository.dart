import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/login_pin_models.dart';

/// Domain contract for app login PIN and biometric flag (not ride PIN).
///
/// Implemented by [LoginPinRepositoryImpl].
abstract class LoginPinRepository {
  Future<Either<Failure, LoginPinStatusModel>> getPinStatus();

  Future<Either<Failure, void>> setupPin(String pin);

  Future<Either<Failure, LoginPinVerifyResultModel>> verifyPin(String pin);

  Future<Either<Failure, void>> changePin({
    required String oldPin,
    required String newPin,
  });

  Future<Either<Failure, void>> deletePin();

  Future<Either<Failure, bool>> setBiometricEnabled(bool enabled);

  Future<bool> refreshSessionTokens();
}
