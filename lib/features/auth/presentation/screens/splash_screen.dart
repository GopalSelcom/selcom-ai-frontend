import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/session_expiry_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  /// True when auth interceptor / session coordinator already invalidated login.
  ///
  /// Splash must not route to Home in this state — otherwise authenticated
  /// background work or navigation can race the session-expired dialog.
  bool _isSessionAlreadyInvalidated() {
    return SessionExpiryService.isHandling ||
        AuthInterceptor.isLoggingOutDueToAuthFailure;
  }

  void _navigateToNext() async {
    // Warm public app settings during splash (no auth required).
    unawaited(sl<AppSettingsService>().preload());
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // A background request may have expired the session during the splash delay.
    if (_isSessionAlreadyInvalidated()) return;

    final token = await StorageService().readAccessToken();
    final userJson = await StorageService().read(StorageKeys.user);

    if (!mounted) return;

    // Re-check after async storage reads — avoids racing with 401 handling.
    if (_isSessionAlreadyInvalidated()) return;

    if (token != null && token.isNotEmpty) {
      await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
      if (!mounted || _isSessionAlreadyInvalidated()) return;

      if (AuthController.userNeedsPhone(userJson)) {
        // Resume phone attach after a prior SSO + firebase_login session.
        Get.offAllNamed(AppRoutes.phone);
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SizedBox.expand(
        child: SvgPictureAsset(AppAssets.splashScreenBg, fit: BoxFit.cover),
      ),
    );
  }
}
