import 'package:intl/intl.dart';

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

  static const CurrencyFormatConfig tanzania = CurrencyFormatConfig(
    locale: 'en_US',
    symbol: 'TZS',
    decimalDigits: 0,
  );

  /// Default formatter for app amounts.
  /// Always returns Tanzania-style grouped output, e.g.:
  /// 1000 -> TZS 1,000
  /// 1251250 -> TZS 1,251,250
  static String format(num amount) {
    final formatter = NumberFormat('#,##0', tanzania.locale);
    return '${tanzania.symbol} ${formatter.format(amount)}';
  }

  /// Optional generic formatter kept for future country expansion.
  static String formatWithConfig(num amount, CurrencyFormatConfig config) {
    final formatter = NumberFormat.decimalPattern(config.locale)
      ..minimumFractionDigits = config.decimalDigits
      ..maximumFractionDigits = config.decimalDigits;
    return '${config.symbol} ${formatter.format(amount)}';
  }
}
