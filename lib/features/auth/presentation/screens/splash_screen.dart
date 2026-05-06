import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/storage_service.dart';
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
    // Preload app-level settings/features once at startup.
    await sl<AppSettingsService>().preload();
    await Future.delayed(const Duration(milliseconds: 2500));

    // Check for existing valid session token
    final token = await StorageService().read(StorageKeys.authorizationToken);
    final signupCompleted =
        await StorageService().read(StorageKeys.signupCompleted);

    if (token != null && token.isNotEmpty) {
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
    return Scaffold(
      backgroundColor: AppColors.primary,
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
              color: AppColors.splashVectorTint,
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
