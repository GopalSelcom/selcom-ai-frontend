import '../../core/constants/currency_code.dart';
import 'currency_formatter.dart';

/// Currency display / API codes from selected ISO country only (phone rules live in [PhoneNationalRules] + [Countries]).
/// Defaults match Duka [CommonValues.currencyCode] when resolution fails.
class CountryRegionDefaults {
  CountryRegionDefaults._();

  static CurrencyFormatConfig currencyConfigForIso(String? iso2) =>
      CurrencyFormatter.currencyDisplayConfigForIsoCountry(iso2);

  /// ISO 4217 when resolvable; else [CurrencyCode.tzs] (same default as Duka).
  static String currencyCodeForIso2(String? iso2) =>
      CurrencyFormatter.tryCurrencyIso4217ForCountry(iso2) ?? CurrencyCode.tzs;
}
