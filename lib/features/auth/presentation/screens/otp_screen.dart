import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../shared/widgets/app_otp_field.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends GetView<AuthController> {
  const OtpScreen({super.key});

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
                'Verification Code',
                style: AppTextStyles.onboardingTitle.copyWith(
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 12.h),

              // Subtitle
              Text(
                'Enter the 4-digit code sent to +255 ${controller.mobileNumber.value}',
                style: AppTextStyles.onboardingSubtitle,
              ),
              SizedBox(height: 48.h),

              // OTP Input Field
              Center(
                child: Obx(() => AppOtpField(
                  length: 4,
                  hasError: controller.errorMessage.isNotEmpty,
                  onChanged: (v) => controller.otp.value = v,
                  onCompleted: (v) async {
                    controller.otp.value = v;
                    await controller.verifyOtp();
                  },
                )),
              ),
              SizedBox(height: 32.h),

              // Resend Option
              Center(
                child: Obx(() {
                  if (controller.resendTimer.value > 0) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Haven't got the confirmation code yet? ",
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 13.sp,
                          ),
                        ),
                        Text(
                          "00:${controller.resendTimer.value.toString().padLeft(2, '0')}",
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Text(
                          "Didn't receive the code?",
                          style: AppTextStyles.onboardingSubtitle.copyWith(
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: () => controller.sendOtp(),
                          child: Text(
                            'Resend Code',
                            style: AppTextStyles.onboardingButton.copyWith(
                              color: AppColors.primary,
                              fontSize: 15.sp,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                }),
              ),

              const Spacer(),

              // Error Message (Figma: Alert Notification Main)
              Obx(() => controller.errorMessage.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: AppColors.error.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.error, size: 20.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                controller.errorMessage.value,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.error,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),

              // Verify Button
              Obx(() => InkWell(
                onTap: controller.otp.value.length == 4 && !controller.isLoading.value
                    ? () async {
                        await controller.verifyOtp();
                      }
                    : null,
                child: Container(
                  height: 54.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: controller.otp.value.length == 4
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: controller.otp.value.length == 4
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
                            'Verify',
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
