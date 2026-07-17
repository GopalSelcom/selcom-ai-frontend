bool _asBool(dynamic value) => value == true || value == 1 || value == '1';

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}

/// `features.low_rating_driver_block` on `/go/settings`.
class LowRatingDriverBlockSettings {
  final bool enabled;
  final double ratingThreshold;
  final int blockWindowDays;

  const LowRatingDriverBlockSettings({
    required this.enabled,
    required this.ratingThreshold,
    required this.blockWindowDays,
  });

  factory LowRatingDriverBlockSettings.fromJson(Map<String, dynamic> json) {
    return LowRatingDriverBlockSettings(
      enabled: _asBool(json['enabled']),
      ratingThreshold: (json['rating_threshold'] as num?)?.toDouble() ?? 0,
      blockWindowDays: (json['block_window_days'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `support` on `/go/settings` — contact channels.
class SupportContactSettings {
  final String phone;
  final String email;
  final String whatsapp;

  const SupportContactSettings({
    required this.phone,
    required this.email,
    required this.whatsapp,
  });

  factory SupportContactSettings.fromJson(Map<String, dynamic> json) {
    return SupportContactSettings(
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
    );
  }
}

/// `email_support` on `/go/settings`.
class EmailSupportSettings {
  final List<String> subjects;
  final String whatsappText;
  final String emailText;

  const EmailSupportSettings({
    required this.subjects,
    required this.whatsappText,
    required this.emailText,
  });

  factory EmailSupportSettings.fromJson(Map<String, dynamic> json) {
    return EmailSupportSettings(
      subjects: _asStringList(json['subjects']),
      whatsappText: json['whatsapp_text']?.toString() ?? '',
      emailText: json['email_text']?.toString() ?? '',
    );
  }
}

/// `quick_replies` on `/go/settings` (passenger + driver canned messages).
class QuickRepliesSettings {
  final List<String> passenger;
  final List<String> driver;

  const QuickRepliesSettings({required this.passenger, required this.driver});

  factory QuickRepliesSettings.fromJson(Map<String, dynamic> json) {
    return QuickRepliesSettings(
      passenger: _asStringList(json['passenger']),
      driver: _asStringList(json['driver']),
    );
  }
}

/// `payment.cancellation_fee` on `/go/settings`.
class CancellationFeeSettings {
  final bool enabled;
  final double pct;
  final int minFlat;

  const CancellationFeeSettings({
    required this.enabled,
    required this.pct,
    required this.minFlat,
  });

  factory CancellationFeeSettings.fromJson(Map<String, dynamic> json) {
    return CancellationFeeSettings(
      enabled: _asBool(json['enabled']),
      pct: (json['pct'] as num?)?.toDouble() ?? 0,
      minFlat: (json['min_flat'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `payment.midride_cancel` on `/go/settings`.
class MidRideCancelSettings {
  final bool enabled;
  final int captureDelayMs;

  const MidRideCancelSettings({
    required this.enabled,
    required this.captureDelayMs,
  });

  factory MidRideCancelSettings.fromJson(Map<String, dynamic> json) {
    return MidRideCancelSettings(
      enabled: _asBool(json['enabled']),
      captureDelayMs: (json['capture_delay_ms'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `payment` on `/go/settings`.
class PaymentSettings {
  final CancellationFeeSettings? cancellationFee;
  final MidRideCancelSettings? midRideCancel;

  const PaymentSettings({this.cancellationFee, this.midRideCancel});

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    final fee = json['cancellation_fee'];
    final midRide = json['midride_cancel'];
    return PaymentSettings(
      cancellationFee: fee is Map
          ? CancellationFeeSettings.fromJson(Map<String, dynamic>.from(fee))
          : null,
      midRideCancel: midRide is Map
          ? MidRideCancelSettings.fromJson(Map<String, dynamic>.from(midRide))
          : null,
    );
  }
}

/// `runtime_config.matching` on `/go/settings` — driver matching tuning.
class MatchingRuntimeConfig {
  final int matchingTimeoutMs;
  final int driverTimeoutMs;
  final double initialRadiusKm;
  final double radiusIncrementKm;
  final double maxRadiusKm;
  final int maxDriversPerRound;
  final String mode;

  const MatchingRuntimeConfig({
    required this.matchingTimeoutMs,
    required this.driverTimeoutMs,
    required this.initialRadiusKm,
    required this.radiusIncrementKm,
    required this.maxRadiusKm,
    required this.maxDriversPerRound,
    required this.mode,
  });

  factory MatchingRuntimeConfig.fromJson(Map<String, dynamic> json) {
    return MatchingRuntimeConfig(
      matchingTimeoutMs: (json['matching_timeout_ms'] as num?)?.toInt() ?? 0,
      driverTimeoutMs: (json['driver_timeout_ms'] as num?)?.toInt() ?? 0,
      initialRadiusKm: (json['initial_radius_km'] as num?)?.toDouble() ?? 0,
      radiusIncrementKm: (json['radius_increment_km'] as num?)?.toDouble() ?? 0,
      maxRadiusKm: (json['max_radius_km'] as num?)?.toDouble() ?? 0,
      maxDriversPerRound: (json['max_drivers_per_round'] as num?)?.toInt() ?? 0,
      mode: json['mode']?.toString() ?? '',
    );
  }
}

/// `faq[]` on `/go/settings`.
class FaqItemSettings {
  final int order;
  final String question;
  final String answer;

  const FaqItemSettings({
    required this.order,
    required this.question,
    required this.answer,
  });

  factory FaqItemSettings.fromJson(Map<String, dynamic> json) {
    return FaqItemSettings(
      order: (json['order'] as num?)?.toInt() ?? 0,
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }
}

/// `privacy_policy` / `terms_and_conditions` / `about` on `/go/settings`.
class LegalDocumentSettings {
  final String body;
  final String bodySwahili;
  final String updatedAt;

  const LegalDocumentSettings({
    required this.body,
    required this.bodySwahili,
    required this.updatedAt,
  });

  factory LegalDocumentSettings.fromJson(Map<String, dynamic> json) {
    return LegalDocumentSettings(
      body: json['body']?.toString() ?? '',
      bodySwahili: json['body_swahili']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

/// `banner[]` on `/go/settings` — promo banners.
class BannerSettings {
  final String screen;
  final String title;
  final String subtitle;
  final String backgroundImageUrl;
  final String updatedAt;

  const BannerSettings({
    required this.screen,
    required this.title,
    required this.subtitle,
    required this.backgroundImageUrl,
    required this.updatedAt,
  });

  factory BannerSettings.fromJson(Map<String, dynamic> json) {
    return BannerSettings(
      screen: json['screen']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      backgroundImageUrl: json['background_image_url']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

/// One entry in `/go/settings` → `topup_methods[]`.
///
/// Drives the Add Money bottom sheet:
/// - [title] / [subtitle] — shown on the tile (API copy, not localized strings)
/// - [enabled] — `false` hides the option
/// - [order] — display sort (ascending)
/// - [key] — routes to an in-app flow ([keySelcomPesa], [keyLocalBank], etc.)
class TopupMethodSettings {
  /// Opens Selcom Pesa → Go Wallet flow.
  static const String keySelcomPesa = 'selcom_pesa';

  /// Opens local-bank deposit instructions sheet.
  static const String keyLocalBank = 'local_bank';

  /// Opens mobile-money top-up sheet.
  static const String keyMobileMoney = 'mobile_money';

  /// Opens saved-cards top-up sheet.
  static const String keyCard = 'card';

  final String key;
  final String title;
  final String subtitle;
  final bool enabled;
  final int order;
  final String updatedAt;

  const TopupMethodSettings({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.order,
    required this.updatedAt,
  });

  factory TopupMethodSettings.fromJson(Map<String, dynamic> json) {
    return TopupMethodSettings(
      key: json['key']?.toString().trim() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      enabled: _asBool(json['enabled']),
      order: (json['order'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

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

  /// `features.max_stops` — max intermediate stops (excludes final destination).
  static const int defaultMaxStops = 2;

  final Map<String, bool> features;
  final int paymentTimerSeconds;
  final BookForOtherSettings? bookForOther;
  final LowRatingDriverBlockSettings? lowRatingDriverBlock;

  /// Ride-cancel options from `/go/settings` → `settings.cancellation_reasons`.
  final List<String> cancellationReasons;

  final int maxStops;

  final String id;
  final SupportContactSettings? support;
  final EmailSupportSettings? emailSupport;
  final QuickRepliesSettings? quickReplies;
  final PaymentSettings? payment;
  final MatchingRuntimeConfig? matching;
  final List<FaqItemSettings> faq;
  final LegalDocumentSettings? privacyPolicy;
  final LegalDocumentSettings? termsAndConditions;
  final LegalDocumentSettings? about;
  final List<BannerSettings> banners;
  final List<TopupMethodSettings> topupMethods;
  final String createdAt;
  final String updatedAt;

  const AppSettingsModel({
    required this.features,
    this.paymentTimerSeconds = defaultPaymentTimerSeconds,
    this.bookForOther,
    this.lowRatingDriverBlock,
    this.cancellationReasons = const [],
    this.maxStops = defaultMaxStops,
    this.id = '',
    this.support,
    this.emailSupport,
    this.quickReplies,
    this.payment,
    this.matching,
    this.faq = const [],
    this.privacyPolicy,
    this.termsAndConditions,
    this.about,
    this.banners = const [],
    this.topupMethods = const [],
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      return value == true || value == 1 || value == '1';
    }

    final featureMap = <String, bool>{};
    BookForOtherSettings? bookForOther;
    LowRatingDriverBlockSettings? lowRatingDriverBlock;
    var maxStops = defaultMaxStops;
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
        if (entry.key == 'low_rating_driver_block' && value is Map) {
          lowRatingDriverBlock = LowRatingDriverBlockSettings.fromJson(
            Map<String, dynamic>.from(value),
          );
          featureMap[entry.key] = lowRatingDriverBlock.enabled;
          continue;
        }
        if (entry.key == 'max_stops') {
          maxStops = _parsePositiveInt(value, defaultMaxStops);
          continue;
        }
        if (value is Map) continue;
        featureMap[entry.key] = parseBool(value);
      }
    }

    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final supportMap = asMap(json['support']);
    final emailSupportMap = asMap(json['email_support']);
    final quickRepliesMap = asMap(json['quick_replies']);
    final paymentMap = asMap(json['payment']);
    final matchingMap = asMap(asMap(json['runtime_config'])?['matching']);
    final privacyMap = asMap(json['privacy_policy']);
    final termsMap = asMap(json['terms_and_conditions']);
    final aboutMap = asMap(json['about']);

    final rawFaq = json['faq'];
    final faq = rawFaq is List
        ? rawFaq
              .whereType<Map>()
              .map((e) => FaqItemSettings.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
        : const <FaqItemSettings>[];

    final rawBanners = json['banner'];
    final banners = rawBanners is List
        ? rawBanners
              .whereType<Map>()
              .map((e) => BannerSettings.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
        : const <BannerSettings>[];

    final rawTopupMethods = json['topup_methods'];
    final topupMethods = rawTopupMethods is List
        ? rawTopupMethods
              .whereType<Map>()
              .map(
                (e) =>
                    TopupMethodSettings.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : const <TopupMethodSettings>[];

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
      lowRatingDriverBlock: lowRatingDriverBlock,
      cancellationReasons: cancellationReasons,
      maxStops: maxStops,
      id: json['_id']?.toString() ?? '',
      support: supportMap != null
          ? SupportContactSettings.fromJson(supportMap)
          : null,
      emailSupport: emailSupportMap != null
          ? EmailSupportSettings.fromJson(emailSupportMap)
          : null,
      quickReplies: quickRepliesMap != null
          ? QuickRepliesSettings.fromJson(quickRepliesMap)
          : null,
      payment: paymentMap != null ? PaymentSettings.fromJson(paymentMap) : null,
      matching: matchingMap != null
          ? MatchingRuntimeConfig.fromJson(matchingMap)
          : null,
      faq: faq,
      privacyPolicy: privacyMap != null
          ? LegalDocumentSettings.fromJson(privacyMap)
          : null,
      termsAndConditions: termsMap != null
          ? LegalDocumentSettings.fromJson(termsMap)
          : null,
      about: aboutMap != null ? LegalDocumentSettings.fromJson(aboutMap) : null,
      banners: banners,
      topupMethods: topupMethods,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
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
