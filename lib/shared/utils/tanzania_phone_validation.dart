import 'phone_national_rules.dart';

/// Shared Tanzania (+255) validation for local UI input (no dial code in field).
abstract final class TanzaniaPhoneValidation {
  TanzaniaPhoneValidation._();

  static const String iso2 = 'TZ';

  /// National significant number digits (no `255`, no leading `0`).
  static String nationalDigitsFromDisplay(String raw) {
    final trimmed = raw.replaceAll(RegExp(r'\s'), '');
    if (trimmed.isEmpty) return '';
    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return '';
    if (digitsOnly.startsWith('255') && digitsOnly.length > 3) {
      return digitsOnly.substring(3);
    }
    if (digitsOnly.startsWith('0')) {
      return digitsOnly.length > 1 ? digitsOnly.substring(1) : '';
    }
    return digitsOnly;
  }

  /// Same completeness rule as auth ([PhoneNationalRules]) for ISO `TZ`.
  static bool isCompleteValid(String raw) {
    final nsn = nationalDigitsFromDisplay(raw);
    return PhoneNationalRules.isCompleteValidNational(iso2, nsn);
  }

  /// E.164 digits without `+`, e.g. `255712345678`, or `null` if invalid.
  static String? e164DigitsOrNull(String raw) {
    final nsn = nationalDigitsFromDisplay(raw);
    if (!PhoneNationalRules.isCompleteValidNational(iso2, nsn)) return null;
    return '255$nsn';
  }
}
