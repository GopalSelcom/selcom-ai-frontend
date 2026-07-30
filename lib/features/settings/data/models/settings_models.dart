import 'dart:convert';

class AppSettingsResponse {
  int? statusCode;
  Data? data;

  AppSettingsResponse({this.statusCode, this.data});

  factory AppSettingsResponse.fromJson(String str) =>
      AppSettingsResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AppSettingsResponse.fromMap(Map<String, dynamic> json) =>
      AppSettingsResponse(
        statusCode: json["status_code"],
        data: json["data"] == null ? null : Data.fromMap(json["data"]),
      );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "data": data?.toMap(),
  };
}

class Data {
  Settings? settings;

  Data({this.settings});

  factory Data.fromJson(String str) => Data.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Data.fromMap(Map<String, dynamic> json) => Data(
    settings: json["settings"] == null
        ? null
        : Settings.fromMap(json["settings"]),
  );

  Map<String, dynamic> toMap() => {"settings": settings?.toMap()};
}

class Settings {
  Features? features;
  Support? support;
  EmailSupport? emailSupport;
  QuickReplies? quickReplies;
  Payment? payment;
  RuntimeConfig? runtimeConfig;
  int? paymentTimer;
  String? id;
  List<Faq>? faq;
  About? privacyPolicy;
  About? termsAndConditions;
  About? about;
  String? createdAt;
  String? updatedAt;
  int? v;
  List<Banner>? banner;
  List<TopupMethod>? topupMethods;
  List<String>? cancellationReasons;

  Settings({
    this.features,
    this.support,
    this.emailSupport,
    this.quickReplies,
    this.payment,
    this.runtimeConfig,
    this.paymentTimer,
    this.id,
    this.faq,
    this.privacyPolicy,
    this.termsAndConditions,
    this.about,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.banner,
    this.topupMethods,
    this.cancellationReasons,
  });

  factory Settings.fromJson(String str) => Settings.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Settings.fromMap(Map<String, dynamic> json) => Settings(
    features: json["features"] == null
        ? null
        : Features.fromMap(json["features"]),
    support: json["support"] == null ? null : Support.fromMap(json["support"]),
    emailSupport: json["email_support"] == null
        ? null
        : EmailSupport.fromMap(json["email_support"]),
    quickReplies: json["quick_replies"] == null
        ? null
        : QuickReplies.fromMap(json["quick_replies"]),
    payment: json["payment"] == null ? null : Payment.fromMap(json["payment"]),
    runtimeConfig: json["runtime_config"] == null
        ? null
        : RuntimeConfig.fromMap(json["runtime_config"]),
    paymentTimer: json["payment_timer"],
    id: json["_id"],
    faq: json["faq"] == null
        ? []
        : List<Faq>.from(json["faq"]!.map((x) => Faq.fromMap(x))),
    privacyPolicy: json["privacy_policy"] == null
        ? null
        : About.fromMap(json["privacy_policy"]),
    termsAndConditions: json["terms_and_conditions"] == null
        ? null
        : About.fromMap(json["terms_and_conditions"]),
    about: json["about"] == null ? null : About.fromMap(json["about"]),
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    v: json["__v"],
    banner: json["banner"] == null
        ? []
        : List<Banner>.from(json["banner"]!.map((x) => Banner.fromMap(x))),
    topupMethods: json["topup_methods"] == null
        ? []
        : List<TopupMethod>.from(
            json["topup_methods"]!.map((x) => TopupMethod.fromMap(x)),
          ),
    cancellationReasons: json["cancellation_reasons"] == null
        ? []
        : List<String>.from(json["cancellation_reasons"]!.map((x) => x)),
  );

  Map<String, dynamic> toMap() => {
    "features": features?.toMap(),
    "support": support?.toMap(),
    "email_support": emailSupport?.toMap(),
    "quick_replies": quickReplies?.toMap(),
    "payment": payment?.toMap(),
    "runtime_config": runtimeConfig?.toMap(),
    "payment_timer": paymentTimer,
    "_id": id,
    "faq": faq == null ? [] : List<dynamic>.from(faq!.map((x) => x.toMap())),
    "privacy_policy": privacyPolicy?.toMap(),
    "terms_and_conditions": termsAndConditions?.toMap(),
    "about": about?.toMap(),
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "__v": v,
    "banner": banner == null
        ? []
        : List<dynamic>.from(banner!.map((x) => x.toMap())),
    "topup_methods": topupMethods == null
        ? []
        : List<dynamic>.from(topupMethods!.map((x) => x.toMap())),
    "cancellation_reasons": cancellationReasons == null
        ? []
        : List<dynamic>.from(cancellationReasons!.map((x) => x)),
  };
}

class About {
  String? body;
  String? bodySwahili;
  String? updatedAt;

  About({this.body, this.bodySwahili, this.updatedAt});

  factory About.fromJson(String str) => About.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory About.fromMap(Map<String, dynamic> json) => About(
    body: json["body"],
    bodySwahili: json["body_swahili"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toMap() => {
    "body": body,
    "body_swahili": bodySwahili,
    "updated_at": updatedAt,
  };
}

class Banner {
  String? screen;
  String? title;
  String? subtitle;
  String? backgroundImageUrl;
  String? updatedAt;

  Banner({
    this.screen,
    this.title,
    this.subtitle,
    this.backgroundImageUrl,
    this.updatedAt,
  });

  factory Banner.fromJson(String str) => Banner.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Banner.fromMap(Map<String, dynamic> json) => Banner(
    screen: json["screen"],
    title: json["title"],
    subtitle: json["subtitle"],
    backgroundImageUrl: json["background_image_url"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toMap() => {
    "screen": screen,
    "title": title,
    "subtitle": subtitle,
    "background_image_url": backgroundImageUrl,
    "updated_at": updatedAt,
  };
}

class EmailSupport {
  List<String>? subjects;
  String? whatsappText;
  String? emailText;

  EmailSupport({this.subjects, this.whatsappText, this.emailText});

  factory EmailSupport.fromJson(String str) =>
      EmailSupport.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory EmailSupport.fromMap(Map<String, dynamic> json) => EmailSupport(
    subjects: json["subjects"] == null
        ? []
        : List<String>.from(json["subjects"]!.map((x) => x)),
    whatsappText: json["whatsapp_text"],
    emailText: json["email_text"],
  );

  Map<String, dynamic> toMap() => {
    "subjects": subjects == null
        ? []
        : List<dynamic>.from(subjects!.map((x) => x)),
    "whatsapp_text": whatsappText,
    "email_text": emailText,
  };
}

class Faq {
  int? order;
  String? question;
  String? answer;

  Faq({this.order, this.question, this.answer});

  factory Faq.fromJson(String str) => Faq.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Faq.fromMap(Map<String, dynamic> json) => Faq(
    order: json["order"],
    question: json["question"],
    answer: json["answer"],
  );

  Map<String, dynamic> toMap() => {
    "order": order,
    "question": question,
    "answer": answer,
  };
}

class Features {
  LowRatingDriverBlock? lowRatingDriverBlock;
  BookForOther? bookForOther;
  bool? ridePinAdminRequired;
  int? maxStops;

  Features({
    this.lowRatingDriverBlock,
    this.bookForOther,
    this.ridePinAdminRequired,
    this.maxStops,
  });

  factory Features.fromJson(String str) => Features.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Features.fromMap(Map<String, dynamic> json) => Features(
    lowRatingDriverBlock: json["low_rating_driver_block"] == null
        ? null
        : LowRatingDriverBlock.fromMap(json["low_rating_driver_block"]),
    bookForOther: json["book_for_other"] == null
        ? null
        : BookForOther.fromMap(json["book_for_other"]),
    ridePinAdminRequired: json["ride_pin_admin_required"],
    maxStops: json["max_stops"],
  );

  Map<String, dynamic> toMap() => {
    "low_rating_driver_block": lowRatingDriverBlock?.toMap(),
    "book_for_other": bookForOther?.toMap(),
    "ride_pin_admin_required": ridePinAdminRequired,
    "max_stops": maxStops,
  };
}

class BookForOther {
  bool? enabled;
  /// API may send km as int or double (e.g. `1` or `0.1`).
  num? distanceThresholdKm;
  int? maxActive;

  BookForOther({this.enabled, this.distanceThresholdKm, this.maxActive});

  factory BookForOther.fromJson(String str) =>
      BookForOther.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BookForOther.fromMap(Map<String, dynamic> json) => BookForOther(
    enabled: json["enabled"],
    distanceThresholdKm: json["distance_threshold_km"],
    maxActive: json["max_active"],
  );

  Map<String, dynamic> toMap() => {
    "enabled": enabled,
    "distance_threshold_km": distanceThresholdKm,
    "max_active": maxActive,
  };
}

class LowRatingDriverBlock {
  bool? enabled;
  int? ratingThreshold;
  int? blockWindowDays;

  LowRatingDriverBlock({
    this.enabled,
    this.ratingThreshold,
    this.blockWindowDays,
  });

  factory LowRatingDriverBlock.fromJson(String str) =>
      LowRatingDriverBlock.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory LowRatingDriverBlock.fromMap(Map<String, dynamic> json) =>
      LowRatingDriverBlock(
        enabled: json["enabled"],
        ratingThreshold: json["rating_threshold"],
        blockWindowDays: json["block_window_days"],
      );

  Map<String, dynamic> toMap() => {
    "enabled": enabled,
    "rating_threshold": ratingThreshold,
    "block_window_days": blockWindowDays,
  };
}

class Payment {
  CancellationFee? cancellationFee;
  MidrideCancel? midrideCancel;

  Payment({this.cancellationFee, this.midrideCancel});

  factory Payment.fromJson(String str) => Payment.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Payment.fromMap(Map<String, dynamic> json) => Payment(
    cancellationFee: json["cancellation_fee"] == null
        ? null
        : CancellationFee.fromMap(json["cancellation_fee"]),
    midrideCancel: json["midride_cancel"] == null
        ? null
        : MidrideCancel.fromMap(json["midride_cancel"]),
  );

  Map<String, dynamic> toMap() => {
    "cancellation_fee": cancellationFee?.toMap(),
    "midride_cancel": midrideCancel?.toMap(),
  };
}

class CancellationFee {
  bool? enabled;
  int? pct;
  int? minFlat;

  CancellationFee({this.enabled, this.pct, this.minFlat});

  factory CancellationFee.fromJson(String str) =>
      CancellationFee.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CancellationFee.fromMap(Map<String, dynamic> json) => CancellationFee(
    enabled: json["enabled"],
    pct: json["pct"],
    minFlat: json["min_flat"],
  );

  Map<String, dynamic> toMap() => {
    "enabled": enabled,
    "pct": pct,
    "min_flat": minFlat,
  };
}

class MidrideCancel {
  bool? enabled;
  int? captureDelayMs;

  MidrideCancel({this.enabled, this.captureDelayMs});

  factory MidrideCancel.fromJson(String str) =>
      MidrideCancel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MidrideCancel.fromMap(Map<String, dynamic> json) => MidrideCancel(
    enabled: json["enabled"],
    captureDelayMs: json["capture_delay_ms"],
  );

  Map<String, dynamic> toMap() => {
    "enabled": enabled,
    "capture_delay_ms": captureDelayMs,
  };
}

class QuickReplies {
  List<String>? passenger;
  List<String>? driver;

  QuickReplies({this.passenger, this.driver});

  factory QuickReplies.fromJson(String str) =>
      QuickReplies.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory QuickReplies.fromMap(Map<String, dynamic> json) => QuickReplies(
    passenger: json["passenger"] == null
        ? []
        : List<String>.from(json["passenger"]!.map((x) => x)),
    driver: json["driver"] == null
        ? []
        : List<String>.from(json["driver"]!.map((x) => x)),
  );

  Map<String, dynamic> toMap() => {
    "passenger": passenger == null
        ? []
        : List<dynamic>.from(passenger!.map((x) => x)),
    "driver": driver == null ? [] : List<dynamic>.from(driver!.map((x) => x)),
  };
}

class RuntimeConfig {
  Matching? matching;

  RuntimeConfig({this.matching});

  factory RuntimeConfig.fromJson(String str) =>
      RuntimeConfig.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RuntimeConfig.fromMap(Map<String, dynamic> json) => RuntimeConfig(
    matching: json["matching"] == null
        ? null
        : Matching.fromMap(json["matching"]),
  );

  Map<String, dynamic> toMap() => {"matching": matching?.toMap()};
}

class Matching {
  int? matchingTimeoutMs;
  int? driverTimeoutMs;
  int? initialRadiusKm;
  int? radiusIncrementKm;
  int? maxRadiusKm;
  int? maxDriversPerRound;
  String? mode;

  Matching({
    this.matchingTimeoutMs,
    this.driverTimeoutMs,
    this.initialRadiusKm,
    this.radiusIncrementKm,
    this.maxRadiusKm,
    this.maxDriversPerRound,
    this.mode,
  });

  factory Matching.fromJson(String str) => Matching.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Matching.fromMap(Map<String, dynamic> json) => Matching(
    matchingTimeoutMs: json["matching_timeout_ms"],
    driverTimeoutMs: json["driver_timeout_ms"],
    initialRadiusKm: json["initial_radius_km"],
    radiusIncrementKm: json["radius_increment_km"],
    maxRadiusKm: json["max_radius_km"],
    maxDriversPerRound: json["max_drivers_per_round"],
    mode: json["mode"],
  );

  Map<String, dynamic> toMap() => {
    "matching_timeout_ms": matchingTimeoutMs,
    "driver_timeout_ms": driverTimeoutMs,
    "initial_radius_km": initialRadiusKm,
    "radius_increment_km": radiusIncrementKm,
    "max_radius_km": maxRadiusKm,
    "max_drivers_per_round": maxDriversPerRound,
    "mode": mode,
  };
}

class Support {
  String? phone;
  String? email;
  String? whatsapp;

  Support({this.phone, this.email, this.whatsapp});

  factory Support.fromJson(String str) => Support.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Support.fromMap(Map<String, dynamic> json) => Support(
    phone: json["phone"],
    email: json["email"],
    whatsapp: json["whatsapp"],
  );

  Map<String, dynamic> toMap() => {
    "phone": phone,
    "email": email,
    "whatsapp": whatsapp,
  };
}

class TopupMethod {
  String? key;
  String? title;
  String? subtitle;
  bool? enabled;
  int? order;
  String? updatedAt;

  TopupMethod({
    this.key,
    this.title,
    this.subtitle,
    this.enabled,
    this.order,
    this.updatedAt,
  });

  factory TopupMethod.fromJson(String str) =>
      TopupMethod.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TopupMethod.fromMap(Map<String, dynamic> json) => TopupMethod(
    key: json["key"],
    title: json["title"],
    subtitle: json["subtitle"],
    enabled: json["enabled"],
    order: json["order"],
    updatedAt: json["updated_at"],
  );

  Map<String, dynamic> toMap() => {
    "key": key,
    "title": title,
    "subtitle": subtitle,
    "enabled": enabled,
    "order": order,
    "updated_at": updatedAt,
  };
}


/// App-side defaults when `/go/settings` omits or invalidates values.
abstract final class AppSettingsDefaults {
  static const int paymentTimerSeconds = 300;
  static const int maxStops = 2;
}

/// Known `topup_methods[].key` values that map to in-app top-up flows.
abstract final class TopupMethodKeys {
  static const String selcomPesa = 'selcom_pesa';
  static const String localBank = 'local_bank';
  static const String mobileMoney = 'mobile_money';
  static const String card = 'card';
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
