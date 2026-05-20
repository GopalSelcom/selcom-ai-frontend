import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/data/countries_phone_data.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/widgets/app_focus_input_field.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/phone_country_picker_chip.dart';
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
                        SizedBox(height: 103.h - kToolbarHeight),

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

                        Obx(() {
                          final iso = controller.selectedCountryIso.value;
                          final resetV =
                              controller.phoneFieldResetVersion.value;
                          final hint = PhoneNationalRules.hintForIso(iso);
                          final country = Countries.findByIsoCode(iso);

                          final phoneFieldStyle = TextStyle(
                            fontFamily: AppTextStyles.metropolisFont,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                            height: 1.2,
                            letterSpacing: -0.16,
                            color: AppColors.primary,
                          );

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              PhoneCountryPickerChip(
                                key: ValueKey('cc-$iso'),
                                selected: country,
                                onChanged: controller.onPhoneCountrySelected,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: AppFocusInputField(
                                  key: ValueKey('$iso-$resetV'),
                                  height: 54.h,
                                  focusedBorderColor: AppColors.primary,
                                  keyboardType: TextInputType.number,
                                  inputFormatters:
                                      PhoneNationalRules.inputFormattersForIso(
                                        iso,
                                      ),
                                  style: phoneFieldStyle,
                                  maxLength:
                                      PhoneNationalRules.maxDisplayCharactersForIso(
                                        iso,
                                      ),
                                  onChanged: (v) {
                                    controller.mobileNumber.value = v
                                        .replaceAll(RegExp(r'\D'), '');
                                  },
                                  hintText: hint.isEmpty
                                      ? AppStrings.eG7XxXxxXxx.tr
                                      : hint,
                                  hintStyle: phoneFieldStyle.copyWith(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 16.h,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

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
                          () => AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            switchInCurve: Curves.easeOutQuart,
                            switchOutCurve: Curves.easeInOutCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axis: Axis.vertical,
                                  child: child,
                                ),
                              );
                            },
                            child: controller.canRequestOtp
                                ? AppPrimaryButton(
                                    key: const ValueKey('otp-button-visible'),
                                    label: AppStrings.getVerificationCode.tr,
                                    isLoading: controller.isLoading.value,
                                    onPressed: controller.sendOtpAndNavigate,
                                    showBottomInnerShadow: true,
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('otp-button-hidden'),
                                  ),
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
