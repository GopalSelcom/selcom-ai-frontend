import 'package:intl/intl.dart';

import '../../core/constants/currency_code.dart';

class CurrencyFormatConfig {
  const CurrencyFormatConfig({
    required this.locale,
    required this.symbol,
    this.decimalDigits = 0,
  });

  final String locale;
  final String symbol;
  final int decimalDigits;
}

class CurrencyFormatter {
  const CurrencyFormatter._();

  /// Default when country / API currency is unknown (matches Duka [CommonValues.currencyCode]).
  static const CurrencyFormatConfig tanzania = CurrencyFormatConfig(
    locale: 'en_US',
    symbol: CurrencyCode.tzs,
    decimalDigits: 0,
  );

  static CurrencyFormatConfig? _regionDisplayConfig;

  /// ICU/`intl` locale data can associate the wrong currency with some `en_<ISO2>` locales
  /// (e.g. `en_TZ` resolves to USD). Override with ISO 4217 codes for those countries.
  /// Explicit ISO 4217 per phone country (Duka-style fixed codes; avoids bad ICU data).
  static const Map<String, String> _currencyIso4217ByCountry = {
    'TZ': CurrencyCode.tzs,
  };

  /// Resolves display currency from ISO 3166-1 alpha-2 using [intl], plus explicit overrides where ICU data is wrong.
  static CurrencyFormatConfig? tryConfigForIsoCountry(String? iso2) {
    final u = (iso2 ?? '').trim().toUpperCase();
    if (u.length != 2) return null;
    final fixed = _currencyIso4217ByCountry[u];
    if (fixed != null) {
      return CurrencyFormatConfig(
        locale: 'en_US',
        symbol: fixed,
        decimalDigits: 0,
      );
    }
    try {
      final nf = NumberFormat.simpleCurrency(locale: 'en_$u', decimalDigits: 0);
      final code = nf.currencyName;
      if (code == null || code.length != 3) return null;
      return CurrencyFormatConfig(
        locale: 'en_US',
        symbol: code.toUpperCase(),
        decimalDigits: 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// ISO 4217 code when intl can resolve `en_<ISO2>`; otherwise null.
  static String? tryCurrencyIso4217ForCountry(String? iso2) {
    final cfg = tryConfigForIsoCountry(iso2);
    return cfg?.symbol;
  }

  static CurrencyFormatConfig currencyDisplayConfigForIsoCountry(
    String? iso2,
  ) => tryConfigForIsoCountry(iso2) ?? tanzania;

  /// Called when the user picks a country on the phone screen (or on restore).
  static void setRegionDisplayConfig(CurrencyFormatConfig config) {
    _regionDisplayConfig = config;
  }

  static CurrencyFormatConfig _displayConfig() =>
      _regionDisplayConfig ?? tanzania;

  /// Prefix for amounts that are already formatted as numbers/strings (e.g. wallet balance).
  static String get displaySymbol => _displayConfig().symbol;

  /// Default formatter for app amounts (uses selected region currency).
  static String format(num amount) {
    return formatWithConfig(amount, _displayConfig());
  }

  /// Uses API / model currency when known; otherwise region display currency.
  static String formatWithApiCurrency(num amount, String? apiCurrencyCode) {
    final fromApi = _configForCode(apiCurrencyCode);
    return formatWithConfig(amount, fromApi ?? _displayConfig());
  }

  /// Maps API ISO 4217 codes (any) via [intl]; no hard-coded country list.
  static CurrencyFormatConfig? _configForCode(String? code) {
    final c = (code ?? '').trim().toUpperCase();
    if (c.length != 3) return null;
    try {
      final nf = NumberFormat.simpleCurrency(locale: 'en_US', name: c);
      return CurrencyFormatConfig(
        locale: 'en_US',
        symbol: c,
        decimalDigits: nf.maximumFractionDigits,
      );
    } catch (_) {
      return null;
    }
  }

  static String formatPayableOrFree(
    num amount,
    String? apiCurrencyCode, {
    required String freeLabel,
  }) {
    if (amount <= 0) return freeLabel;
    return formatWithApiCurrency(amount, apiCurrencyCode);
  }

  static String formatWithConfig(num amount, CurrencyFormatConfig config) {
    final formatter = NumberFormat.decimalPattern(config.locale)
      ..minimumFractionDigits = config.decimalDigits
      ..maximumFractionDigits = config.decimalDigits;
    final result = '${config.symbol} ${formatter.format(amount)}';
    if (result.endsWith('.00')) {
      return result.substring(0, result.length - 3);
    }
    return result;
  }
}
