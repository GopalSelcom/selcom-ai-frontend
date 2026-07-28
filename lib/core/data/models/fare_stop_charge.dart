import 'dart:convert';

/// One stop fee line from `fare_breakdown.stop_charges`.
///
/// Prefer these lines in the UI over the legacy aggregate [waypoint_charge].
/// Example: `{ "stop_number": 1, "label": "Stop 1", "amount": 500 }`.
class FareStopCharge {
  final int stopNumber;
  final String label;
  final int amount;

  const FareStopCharge({
    required this.stopNumber,
    required this.label,
    required this.amount,
  });

  factory FareStopCharge.fromJson(String str) =>
      FareStopCharge.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory FareStopCharge.fromMap(Map<String, dynamic> json) => FareStopCharge(
    stopNumber: (json['stop_number'] as num?)?.toInt() ?? 0,
    label: (json['label'] as String?)?.trim() ?? '',
    amount: (json['amount'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'stop_number': stopNumber,
    'label': label,
    'amount': amount,
  };

  /// Parses `fare_breakdown.stop_charges`; returns empty when absent/invalid.
  static List<FareStopCharge> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => FareStopCharge.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}
