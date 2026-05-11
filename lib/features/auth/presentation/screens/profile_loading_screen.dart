import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';

class ProfileLoadingScreen extends StatefulWidget {
  const ProfileLoadingScreen({super.key});

  @override
  State<ProfileLoadingScreen> createState() => _ProfileLoadingScreenState();
}

class _ProfileLoadingScreenState extends State<ProfileLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..forward().then((_) {
            if (!mounted) return;
            if (Get.isRegistered<AuthController>()) {
              Get.find<AuthController>().completeProfileLoading();
            } else {
              Get.offAllNamed(AppRoutes.home);
            }
          });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.loadingYourProfile.tr,
              style: AppTextStyles.onboardingTitle.copyWith(
                fontSize: 28.sp,
                color: AppColors.textHeading,
                height: 34 / 28,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              width: 311.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: AppColors.progressTrack,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return UnconstrainedBox(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 311.w * _progressController.value,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 4,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
