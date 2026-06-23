import '../data/countries_phone_data.dart';
import 'grouped_phone_number_formatter.dart';

/// Parses contact phone strings that may or may not include a country dial code.
abstract final class PhoneContactImport {
  PhoneContactImport._();

  /// [country] is set only when the contact value has an explicit `+` or `00` prefix.
  static ({CountryData? country, String formattedNational}) parse(
    String rawPhone,
  ) {
    final compact = rawPhone.replaceAll(RegExp(r'[\s\-().]'), '');
    final hasExplicitIntlPrefix =
        rawPhone.trim().startsWith('+') ||
        compact.startsWith('00');

    var digits = compact;
    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('00') && digits.length > 2) {
      digits = digits.substring(2);
    }

    if (hasExplicitIntlPrefix) {
      final byDialLength = [...Countries.all]
        ..sort((a, b) {
          final al = a.dialCode.replaceAll('+', '').length;
          final bl = b.dialCode.replaceAll('+', '').length;
          return bl.compareTo(al);
        });

      for (final country in byDialLength) {
        final dial = country.dialCode.replaceAll('+', '');
        if (digits.startsWith(dial) && digits.length > dial.length) {
          var nsn = digits.substring(dial.length);
          if (nsn.startsWith('0') && nsn.length > 1) {
            nsn = nsn.substring(1);
          }
          return (
            country: country,
            formattedNational: GroupedPhoneNumberFormatter.formatDigits(
              nsn,
              country.format,
            ),
          );
        }
      }
    }

    var nsn = compact.replaceAll(RegExp(r'\D'), '');
    if (nsn.startsWith('0') && nsn.length > 1) {
      nsn = nsn.substring(1);
    }

    return (country: null, formattedNational: nsn);
  }
}
