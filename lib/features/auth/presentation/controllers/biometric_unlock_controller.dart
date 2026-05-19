import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../domain/usecases/login_pin_usecases.dart';

/// Prompts [BiometricService.authenticate] then refreshes session tokens.
///
/// Auto-starts auth in [onReady]. "Use PIN instead" → [AppRoutes.pinLogin].
class BiometricUnlockController extends GetxController {
  BiometricUnlockController({
    required this.biometricService,
    required this.refreshLoginSessionUseCase,
    required this.analyticsService,
  });

  final BiometricService biometricService;
  final RefreshLoginSessionUseCase refreshLoginSessionUseCase;
  final AnalyticsService analyticsService;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onReady() {
    super.onReady();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      unawaited(authenticate());
    });
  }

  Future<void> authenticate() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';

    final ok = await biometricService.authenticate(
      localizedReason: AppStrings.unlockWithBiometric.tr,
    );
    if (!ok) {
      isLoading.value = false;
      return;
    }

    final refreshed = await refreshLoginSessionUseCase();
    isLoading.value = false;

    if (!refreshed) {
      errorMessage.value = AppStrings.sessionExpiredPleaseLoginAgain.tr;
      AppDialogs.showErrorDialog(
        message: AppStrings.sessionExpiredPleaseLoginAgain.tr,
        onConfirm: openPinLogin,
      );
      return;
    }

    unawaited(analyticsService.logEvent('go_biometric_login_success'));
    await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
    Get.offAllNamed(AppRoutes.home);
  }

  void openPinLogin() {
    Get.offNamed(AppRoutes.pinLogin);
  }

  void cancelToPin() {
    openPinLogin();
  }
}
