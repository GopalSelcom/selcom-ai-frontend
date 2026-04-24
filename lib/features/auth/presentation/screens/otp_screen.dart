import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_otp_field.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends GetView<AuthController> {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Start the timer when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startResendTimer();
    });

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16.h),
                        // Back Button
                        AppBackButton(color: AppColors.textHeading, size: 28.w),
                        SizedBox(height: 32.h),

                        // Title
                        Text(
                          AppStrings.verifyPhoneNumber.tr,
                          style: AppTextStyles.onboardingTitle.copyWith(
                            fontSize: 24.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Subtitle
                        Text(
                          'Please enter the 4-digit code sent to \n${controller.countryCode} ${TanzaniaPhoneFormatter.formatString(controller.mobileNumber.value)} through SMS',
                          style: AppTextStyles.onboardingSubtitle,
                        ),
                        SizedBox(height: 16.h),

                        // Edit Phone Number
                        InkWell(
                          onTap: () => Get.back(),
                          child: Text(
                            AppStrings.editYourPhoneNumber.tr,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.info,
                              // Blue color as per generic design commonalities
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 48.h),

                        // OTP Input Field
                        Center(
                          child: Obx(
                            () => AppOtpField(
                              length: 4,
                              hasError: controller.errorMessage.isNotEmpty,
                              onChanged: (v) => controller.otp.value = v,
                              onCompleted: (v) async {
                                controller.otp.value = v;
                                await controller.verifyOtp();
                              },
                            ),
                          ),
                        ),
                        Obx(
                          () =>
                              controller.shouldShowGeneratedOtp &&
                                  controller.generatedOtp.value.isNotEmpty
                              ? Padding(
                                  padding: EdgeInsets.only(top: 8.h),
                                  child: Center(
                                    child: Text(
                                      'OTP: ${controller.generatedOtp.value}',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
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
                                      color: AppColors.textBody,
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
                                    style: AppTextStyles.onboardingSubtitle
                                        .copyWith(fontSize: 14.sp),
                                  ),
                                  SizedBox(height: 8.h),
                                  InkWell(
                                    onTap: () async =>
                                        await controller.resendOtp(),
                                    child: Text(
                                      AppStrings.resendCode.tr,
                                      style: AppTextStyles.onboardingButton
                                          .copyWith(
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

                        // Error Message
                        Obx(
                          () => controller.errorMessage.isNotEmpty
                              ? Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 12.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: AppColors.error.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppColors.error,
                                          size: 20.sp,
                                        ),
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
                              : const SizedBox.shrink(),
                        ),

                        // Verify Button
                        Obx(
                          () => AppPrimaryButton(
                            label: 'Verify',
                            isLoading: controller.isLoading.value,
                            onPressed: controller.otp.value.length == 4
                                ? () async {
                                    await controller.verifyOtp();
                                  }
                                : null,
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
