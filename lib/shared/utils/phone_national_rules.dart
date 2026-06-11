import 'package:flutter/services.dart';

import '../data/countries_phone_data.dart';
import 'grouped_phone_number_formatter.dart';

/// Phone rules aligned with `duka_direct_4_flutter`: [Countries] + [GroupedPhoneNumberFormatter].
class PhoneNationalRules {
  PhoneNationalRules._();

  static int maxNationalDigits(String? iso2) =>
      Countries.findByIsoCode(iso2).maxLength;

  static bool isCompleteValidNational(String? iso2, String digitsOnly) {
    final c = Countries.findByIsoCode(iso2);
    final len = digitsOnly.length;
    return len >= c.minLength && len <= c.maxLength;
  }

  /// Same order as Duka auth [TextFieldWidget]: digits only → cap → group with spaces.
  static List<TextInputFormatter> inputFormattersForIso(String? iso2) {
    final c = Countries.findByIsoCode(iso2);
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(c.maxLength),
      GroupedPhoneNumberFormatter(format: c.format),
    ];
  }

  /// Display cap: NSN digits + spaces between groups ([format.length - 1]).
  static int maxDisplayCharactersForIso(String? iso2) {
    final c = Countries.findByIsoCode(iso2);
    final spaces = c.format.length > 1 ? c.format.length - 1 : 0;
    return c.maxLength + spaces;
  }

  /// E.164 digits without `+`, e.g. `255712345678`, or `null` if invalid.
  static String? e164DigitsOrNull(String? iso2, String rawDisplay) {
    final nsn = rawDisplay.replaceAll(RegExp(r'\D'), '');
    if (!isCompleteValidNational(iso2, nsn)) return null;
    final dial = findByIso(iso2).dialCode.replaceAll('+', '');
    return '$dial$nsn';
  }

  static CountryData findByIso(String? iso2) => Countries.findByIsoCode(iso2);

  /// Hint matches visible grouping (digits shown as `x`).
  static String hintForIso(String? iso2) {
    final c = Countries.findByIsoCode(iso2);
    final synthetic = List.filled(c.maxLength, '9').join();
    final formatted = GroupedPhoneNumberFormatter.formatDigits(
      synthetic,
      c.format,
    );
    return formatted.replaceAll(RegExp(r'[0-9]'), 'x');
  }

  /// Formats [mobileNumber] for display using API [countryCode] (`255`, `+255`, etc.).
  static String formatMobileForDisplay({
    String? countryCode,
    int? mobileNumber,
  }) {
    if (mobileNumber == null || mobileNumber == 0) return '';

    final country = Countries.findByDialCode(countryCode ?? '');
    final dialDigits = country.dialCode.replaceAll('+', '');
    var digits = mobileNumber.toString().replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith(dialDigits) && digits.length > country.maxLength) {
      digits = digits.substring(dialDigits.length);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    final grouped = GroupedPhoneNumberFormatter.formatDigits(
      digits,
      country.format,
    );
    return '${country.dialCode} $grouped';
  }
}
