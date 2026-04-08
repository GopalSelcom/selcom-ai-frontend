import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';

class ProfileLoadingScreen extends StatefulWidget {
  const ProfileLoadingScreen({super.key});

  @override
  State<ProfileLoadingScreen> createState() => _ProfileLoadingScreenState();
}

class _ProfileLoadingScreenState extends State<ProfileLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward().then((_) {
        setState(() {
          _isSuccess = true;
        });
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
      body: Stack(
        children: [
          // Loading View
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Loading your profile...',
                  style: AppTextStyles.onboardingTitle.copyWith(
                    fontSize: 28.sp,
                    color: const Color(0xFF132235),
                  ),
                ),
                SizedBox(height: 24.h),
                // Custom Animated Progress Bar
                Container(
                  width: 311.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE1E8),
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
                            borderRadius: BorderRadius.circular(5.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
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

          // Success Overlay (Success Modal)
          if (_isSuccess)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Center(
                    child: Container(
                      width: 327.w,
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF242E49).withOpacity(0.05),
                            blurRadius: 21,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Success Illustration
                          Container(
                            height: 200.h,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F5F9),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: SvgPicture.asset(
                              'assets/images/ic_verification_success.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          
                          // Text Content
                          Text(
                            'Verification Successfully',
                            style: AppTextStyles.onboardingTitle.copyWith(
                              fontSize: 24.sp,
                              color: const Color(0xFF132235),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Face scan process has been successful',
                            style: AppTextStyles.onboardingSubtitle.copyWith(
                              fontSize: 15.sp,
                              color: const Color(0xFF364B63),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32.h),

                          // Done Button
                          InkWell(
                            onTap: () => Get.offAllNamed(AppRoutes.home),
                            child: Container(
                              height: 54.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Done',
                                    style: AppTextStyles.onboardingButton.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                      fontFamily: 'Plus Jakarta Sans', // Based on Figma
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  SvgPicture.asset(
                                    'assets/images/ic_tick_circle.svg',
                                    height: 24.h,
                                    width: 24.w,
                                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
