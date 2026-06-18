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

  bool get bookForOtherEnabled => bookForOtherSettings.value?.enabled ?? false;

  /// `features.book_for_other.max_active` — cap on rides booked for someone else.
  int get maxActiveBookForOtherRides =>
      bookForOtherSettings.value?.maxActive ?? 1;

  bool get hasAnyFeatureEnabled => features.values.any((v) => v == true);

  bool hasFeature(String key) => features.containsKey(key);

  bool featureEnabled(String key, {bool fallback = false}) {
    return features[key] ?? fallback;
  }

  Future<void> preload({bool forceRefresh = false}) async {
    if (isLoaded.value && !forceRefresh) return;

    final result = await settingsUseCase.getAppSettings();
    result.fold(
      (_) {
        features.clear();
        bookForOtherSettings.value = null;
        paymentWaitSeconds.value = AppSettingsModel.defaultPaymentTimerSeconds;
      },
      (settings) {
        features.assignAll(settings.features);
        bookForOtherSettings.value = settings.bookForOther;
        paymentWaitSeconds.value = settings.paymentTimerSeconds;
      },
    );
    isLoaded.value = true;
  }
}
