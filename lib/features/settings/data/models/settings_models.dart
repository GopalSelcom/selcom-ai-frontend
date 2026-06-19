class BookForOtherSettings {
  final bool enabled;
  final double distanceThresholdKm;

  /// Max concurrent **book-for-other** rides (from `features.book_for_other.max_active`).
  /// Does not limit the rider's own active ride (still max one self ride).
  final int maxActive;

  const BookForOtherSettings({
    required this.enabled,
    required this.distanceThresholdKm,
    required this.maxActive,
  });

  factory BookForOtherSettings.fromJson(Map<String, dynamic> json) {
    return BookForOtherSettings(
      enabled: json['enabled'] == true,
      distanceThresholdKm:
          (json['distance_threshold_km'] as num?)?.toDouble() ?? 1,
      maxActive: (json['max_active'] as num?)?.toInt() ?? 1,
    );
  }
}

class AppSettingsModel {
  /// Server `payment_timer` (seconds); used when absent or invalid.
  static const int defaultPaymentTimerSeconds = 300;

  final Map<String, bool> features;
  final int paymentTimerSeconds;
  final BookForOtherSettings? bookForOther;

  /// Ride-cancel options from `/go/settings` → `settings.cancellation_reasons`.
  final List<String> cancellationReasons;

  const AppSettingsModel({
    required this.features,
    this.paymentTimerSeconds = defaultPaymentTimerSeconds,
    this.bookForOther,
    this.cancellationReasons = const [],
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      return value == true || value == 1 || value == '1';
    }

    final featureMap = <String, bool>{};
    BookForOtherSettings? bookForOther;
    final rawFeatures = json['features'];
    if (rawFeatures is Map<String, dynamic>) {
      for (final entry in rawFeatures.entries) {
        final value = entry.value;
        if (entry.key == 'book_for_other' && value is Map) {
          bookForOther = BookForOtherSettings.fromJson(
            Map<String, dynamic>.from(value),
          );
          featureMap[entry.key] = bookForOther.enabled;
          continue;
        }
        if (value is Map) continue;
        featureMap[entry.key] = parseBool(value);
      }
    }

    // Server-managed cancel reasons; shown verbatim in the cancel dialog.
    final rawReasons = json['cancellation_reasons'];
    final cancellationReasons = rawReasons is List
        ? rawReasons
              .whereType<String>()
              .map((reason) => reason.trim())
              .where((reason) => reason.isNotEmpty)
              .toList()
        : const <String>[];

    return AppSettingsModel(
      features: featureMap,
      paymentTimerSeconds: _parsePaymentTimerSeconds(json['payment_timer']),
      bookForOther: bookForOther,
      cancellationReasons: cancellationReasons,
    );
  }

  static int _parsePaymentTimerSeconds(dynamic value) {
    return _parsePositiveInt(value, defaultPaymentTimerSeconds);
  }

  static int _parsePositiveInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    final int? parsed = switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v.trim()),
      _ => null,
    };
    if (parsed == null || parsed <= 0) return fallback;
    return parsed;
  }

  bool featureEnabled(String key, {bool fallback = false}) {
    return features[key] ?? fallback;
  }
}

class RidePinPreferenceModel {
  final bool userEnabled;
  final bool adminRequired;
  final bool effectiveRequired;

  const RidePinPreferenceModel({
    required this.userEnabled,
    required this.adminRequired,
    required this.effectiveRequired,
  });

  factory RidePinPreferenceModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      return value == true || value == 1 || value == '1';
    }

    return RidePinPreferenceModel(
      userEnabled: parseBool(json['user_enabled']),
      adminRequired: parseBool(json['admin_required']),
      effectiveRequired: parseBool(json['effective_required']),
    );
  }
}
