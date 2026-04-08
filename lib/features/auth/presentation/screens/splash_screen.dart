import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
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
    // For now, navigate to onboarding
    Get.offAllNamed(AppRoutes.onboarding);
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
                'assets/images/splash_bg_vector.svg',
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
              'assets/images/selcom_go_logo.svg',
              width: 180.w,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
