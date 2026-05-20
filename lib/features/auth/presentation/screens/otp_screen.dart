import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_otp_field.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends GetView<AuthController> {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double otpContentMaxWidth = 304.w;

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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppBackButton(
                              alignToParent: false,
                              alignIconToStart: true,
                              color: AppColors.textHeading,
                              showOnlyWhenCanPop: false,
                              size: 30.w,
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Get.back();
                                }
                              },
                            ),
                            SizedBox(height: 13.h),
                            Text(
                              AppStrings.verifyPhoneNumber.tr,
                              style: AppTextStyles.onboardingTitle,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),

                        // Subtitle
                        Text(
                          AppStrings
                              .pleaseEnterThe4DigitCodeSentToPhoneThroughSms
                              .trParams({
                                'countryCode': controller.countryCode.value,
                                'phoneNumber':
                                    TanzaniaPhoneFormatter.formatString(
                                      controller.mobileNumber.value,
                                    ),
                              }),
                          style: AppTextStyles.onboardingSubtitle,
                        ),
                        SizedBox(height: 24.h),

                        // Edit Phone Number (Cupertino text button; 15sp per Figma subtitle scale)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: () => Get.back(),
                          child: Text(
                            AppStrings.editYourPhoneNumber.tr,
                            style: AppTextStyles.onboardingSubtitle.copyWith(
                              fontSize: 16.sp,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                              decorationThickness: 1,
                              decorationStyle: TextDecorationStyle.solid,
                              height: 22 / 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 43.h),

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
                                color: AppColors.textHeading,
                                height: 41 / 34,
                                letterSpacing: -0.4,
                              ),
                              onChanged: controller.onOtpChanged,
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
                                      '${AppStrings.otpLabel.tr}: ${controller.generatedOtp.value}',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        // Error Message
                        Obx(
                          () => controller.errorMessage.isNotEmpty
                              ? Padding(
                                  padding: EdgeInsets.only(top: 12.h),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: otpContentMaxWidth,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(12.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.otpErrorBackground,
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          border: Border.all(
                                            color: AppColors.otpErrorBorder,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SvgPictureAsset(
                                              AppAssets.icError,
                                              width: 20.w,
                                              height: 20.w,
                                              color: AppColors.otpErrorBorder,
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                controller.errorMessage.value,
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                      color:
                                                          AppColors.textHeading,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      height: 1,
                                                      letterSpacing: -0.14,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const Spacer(),

                        Obx(() {
                          if (controller.resendTimer.value > 0) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.haventGotTheConfirmationCodeYet.tr,
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
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.didntReceiveTheCode.tr,
                                style: AppTextStyles.onboardingSubtitle
                                    .copyWith(fontSize: 14.sp),
                              ),
                              SizedBox(width: 8.h),
                              InkWell(
                                onTap: () async => await controller.resendOtp(),
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
                        }),

                        SizedBox(height: 18.h),
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
