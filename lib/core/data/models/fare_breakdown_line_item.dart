import 'dart:convert';

/// One row from `fare_breakdown.line_items` (Total Fare card).
///
/// Render in API order: [title] → formatted [value]. Do not re-combine
/// ride_charge / booking_fee / promo client-side when this list is present.
class FareBreakdownLineItem {
  /// Stable id (`ride_charge`, `cashback`, `total_amount`, …).
  final String key;
  final String title;

  /// Signed TZS amount; promo/cashback rows are negative.
  final int value;

  const FareBreakdownLineItem({
    required this.key,
    required this.title,
    required this.value,
  });

  bool get isTotal => key == 'total_amount';

  bool get isNegative => value < 0;

  factory FareBreakdownLineItem.fromJson(String str) =>
      FareBreakdownLineItem.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory FareBreakdownLineItem.fromMap(Map<String, dynamic> json) =>
      FareBreakdownLineItem(
        key: (json['key'] as String?)?.trim() ?? '',
        title: (json['title'] as String?)?.trim() ?? '',
        value: (json['value'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
    'key': key,
    'title': title,
    'value': value,
  };

  /// Parses `fare_breakdown.line_items`; empty when absent/invalid.
  static List<FareBreakdownLineItem> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FareBreakdownLineItem.fromMap(Map<String, dynamic>.from(e)))
        .where((e) => e.title.isNotEmpty)
        .toList(growable: false);
  }
}
