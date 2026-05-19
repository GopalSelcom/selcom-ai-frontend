import 'failures.dart';

/// Domain failure for auth PIN APIs with server `error_code` and lock metadata.
///
/// Mapped in [LoginPinRepositoryImpl] from [LoginPinApiException].
/// UI handling: [LoginPinController._handlePinApiFailure].
class LoginPinFailure extends Failure {
  final String? errorCode;
  final int? attemptsRemaining;
  final DateTime? lockedUntil;

  const LoginPinFailure(
    super.message, {
    this.errorCode,
    this.attemptsRemaining,
    this.lockedUntil,
  });
}
