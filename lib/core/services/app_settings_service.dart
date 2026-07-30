import 'package:get/get.dart';

import '../../features/settings/data/models/settings_models.dart';
import '../../features/settings/domain/usecases/settings_usecase.dart';

class AppSettingsService {
  AppSettingsService({required this.settingsUseCase});

  final SettingsUseCase settingsUseCase;

  final features = <String, bool>{}.obs;
  final isLoaded = false.obs;

  /// `/go/settings` `payment_timer` (seconds). Default 5 minutes until loaded.
  final paymentWaitSeconds = AppSettingsDefaults.paymentTimerSeconds.obs;
  final bookForOtherSettings = Rxn<BookForOther>();

  /// Cached `cancellation_reasons` from `/go/settings` (populated by [preload]).
  final cancellationReasons = <String>[].obs;

  /// Cached `features.max_stops` from `/go/settings` (populated by [preload]).
  final maxStops = AppSettingsDefaults.maxStops.obs;

  /// Cached `topup_methods` from `/go/settings` (populated by [preload]).
  ///
  /// Used by the Add Money bottom sheet for title, subtitle, order, and
  /// enabled visibility. Flow navigation uses each method's `key`.
  final topupMethods = <TopupMethod>[].obs;

  /// Add-money options to display: `enabled == true` only, sorted by `order`.
  List<TopupMethod> get enabledTopupMethods {
    final methods = topupMethods.where((m) => m.enabled == true).toList()
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    return methods;
  }

  bool get bookForOtherEnabled => bookForOtherSettings.value?.enabled ?? false;

  /// Max intermediate stops allowed (excludes final destination).
  int get maxIntermediateStops => maxStops.value;

  /// `features.book_for_other.max_active` — cap on rides booked for someone else.
  int get maxActiveBookForOtherRides =>
      bookForOtherSettings.value?.maxActive ?? 1;

  bool get hasAnyFeatureEnabled => features.values.any((v) => v == true);

  bool hasFeature(String key) => features.containsKey(key);

  bool featureEnabled(String key, {bool fallback = false}) {
    return features[key] ?? fallback;
  }

  /// Returns cached cancel reasons; calls [preload] only when the cache is empty
  /// (e.g. splash preload still in flight or not yet run).
  Future<List<String>> resolveCancellationReasons() async {
    if (cancellationReasons.isEmpty) {
      await preload();
    }
    return List<String>.from(cancellationReasons);
  }

  /// `/go/settings` `payment_timer` (seconds), defaulting to
  /// [AppSettingsDefaults.paymentTimerSeconds].
  Future<int> resolvePaymentTimerSeconds() async {
    if (!isLoaded.value) {
      await preload();
    }
    return paymentWaitSeconds.value;
  }

  Future<void> preload({bool forceRefresh = false}) async {
    if (isLoaded.value && !forceRefresh) return;

    final result = await settingsUseCase.getAppSettings();
    result.fold(
      (_) {
        features.clear();
        bookForOtherSettings.value = null;
        paymentWaitSeconds.value = AppSettingsDefaults.paymentTimerSeconds;
        cancellationReasons.clear();
        maxStops.value = AppSettingsDefaults.maxStops;
        topupMethods.clear();
        // Keep isLoaded false so a later screen can retry after a failed parse/load.
        isLoaded.value = false;
      },
      (settings) {
        features.assignAll(_featureFlagsFrom(settings));
        bookForOtherSettings.value = settings.features?.bookForOther;
        paymentWaitSeconds.value = _positiveOrDefault(
          settings.paymentTimer,
          AppSettingsDefaults.paymentTimerSeconds,
        );
        cancellationReasons.assignAll(settings.cancellationReasons ?? const []);
        maxStops.value = _positiveOrDefault(
          settings.features?.maxStops,
          AppSettingsDefaults.maxStops,
        );
        topupMethods.assignAll(settings.topupMethods ?? const []);
        isLoaded.value = true;
      },
    );
  }

  Map<String, bool> _featureFlagsFrom(Settings settings) {
    final f = settings.features;
    if (f == null) return const {};

    final map = <String, bool>{};
    if (f.ridePinAdminRequired != null) {
      map['ride_pin_admin_required'] = f.ridePinAdminRequired!;
    }
    if (f.bookForOther?.enabled != null) {
      map['book_for_other'] = f.bookForOther!.enabled!;
    }
    if (f.lowRatingDriverBlock?.enabled != null) {
      map['low_rating_driver_block'] = f.lowRatingDriverBlock!.enabled!;
    }
    return map;
  }

  int _positiveOrDefault(int? value, int fallback) {
    if (value == null || value <= 0) return fallback;
    return value;
  }
}
