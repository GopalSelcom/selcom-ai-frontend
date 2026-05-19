import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/login_pin_gate_service.dart';
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

    if (!mounted) return;

    // Cold start: session → pin-login, biometric-unlock, pin-setup, or home ([LoginPinGateService]).
    final gate = sl<LoginPinGateService>();
    final hasSession = await gate.hasStoredSession();

    if (hasSession) {
      await VoipCallkitBridgeService.instance.syncCachedTokenToBackend();
      final nextRoute = await gate.resolveColdStartRoute();
      if (!mounted) return;

      if (nextRoute == AppRoutes.pinSetup) {
        Get.offAllNamed(
          AppRoutes.pinSetup,
          arguments: {
            'mode': 'setup',
            'nextRoute': AppRoutes.home,
          },
        );
        return;
      }

      Get.offAllNamed(nextRoute);
      return;
    }

    Get.offAllNamed(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        children: [
          // Background Vector Decoration
          Positioned(
            bottom: -175.h,
            right: -225.w,
            child: SvgPictureAsset(
              AppAssets.splashBgVector,
              width: 574.w,
              height: 576.h,
            ),
          ),
          // Centered Logo
          Positioned(
            left: 0,
            right: 0,
            top: 300.h,
            child: SvgPictureAsset(
              AppAssets.selcomGoLogo,
              width: 180.w,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
