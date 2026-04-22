import 'package:get/get.dart';
import '../../features/settings/domain/usecases/settings_usecase.dart';

class AppSettingsService {
  AppSettingsService({required this.settingsUseCase});

  final SettingsUseCase settingsUseCase;

  final features = <String, bool>{}.obs;
  final isLoaded = false.obs;

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
      },
      (settings) {
        features.assignAll(settings.features);
      },
    );
    isLoaded.value = true;
  }
}
