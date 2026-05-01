import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_otp_field.dart';
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
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.h),
                        AppBackButton(
                          color: AppColors.textHeading,
                          showOnlyWhenCanPop: false,
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Get.back();
                            }
                          },
                        ),
                        SizedBox(height: 17.h),

                        // Title
                        Text(
                          AppStrings.verifyPhoneNumber.tr,
                          style: AppTextStyles.onboardingTitle.copyWith(
                            fontSize: 28.sp,
                            height: 34 / 28,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Subtitle
                        Text(
                          'Please enter the 4-digit code sent to \n${controller.countryCode} ${TanzaniaPhoneFormatter.formatString(controller.mobileNumber.value)} through SMS',
                          style: AppTextStyles.homeSubtitle.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBody,
                            height: 20 / 15,
                          ),
                        ),
                        SizedBox(height: 18.h),

                        // Edit Phone Number
                        InkWell(
                          onTap: () => Get.back(),
                          child: Text(
                            AppStrings.editYourPhoneNumber.tr,
                            style: AppTextStyles.homeSubtitle.copyWith(
                              fontSize: 17.sp,
                              color: AppColors.figmaInputBlue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                              height: 22 / 17,
                            ),
                          ),
                        ),
                        SizedBox(height: 42.h),

                        // OTP Input Field
                        Center(
                          child: Obx(
                            () => AppOtpField(
                              length: 4,
                              fieldHeight: 70.h,
                              fieldWidth: 64.w,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              hasError: controller.errorMessage.isNotEmpty,
                              textStyle: AppTextStyles.body.copyWith(
                                fontFamily: AppTextStyles.metropolisFont,
                                fontSize: 34.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.figmaInputBlue,
                                height: 41 / 34,
                                letterSpacing: -0.4,
                              ),
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
                        SizedBox(height: 56.h),

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
                                      fontSize: 30.sp / 2,
                                      fontWeight: FontWeight.w500,
                                      height: 20 / 15,
                                    ),
                                  ),
                                  Text(
                                    "00:${controller.resendTimer.value.toString().padLeft(2, '0')}",
                                    style: AppTextStyles.onboardingFooter
                                        .copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.sp,
                                          height: 18 / 13,
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

                        // Error Message
                        Obx(
                          () => controller.errorMessage.isNotEmpty
                              ? Padding(
                                  padding: EdgeInsets.only(top: 12.h),
                                  child: Center(
                                    child: Text(
                                      controller.errorMessage.value,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.error,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const Spacer(),
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
