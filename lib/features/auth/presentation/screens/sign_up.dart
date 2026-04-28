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
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                style: AppTextStyles.onboardingTitle.copyWith(fontSize: 28.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                'Please enter your details to continue.',
                style: AppTextStyles.onboardingSubtitle,
              ),
              SizedBox(height: 24.h),
              Obx(
                () => Column(
                  children: [
                    AppTextField(
                      label: 'Full name',
                      hintText: 'Enter your full name',
                      controller: controller.nameController,
                      errorText: controller.submitted.value
                          ? controller.nameError
                          : null,
                      onChanged: controller.onNameChanged,
                    ),
                    SizedBox(height: 14.h),
                    AppTextField(
                      label: 'Email',
                      hintText: 'Enter your email (optional)',
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: controller.submitted.value
                          ? controller.emailError
                          : null,
                      onChanged: controller.onEmailChanged,
                    ),
                    SizedBox(height: 14.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: controller.acceptedTerms.value,
                          onChanged: (v) =>
                              controller.setAcceptedTerms(v == true),
                          activeColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: Text(
                              'I agree to the Terms and Conditions',
                              style: AppTextStyles.homeCaption.copyWith(
                                color: AppColors.textBody,
                                fontSize: 13.sp,
                              ),
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
              const Spacer(),
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
                        ),
                      ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
