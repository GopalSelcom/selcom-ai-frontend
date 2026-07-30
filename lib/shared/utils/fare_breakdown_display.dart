import '../../core/data/models/fare_breakdown_line_item.dart';
import 'currency_formatter.dart';

/// Formatted row for in-app fare cards (title + currency label).
class FareBreakdownDisplayRow {
  final String title;
  final String amountLabel;
  final String? key;
  final bool isTotal;
  final bool isNegative;

  const FareBreakdownDisplayRow({
    required this.title,
    required this.amountLabel,
    this.key,
    this.isTotal = false,
    this.isNegative = false,
  });
}

/// Unformatted line for receipt PNG/PDF.
class FareBreakdownComponentLine {
  final String title;
  final int amount;
  final String? key;
  final bool isTotal;

  const FareBreakdownComponentLine({
    required this.title,
    required this.amount,
    this.key,
    this.isTotal = false,
  });
}

/// Total Fare card rows from API `fare_breakdown.line_items` only.
///
/// Map in order — no client ride_charge / booking_fee / promo arithmetic.
abstract final class FareBreakdownDisplay {
  FareBreakdownDisplay._();

  static bool hasLineItems(List<FareBreakdownLineItem>? lineItems) =>
      lineItems != null && lineItems.isNotEmpty;

  /// In-app fare card rows.
  static List<FareBreakdownDisplayRow> rowsFromLineItems(
    List<FareBreakdownLineItem> lineItems, {
    String? apiCurrency,
  }) {
    return lineItems.map((item) {
      final label = apiCurrency == null
          ? CurrencyFormatter.format(item.value)
          : CurrencyFormatter.formatWithApiCurrency(item.value, apiCurrency);
      return FareBreakdownDisplayRow(
        title: item.title,
        amountLabel: label,
        key: item.key,
        isTotal: item.isTotal,
        isNegative: item.isNegative,
      );
    }).toList(growable: false);
  }

  /// Receipt / PDF lines.
  static List<FareBreakdownComponentLine> linesFromLineItems(
    List<FareBreakdownLineItem> lineItems,
  ) {
    return lineItems
        .map(
          (item) => FareBreakdownComponentLine(
            title: item.title,
            amount: item.value,
            key: item.key,
            isTotal: item.isTotal,
          ),
        )
        .toList(growable: false);
  }
}
