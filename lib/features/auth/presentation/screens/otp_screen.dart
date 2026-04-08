import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_otp_field.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  AuthController get controller => Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                'Verification Code',
                style: AppTextStyles.screenTitle,
              ),
              SizedBox(height: 12.h),
              Text(
                'Enter the 4-digit code sent to +255 ${controller.mobileNumber.value}',
                style: AppTextStyles.body,
              ),
              SizedBox(height: 48.h),
              Center(
                child: AppOtpField(
                  length: 4,
                  onChanged: (v) => controller.otp.value = v,
                  onCompleted: (v) async {
                    controller.otp.value = v;
                    final success = await controller.verifyOtp();
                    if (success) {
                      Get.offAllNamed(AppRoutes.home);
                    }
                  },
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: TextButton(
                  onPressed: () => controller.sendOtp(),
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Obx(() => controller.errorMessage.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Center(
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(color: AppColors.error, fontSize: 14.sp),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
              Obx(() => AppPrimaryButton(
                    label: 'Verify',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.otp.value.length == 4
                        ? () async {
                            final success = await controller.verifyOtp();
                            if (success) {
                              Get.offAllNamed(AppRoutes.home);
                            }
                          }
                        : null,
                  )),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
