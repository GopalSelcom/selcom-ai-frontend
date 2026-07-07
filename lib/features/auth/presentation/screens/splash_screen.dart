import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/voip_callkit_bridge_service.dart';
import '../../../../core/services/local_bank_instructions_service.dart';
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

  void _navigateToNext() async {
    // Preload app settings in the background. Do not await: a slow or hung
    // settings API (or DNS / connectivity checks in ApiService) would block
    // leaving the user on the splash screen.
    unawaited(sl<AppSettingsService>().preload());
    unawaited(sl<LocalBankInstructionsService>().fetchInstructions());
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final token = await StorageService().readAccessToken();
    final userJson = await StorageService().read(StorageKeys.user);

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
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
