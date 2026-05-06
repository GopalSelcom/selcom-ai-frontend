import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../controllers/payment_methods_controller.dart';

class SelcomPesaOtpBottomSheet extends GetView<PaymentMethodsController> {
  const SelcomPesaOtpBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Pin theme for Pinput
    final defaultPinTheme = PinTheme(
      width: 50.w,
      height: 56.h,
      textStyle: AppTextStyles.body.copyWith(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textHeading,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.borderWalletCard),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.error),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 64.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.dividerHandle,
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          Text(
            AppStrings.enterOtp.tr,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          SizedBox(height: 8.h),

          Text(
            'OTP Sent to your ${TanzaniaPhoneFormatter.formatInternational(controller.selcomPhoneController.text)} phone number',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textBody,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: AppColors.divider, thickness: 1),
          SizedBox(height: 32.h),

          // OTP Input (Pinput)
          Obx(
            () => Pinput(
              length: 6,
              controller: controller.otpController,
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              errorPinTheme: errorPinTheme,
              forceErrorState: controller.otpError.isNotEmpty,
              errorText: controller.otpError.value,
              errorTextStyle: AppTextStyles.body.copyWith(
                color: AppColors.error,
                fontSize: 13.sp,
              ),
              onCompleted: controller.onOtpComplete,
              onChanged: (_) => controller.otpError.value = '',
              showCursor: true,
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(width: 2.w, height: 24.h, color: AppColors.primary),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // Timer and Change Phone Number
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  if (controller.resendTimer.value > 0) {
                    return Text(
                      '0:${controller.resendTimer.value.toString().padLeft(2, '0')}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  } else {
                    return InkWell(
                      onTap: controller.resendOtp,
                      child: Text(
                        AppStrings.resendOtp.tr,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                }),
                InkWell(
                  onTap: controller.openPhoneInput,
                  child: Text(
                    AppStrings.changePhoneNumber.tr,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),
          // Note: No Continue button as per user request (automatically completes on 6 digits)
        ],
      ),
    );
  }
}
