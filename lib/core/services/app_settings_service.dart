import 'package:get/get.dart';

import '../../features/settings/data/models/settings_models.dart';
import '../../features/settings/domain/usecases/settings_usecase.dart';

class AppSettingsService {
  AppSettingsService({required this.settingsUseCase});

  final SettingsUseCase settingsUseCase;

  final features = <String, bool>{}.obs;
  final isLoaded = false.obs;

  /// `/go/settings` `payment_timer` (seconds). Default 5 minutes until loaded.
  final paymentWaitSeconds = AppSettingsModel.defaultPaymentTimerSeconds.obs;
  final bookForOtherSettings = Rxn<BookForOtherSettings>();

  /// Cached `cancellation_reasons` from `/go/settings` (populated by [preload]).
  final cancellationReasons = <String>[].obs;

  /// Cached `features.max_stops` from `/go/settings` (populated by [preload]).
  final maxStops = AppSettingsModel.defaultMaxStops.obs;

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

  /// `/go/settings` `payment_timer` (seconds), defaulting to [AppSettingsModel.defaultPaymentTimerSeconds].
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
        paymentWaitSeconds.value = AppSettingsModel.defaultPaymentTimerSeconds;
        cancellationReasons.clear();
        maxStops.value = AppSettingsModel.defaultMaxStops;
      },
      (settings) {
        features.assignAll(settings.features);
        bookForOtherSettings.value = settings.bookForOther;
        paymentWaitSeconds.value = settings.paymentTimerSeconds;
        cancellationReasons.assignAll(settings.cancellationReasons);
        maxStops.value = settings.maxStops;
      },
    );
    isLoaded.value = true;
  }
}
