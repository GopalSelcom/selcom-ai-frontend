import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../controllers/splash_controller.dart';

/// Splash UI only — post-splash routing lives in [SplashController].
class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

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
