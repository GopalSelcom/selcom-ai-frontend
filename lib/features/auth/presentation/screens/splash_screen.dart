import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';

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
    await Future.delayed(const Duration(milliseconds: 2500));

    // Check for existing valid session token
    final token = await StorageService().read(StorageKeys.authorizationToken);

    if (token != null && token.isNotEmpty) {
      Get.offAllNamed(AppRoutes.home);
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
            child: SvgPicture.asset(
              AppAssets.splashBgVector,
              width: 574.w,
              height: 576.h,
              colorFilter: const ColorFilter.mode(
                // Colors.white,
                Color(0xFFCC0031),
                BlendMode.srcIn,
              ),
            ),
          ),
          // Centered Logo
          Positioned(
            left: 0,
            right: 0,
            top: 300.h,
            child: SvgPicture.asset(
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
