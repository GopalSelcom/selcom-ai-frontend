import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/svg_picture_asset.dart';

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

  void _navigateToNext() async {
    // Preload app settings in the background. Do not await: a slow or hung
    // settings API (or DNS / connectivity checks in ApiService) would block
    // leaving the user on the splash screen.
    unawaited(sl<AppSettingsService>().preload());
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check for existing valid session token
    final token = await StorageService().read(StorageKeys.authorizationToken);
    final signupCompleted = await StorageService().read(
      StorageKeys.signupCompleted,
    );

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
      if (signupCompleted == 'false') {
        Get.offAllNamed(AppRoutes.phone);
      } else {
        // For existing logged-in users where this flag may be absent,
        // default to home to preserve prior behavior.
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
        child: SvgPictureAsset(
          AppAssets.splashScreenBg,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
