import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/network/certificate_pinning.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import 'auth_controller.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited(_navigateAfterSplash());
  }

  /// True when auth interceptor / session coordinator already invalidated login.
  ///
  /// Splash must not route to Home in this state — otherwise authenticated
  /// background work or navigation can race the session-expired dialog.
  bool _isSessionAlreadyInvalidated() {
    return SessionExpiryService.isHandling ||
        AuthInterceptor.isLoggingOutDueToAuthFailure;
  }

  Future<void> _navigateAfterSplash() async {
    // Fetch SPKI pin and attach pinned HttpClient to Dio before API traffic.
    await CertificatePinning.instance.init();
    ApiService().applyCertificatePinning();

    unawaited(sl<AppSettingsService>().preload());
    await Future.delayed(const Duration(milliseconds: 2500));

    if (isClosed) return;
    if (_isSessionAlreadyInvalidated()) return;

    final token = await StorageService().readAccessToken();
    final userJson = await StorageService().read(StorageKeys.user);

    if (isClosed) return;
    if (_isSessionAlreadyInvalidated()) return;

    if (token != null && token.isNotEmpty) {
      await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
      if (isClosed || _isSessionAlreadyInvalidated()) return;

      if (AuthController.userNeedsPhone(userJson)) {
        NotificationService().clearPendingNavigation();
        Get.offAllNamed(AppRoutes.phone);
      } else {
        Get.offAllNamed(AppRoutes.home);
        // Push taps queued during splash must run *after* Home replaces the
        // stack — otherwise splash offAllNamed would wipe the destination.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(NotificationService().flushPendingNavigationIfAny());
        });
      }
      return;
    }

    NotificationService().clearPendingNavigation();
    Get.offAllNamed(AppRoutes.onboarding);
  }
}