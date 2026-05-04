import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_focus_input_field.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/auth_controller.dart';

class PhoneInputScreen extends GetView<AuthController> {
  const PhoneInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          AppStrings.enterPhoneNumberForVerification.tr,
                          style: AppTextStyles.onboardingTitle.copyWith(
                            fontSize: 28.sp,
                            height: 34 / 28,
                            letterSpacing: -0.4,
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // Subtitle
                        Text(
                          AppStrings.weLlTextACodeToVerifyYourPhoneNumber.tr,
                          style: AppTextStyles.homeSubtitle.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBody,
                            height: 20 / 15,
                          ),
                        ),

                        SizedBox(height: 22.h),

                        // Phone Input Field
                        Row(
                          children: [
                            // Country Selector
                            Container(
                              height: 54.h,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                border: Border.all(
                                  color: AppColors.borderDefault,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowSoft,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3.r),
                                    child: SvgPictureAsset(
                                      AppAssets.icTanzaniaFlag,
                                      height: 15.h,
                                      width: 23.w,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    AppStrings.value255.tr,
                                    style: AppTextStyles.body.copyWith(
                                      fontFamily: AppTextStyles.metropolisFont,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textHeading,
                                      fontSize: 17.sp,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20.sp,
                                    color: AppColors.textBody,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.w),

                            // Number Input
                            Expanded(
                              child: AppFocusInputField(
                                height: 54.h,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  TanzaniaPhoneFormatter(),
                                ],
                                style: AppTextStyles.body.copyWith(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: AppColors.figmaInputBlue,
                                  letterSpacing: -0.16,
                                ),
                                maxLength: 11,
                                onChanged: (v) {
                                  controller.mobileNumber.value = v.replaceAll(
                                    ' ',
                                    '',
                                  );
                                },
                                hintText: AppStrings.eG7XxXxxXxx.tr,
                                hintStyle: AppTextStyles.hint.copyWith(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16.sp,
                                  color: AppColors.figmaInputBlue,
                                  letterSpacing: -0.16,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 16.h,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12.h),

                        // Email Input Field
                        Row(
                          children: [
                            Container(
                              height: 56.h,
                              width: 115.w,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                border: Border.all(
                                  color: AppColors.borderDefault,
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowSoft,
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  SvgPictureAsset(
                                    AppAssets.icSms,
                                    height: 24.h,
                                    width: 24.w,
                                    color: AppColors.textHeading,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Email',
                                    style: AppTextStyles.body.copyWith(
                                      fontFamily: AppTextStyles.metropolisFont,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 17.sp,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                  const Spacer(),
                                  Transform.rotate(
                                    angle: -1.5708,
                                    child: Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 12.sp,
                                      color: AppColors.textBody,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: AppFocusInputField(
                                height: 56.h,
                                keyboardType: TextInputType.emailAddress,
                                style: AppTextStyles.body.copyWith(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.sp,
                                  color: AppColors.figmaInputBlue,
                                  letterSpacing: -0.16,
                                ),
                                onChanged: controller.onEmailChanged,
                                hintText: AppStrings.eGNameEmailComOptional.tr,
                                hintStyle: AppTextStyles.hint.copyWith(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16.sp,
                                  color: AppColors.figmaInputBlue,
                                  letterSpacing: -0.16,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 16.h,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Error Message
                        Obx(
                          () => controller.errorMessage.isNotEmpty
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
                              : const SizedBox.shrink(),
                        ),

                        const Spacer(),

                        // Legal Note
                        Padding(
                          padding: EdgeInsets.only(bottom: 14.h),
                          child: Text(
                            AppStrings
                                .noteByProceedingYouConsentToGetCallsWhatsappOrSmsMessagesIncludingByAu
                                .tr,
                            style: AppTextStyles.homeCaption.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textBody,
                              height: 20 / 12,
                            ),
                          ),
                        ),

                        // Button
                        Obx(
                          () => AppPrimaryButton(
                            label: 'Get Verification Code',
                            isLoading: controller.isLoading.value,
                            onPressed: controller.canRequestOtp
                                ? controller.sendOtpAndNavigate
                                : null,
                          ),
                        ),

                        SizedBox(height: 12.h),
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
