import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'authorization_token');

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
            bottom: -100.h,
            right: -100.w,
            child: Opacity(
              opacity: 0.35,
              child: SvgPicture.asset(
                AppAssets.splashBgVector,
                width: 500.w,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFCC0031),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          // Centered Logo
          Center(
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
