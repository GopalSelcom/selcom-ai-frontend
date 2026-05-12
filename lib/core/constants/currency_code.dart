/// Default currency and country constants aligned with Duka Direct
/// `lib/core/constants/constans.dart` (`CommonValues`, `CurrencyCode`).
///
/// Duka fixes `CommonValues.currencyCode` to **TZS** app-wide (no `intl` derivation).
/// This app keeps the same defaults; live UI after phone-country selection uses
/// `CurrencyFormatter.displaySymbol` / `CountryRegionDefaults.currencyCodeForIso2`.
library currency_code;

class CurrencyCode {
  CurrencyCode._();

  /// Tanzanian shilling (ISO 4217). Same value as Duka `CurrencyCode.TZS`.
  static const String tzs = 'TZS';
}

/// Same defaults as Duka `CommonValues` (primary market TZ / TZS).
class CommonValues {
  CommonValues._();

  static const String currencyCode = CurrencyCode.tzs;

  /// Default ISO country when none stored (Duka: `CommonValues.countryCode`).
  static const String countryCode = 'TZ';
}
