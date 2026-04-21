import 'package:get/get.dart';
import '../../../../../core/services/app_settings_service.dart';
import '../../../../../shared/utils/app_dialogs.dart';
import '../../../../../features/settings/domain/usecases/settings_usecase.dart';

class SettingsController extends GetxController {
  final SettingsUseCase settingsUseCase;
  final AppSettingsService appSettingsService;

  SettingsController({
    required this.settingsUseCase,
    required this.appSettingsService,
  });

  final isLoading = false.obs;
  final isSaving = false.obs;
  final features = <String, bool>{}.obs;
  final userEnabledRidePin = false.obs;
  final adminRequiredRidePin = false.obs;
  final effectiveRequiredRidePin = false.obs;

  bool get canToggleRidePin => !adminRequiredRidePin.value;
  bool get hasRidePinFeature => features.containsKey('ride_pin_admin_required');
  bool get ridePinSwitchValue =>
      adminRequiredRidePin.value
          ? effectiveRequiredRidePin.value
          : userEnabledRidePin.value;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;

    await appSettingsService.preload();
    features.assignAll(appSettingsService.features);
    adminRequiredRidePin.value = appSettingsService.featureEnabled(
      'ride_pin_admin_required',
    );

    if (!hasRidePinFeature) {
      userEnabledRidePin.value = false;
      effectiveRequiredRidePin.value = false;
      isLoading.value = false;
      return;
    }

    final preferenceResult = await settingsUseCase.getRidePinPreference();
    preferenceResult.fold(
      (failure) => AppDialogs.showErrorDialog(message: failure.message),
      (preference) {
        userEnabledRidePin.value = preference.userEnabled;
        adminRequiredRidePin.value = preference.adminRequired;
        effectiveRequiredRidePin.value = preference.effectiveRequired;
      },
    );

    if (adminRequiredRidePin.value) {
      effectiveRequiredRidePin.value = true;
    }

    isLoading.value = false;
  }

  Future<void> onToggleRidePin(bool value) async {
    if (!canToggleRidePin || isSaving.value) return;

    final previousValue = userEnabledRidePin.value;
    userEnabledRidePin.value = value;
    isSaving.value = true;

    final result = await settingsUseCase.updateRidePinPreference(enabled: value);
    result.fold(
      (failure) {
        userEnabledRidePin.value = previousValue;
        AppDialogs.showErrorDialog(message: failure.message);
      },
      (preference) {
        userEnabledRidePin.value = preference.userEnabled;
        adminRequiredRidePin.value = preference.adminRequired;
        effectiveRequiredRidePin.value = preference.effectiveRequired;
      },
    );

    isSaving.value = false;
  }
}
