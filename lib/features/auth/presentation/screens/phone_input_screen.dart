import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class PhoneInputScreen extends StatelessWidget {
  const PhoneInputScreen({super.key});

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
                'Enter Phone Number',
                style: AppTextStyles.screenTitle,
              ),
              SizedBox(height: 12.h),
              Text(
                'We will send a 4-digit code to verify your phone number.',
                style: AppTextStyles.body,
              ),
              SizedBox(height: 48.h),
              Row(
                children: [
                  Container(
                    height: 56.h,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorderDefault),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: Text(
                        '+255',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppTextField(
                      hintText: '712 345 678',
                      keyboardType: TextInputType.phone,
                      onChanged: (v) => controller.mobileNumber.value = v,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Obx(() => controller.errorMessage.isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Text(
                        controller.errorMessage.value,
                        style: TextStyle(color: AppColors.error, fontSize: 14.sp),
                      ),
                    )
                  : const SizedBox.shrink()),
              Obx(() => AppPrimaryButton(
                    label: 'Get Verification Code',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.mobileNumber.value.length >= 9
                        ? () async {
                            final success = await controller.sendOtp();
                            if (success) {
                              Get.toNamed(AppRoutes.otp);
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
