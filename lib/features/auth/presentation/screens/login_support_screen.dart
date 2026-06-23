import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/app_animated_reveal.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/phone_country_picker_chip.dart';
import '../controllers/login_support_controller.dart';
import '../widgets/login_support_screen_shimmer.dart';

class LoginSupportScreen extends GetView<LoginSupportController> {
  const LoginSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS ? 0 : 8.h)
        : 16.h;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppProfileHeader(title: AppStrings.contactSupport.tr),
          SizedBox(height: 16.h),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.reasons.isEmpty) {
                return SingleChildScrollView(
                  child: LoginSupportScreenShimmer.formContent(),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.fullName.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      AppTextField(
                        controller: controller.nameController,
                        hintText: AppStrings.enterYourFullName.tr,
                        keyboardType: TextInputType.name,
                        onChanged: controller.onFieldChanged,
                        textColor: AppColors.textHeading,
                        textFieldBackgroundColor: AppColors.surfaceSubtle,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.enterYourEmail.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      AppTextField(
                        controller: controller.emailController,
                        hintText: AppStrings.enterYourEmail.tr,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: controller.onFieldChanged,
                        textColor: AppColors.textHeading,
                        textFieldBackgroundColor: AppColors.surfaceSubtle,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.phoneNumber.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      Obx(() {
                        final iso = controller.selectedCountryIso.value;
                        final resetV = controller.phoneFieldResetVersion.value;
                        return AppTextField(
                          key: ValueKey('login-support-phone-$iso-$resetV'),
                          controller: controller.phoneController,
                          hintText: PhoneNationalRules.hintForIso(iso),
                          keyboardType: TextInputType.phone,
                          inputFormatters:
                              PhoneNationalRules.inputFormattersForIso(iso),
                          prefixIcon: Container(
                            padding: EdgeInsets.only(left: 12.w, right: 2.w),
                            child: PhoneCountryPickerChip(
                              inline: true,
                              selected: controller.selectedCountry,
                              onChanged: controller.onPhoneCountrySelected,
                            ),
                          ),
                          onChanged: controller.onFieldChanged,
                          textColor: AppColors.textHeading,
                          textFieldBackgroundColor: AppColors.surfaceSubtle,
                        );
                      }),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.reasonToContact.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      _buildReasonDropdown(),
                      SizedBox(height: 16.h),
                      Text(
                        AppStrings.message.tr,
                        style: AppTextStyles.homeSubtitle,
                      ),
                      SizedBox(height: 8.h),
                      AppTextField(
                        controller: controller.messageController,
                        hintText: AppStrings.howCanWeHelpYou.tr,
                        maxLines: 5,
                        onChanged: controller.onFieldChanged,
                        textColor: AppColors.textHeading,
                        textFieldBackgroundColor: AppColors.surfaceSubtle,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          SafeArea(
            top: false,
            bottom: true,
            child: Obx(
              () => Padding(
                padding: EdgeInsets.only(
                  bottom: controller.canSubmit.value
                      ? computedBottomPadding
                      : 0,
                  left: 24.w,
                  right: 24.w,
                ),
                child: AppAnimatedReveal(
                  show: controller.canSubmit.value,
                  visibleKey: const ValueKey('login-support-submit-visible'),
                  hiddenKey: const ValueKey('login-support-submit-hidden'),
                  child: AppPrimaryButton(
                    label: AppStrings.submit.tr,
                    onPressed: controller.submitTicket,
                    isLoading: controller.isSubmitting.value,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonDropdown() {
    return GestureDetector(
      onTap: controller.openReasonPicker,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => Text(
                  controller.reasonDisplayText,
                  style: AppTextStyles.body.copyWith(
                    color: controller.selectedReasonValue.value.isEmpty
                        ? AppColors.textBody
                        : AppColors.textHeading,
                  ),
                ),
              ),
            ),
            const Icon(
              Iconsax.arrow_down_1,
              color: AppColors.textHeading,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
