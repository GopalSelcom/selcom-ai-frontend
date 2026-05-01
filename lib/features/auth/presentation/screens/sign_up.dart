import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/sign_up_controller.dart';

class SignUpScreen extends GetView<SignUpController> {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          bottom: bottomInset > 0 ? bottomInset + 12.h : 16.h,
          top: 8.h,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => AppPrimaryButton(
                  label: 'Submit',
                  isLoading: controller.isLoading.value,
                  onPressed: controller.canSubmit
                      ? controller.submitAdditionalDetails
                      : null,
                ),
              ),
              Obx(
                () => controller.errorMessage.value.trim().isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Text(
                          controller.errorMessage.value,
                          style: AppTextStyles.homeCaption.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 140.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                Center(
                  child: SvgPicture.asset(
                    AppAssets.selcomGoLogo,
                    width: 154.w,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 28.h),
                Text(
                  'Welcome to Selcom Go',
                  style: AppTextStyles.onboardingTitle.copyWith(
                    fontSize: 28.sp,
                    height: 34 / 28,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Please enter your details to continue.',
                  style: AppTextStyles.homeSubtitle.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                    height: 20 / 15,
                  ),
                ),
                SizedBox(height: 24.h),
                Obx(
                  () => Column(
                    children: [
                      AppTextField(
                        enableEnhancedStyle: true,
                        label: 'Full name',
                        hintText: 'Enter your full name',
                        controller: controller.nameController,
                        textColor: AppColors.figmaInputBlue,
                        errorText: controller.submitted.value
                            ? controller.nameError
                            : null,
                        onChanged: controller.onNameChanged,
                      ),
                      SizedBox(height: 14.h),
                      AppTextField(
                        enableEnhancedStyle: true,
                        label: 'Email',
                        hintText: 'Enter your email (optional)',
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        textColor: AppColors.figmaInputBlue,
                        errorText:
                            controller.emailController.text.trim().isNotEmpty
                            ? controller.emailError
                            : null,
                        onChanged: controller.onEmailChanged,
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, 0),
                            child: Checkbox(
                              value: controller.acceptedTerms.value,
                              onChanged: (v) =>
                                  controller.setAcceptedTerms(v == true),
                              activeColor: AppColors.primary,
                              checkColor: AppColors.white,
                              side: BorderSide(
                                color: AppColors.textBody.withValues(
                                  alpha: 0.7,
                                ),
                                width: 1.5.w,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'I agree to the Terms and Conditions',
                              style: AppTextStyles.homeCaption.copyWith(
                                color: AppColors.textBody,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (controller.submitted.value &&
                          !controller.acceptedTerms.value)
                        Padding(
                          padding: EdgeInsets.only(left: 12.w, top: 4.h),
                          child: Text(
                            'Please accept Terms and Conditions',
                            style: AppTextStyles.homeCaption.copyWith(
                              color: AppColors.error,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
