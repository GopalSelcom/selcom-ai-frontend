/// Client-side format check only (AUTH-PIN-BIOMETRIC rule 1).
///
/// Weak-PIN rejection is server-side (`AUTH_PIN_TOO_WEAK`).
/// Used by [LoginPinController.onPinCompleted].
class LoginPinValidator {
  LoginPinValidator._();

  static final RegExp _fourDigits = RegExp(r'^\d{4}$');

  static bool isValidFormat(String pin) => _fourDigits.hasMatch(pin);
}
