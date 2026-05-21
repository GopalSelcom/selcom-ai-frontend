import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/payment_methods_controller.dart';

class SelcomPesaFlowBottomSheet extends GetView<PaymentMethodsController> {
  const SelcomPesaFlowBottomSheet({super.key});

  static Future<void> show() {
    return AppDialogs.showStandardBottomSheet<void>(
      sheet: const SelcomPesaFlowBottomSheet(),
      barrierDismissible: true,
    );
  }

  static String _titleForStep(SelcomPesaStep step) {
    switch (step) {
      case SelcomPesaStep.connect:
        return AppStrings.stepsToConnectSelcomPesa.tr;
      case SelcomPesaStep.phoneInput:
        return AppStrings.enterYourSelcomPesaNumber.tr;
      case SelcomPesaStep.otp:
        return AppStrings.enterOtp.tr;
      case SelcomPesaStep.selfie:
        return AppStrings.verifyYourSelfie.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double computedBottomPadding = bottomPadding > 0
        ? (GetPlatform.isIOS
              ? (bottomPadding - 12.h).clamp(
                  10.h > bottomPadding ? bottomPadding : 10.h,
                  bottomPadding,
                )
              : bottomPadding + 12.h)
        : 12.h;
    return Obx(
      () => AppStandardBottomSheet(
        title: _titleForStep(controller.selcomPesaStep.value),
        headerTextAlign: TextAlign.start,
        showHeaderDivider: true,
        maxHeightFactor: 0.92,
        content: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offsetAnimation, child: child),
              );
            },
            child: Column(
              children: [
                _buildStepContent(context, controller.selcomPesaStep.value),
                SizedBox(height: computedBottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, SelcomPesaStep step) {
    switch (step) {
      case SelcomPesaStep.connect:
        return _buildConnectStep(context);
      case SelcomPesaStep.phoneInput:
        return _buildPhoneInputStep(context);
      case SelcomPesaStep.otp:
        return _buildOtpStep(context);
      case SelcomPesaStep.selfie:
        return _buildSelfieStep(context);
    }
  }

  Widget _buildConnectStep(BuildContext context) {
    return Column(
      key: const ValueKey(SelcomPesaStep.connect),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepper(),

        SizedBox(height: 14.h),

        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.bgRequestMoney,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            AppStrings
                .youCanStillAbleToRequestMoneyOnSelcomPesaUsingAnotherNumber
                .tr,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w500,
              fontSize: 15.sp,
              height: 20 / 15,
            ),
          ),
        ),
        SizedBox(height: 20.h),

        AppPrimaryButton(
          label: AppStrings.continueLabel.tr,
          onPressed: controller.openPhoneInput,
          showBottomInnerShadow: true,
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Column(
      children: [
        _StepperItem(
          step: '1',
          description: AppStrings.selcomPesaConnectStep1.tr,
          isLast: false,
        ),
        _StepperItem(
          step: '2',
          description: AppStrings.selcomPesaConnectStep2.tr,
          isLast: false,
        ),
        _StepperItem(
          step: '3',
          description: AppStrings.selcomPesaConnectStep3.tr,
          isLast: false,
        ),
        _StepperItem(
          step: '4',
          description: AppStrings.selcomPesaConnectStep4.tr,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildPhoneInputStep(BuildContext context) {
    return Column(
      key: const ValueKey(SelcomPesaStep.phoneInput),
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppStrings.enterPhoneNumber.tr,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textBody,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 8.h),

        Obx(
          () => AppTextField(
            controller: controller.selcomPhoneController,
            keyboardType: TextInputType.phone,
            autofocus: true,
            textFieldBackgroundColor: AppColors.pageBackground,
            borderColor: AppColors.borderWalletCard,
            errorText: controller.phoneError.value.isEmpty
                ? null
                : controller.phoneError.value,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TanzaniaPhoneFormatter(),
            ],
            prefixIcon: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Text(
                AppStrings.value255.tr,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHeading,
                ),
              ),
            ),
            onChanged: controller.onSelcomPhoneChanged,
          ),
        ),

        SizedBox(height: 24.h),

        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axis: Axis.vertical,
                child: child,
              ),
            ),
            child: controller.canContinueSelcomPhone.value
                ? AppPrimaryButton(
                    key: const ValueKey('selcom-pesa-continue-visible'),
                    label: AppStrings.continueLabel.tr,
                    onPressed: controller.onPhoneContinue,
                    showBottomInnerShadow: true,
                  )
                : const SizedBox.shrink(
                    key: ValueKey('selcom-pesa-continue-hidden'),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep(BuildContext context) {
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

    return Column(
      key: const ValueKey(SelcomPesaStep.otp),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.otpSentToYourPhoneNumber.trParams({
            'phoneNumber': TanzaniaPhoneFormatter.formatInternational(
              controller.selcomPhoneController.text,
            ),
          }),
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textBody,
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 16.h),
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

        SizedBox(height: 10.52.h),

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
                      fontWeight: FontWeight.w500,
                      fontSize: 15.sp,
                      height: 20 / 15,
                    ),
                  );
                } else {
                  return InkWell(
                    onTap: controller.resendOtp,
                    child: Text(
                      AppStrings.resendOtp.tr,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 15.sp,
                        height: 20 / 15,
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
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 15.sp,
                    height: 20 / 15,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildSelfieStep(BuildContext context) {
    return Column(
      key: const ValueKey(SelcomPesaStep.selfie),
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SvgPictureAsset(
            AppAssets.icFaceScan,
            height: 200.h,
            width: 160.w,
          ),
        ),
        SizedBox(height: 24.h),

        Text(
          AppStrings
              .yourSelfieWillBeCapturedToHelpUsValidateYouAgainstYourIdPleaseHoldYour
              .tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textBody,
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            height: 20 / 15,
          ),
        ),
        SizedBox(height: 24.h),

        AppPrimaryButton(
          label: AppStrings.takeSelfie.tr,
          onPressed: controller.takeSelfie,
          showBottomInnerShadow: true,
        ),
      ],
    );
  }
}

class _StepperItem extends StatelessWidget {
  final String step;
  final String description;
  final bool isLast;

  const _StepperItem({
    required this.step,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.borderWalletCard,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                      fontSize: 15.sp,
                      height: 20 / 15,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 10.w,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      border: Border.symmetric(
                        vertical: BorderSide(
                          color: AppColors.borderWalletCard,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textBody,
                    fontSize: 15.sp,
                    height: 1.4,
                  ),
                ),
                if (!isLast) SizedBox(height: 14.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
