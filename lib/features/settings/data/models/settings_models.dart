class AppSettingsModel {
  /// Server `payment_timer` (seconds); used when absent or invalid.
  static const int defaultPaymentTimerSeconds = 300;

  final Map<String, bool> features;
  final int paymentTimerSeconds;

  const AppSettingsModel({
    required this.features,
    this.paymentTimerSeconds = defaultPaymentTimerSeconds,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      return value == true || value == 1 || value == '1';
    }

    final featureMap = <String, bool>{};
    final rawFeatures = json['features'];
    if (rawFeatures is Map<String, dynamic>) {
      for (final entry in rawFeatures.entries) {
        featureMap[entry.key] = parseBool(entry.value);
      }
    }

    return AppSettingsModel(
      features: featureMap,
      paymentTimerSeconds: _parsePaymentTimerSeconds(json['payment_timer']),
    );
  }

  static int _parsePaymentTimerSeconds(dynamic value) {
    if (value == null) return defaultPaymentTimerSeconds;
    final int? parsed = switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v.trim()),
      _ => null,
    };
    if (parsed == null || parsed <= 0) return defaultPaymentTimerSeconds;
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
