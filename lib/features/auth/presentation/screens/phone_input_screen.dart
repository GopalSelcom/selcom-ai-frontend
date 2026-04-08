import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class PhoneInputScreen extends GetView<AuthController> {
  const PhoneInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              // Back Button
              InkWell(
                onTap: () => Get.back(),
                child: SvgPicture.asset(
                  'assets/images/ic_arrow_left.svg',
                  height: 28.h,
                  width: 28.w,
                ),
              ),
              SizedBox(height: 32.h),

              // Title
              Text(
                'Enter Phone number for verification',
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 24.sp, // Adjusting slightly for fit if needed
                ),
              ),
              SizedBox(height: 12.h),

              // Subtitle
              Text(
                'We’ll text a code to verify your phone number',
                style: AppTextStyles.onboardingSubtitle,
              ),
              SizedBox(height: 48.h),

              // Phone Input Field
              Row(
                children: [
                  // Country Selector
                  Container(
                    height: 56.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3.r),
                          child: SvgPicture.asset(
                            'assets/images/ic_tanzania_flag.svg',
                            height: 20.h,
                            width: 28.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          '+255',
                          style: AppTextStyles.body.copyWith(
                            fontFamily: AppTextStyles.metropolisFont,
                            fontWeight: FontWeight.w600,
                            color: AppColors.shade1,
                            fontSize: 16.sp,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20.sp,
                          color: AppColors.shade2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Number Input
                  Expanded(
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.body.copyWith(
                          fontFamily: AppTextStyles.metropolisFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 18.sp,
                          color: AppColors.shade1,
                          letterSpacing: 1.2,
                        ),
                        maxLength: 11, // To allow spaces (XXX XXX XXX)
                        onChanged: (v) {
                          // Allow only 9 digits total
                          final digits = v.replaceAll(' ', '');
                          if (digits.length <= 9) {
                            controller.mobileNumber.value = digits;
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '711 410 410',
                          counterText: "",
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textLight,
                            fontFamily: AppTextStyles.metropolisFont,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Email Input Field
              Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 16.w),
                    SvgPicture.asset(
                      'assets/images/ic_sms.svg',
                      height: 20.h,
                      width: 20.w,
                      colorFilter: const ColorFilter.mode(AppColors.shade2, BlendMode.srcIn),
                    ),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.body.copyWith(
                          fontFamily: AppTextStyles.metropolisFont,
                          fontWeight: FontWeight.w500,
                          fontSize: 16.sp,
                          color: AppColors.shade1,
                        ),
                        onChanged: (v) => controller.email.value = v,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textLight,
                            fontFamily: AppTextStyles.metropolisFont,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Error Message
              Obx(() => controller.errorMessage.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14.sp,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),

              // Legal Note
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Text(
                  'Note: By proceeding, you consent to get calls, WhatsApp or SMS messages, including by automated means, from GoChauffeur and its affiliates to the number provided.',
                  style: AppTextStyles.onboardingFooter.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.shade2.withOpacity(0.7),
                  ),
                ),
              ),

              // Action Button
              Obx(() => InkWell(
                onTap: controller.mobileNumber.value.length >= 9 && !controller.isLoading.value
                    ? () async {
                        final success = await controller.sendOtp();
                        if (success) {
                          Get.toNamed(AppRoutes.otp);
                        }
                      }
                    : null,
                child: Container(
                  height: 54.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: controller.mobileNumber.value.length >= 9
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: controller.mobileNumber.value.length >= 9
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 24.h,
                            width: 24.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Get Verification Code',
                            style: AppTextStyles.onboardingButton,
                          ),
                  ),
                ),
              )),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
