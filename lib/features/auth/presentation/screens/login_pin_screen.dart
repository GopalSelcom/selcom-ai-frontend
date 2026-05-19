import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/widgets/app_otp_field.dart';
import '../controllers/login_pin_controller.dart';
import '../widgets/login_pin_auth_shell.dart';

/// Single screen for app **login PIN** setup, verify, and change.
///
/// Used by routes `pin-setup`, `pin-login`, `pin-change` ([AppRoutes]).
/// - **setup / login:** [LoginPinHeaderStyle.branded] (logo, centered titles).
/// - **change:** [LoginPinHeaderStyle.compact] (left-aligned like phone/OTP).
/// - **PIN loading:** full-screen overlay while [LoginPinController.isLoading].
/// - **Biometric loading:** spinner on the scan button only ([LoginPinController.isBiometricLoading]).
///
/// PIN digits: [AppOtpField] + shared [LoginPinController.pinController].
class LoginPinScreen extends GetView<LoginPinController> {
  const LoginPinScreen({super.key});

  LoginPinHeaderStyle get _headerStyle =>
      controller.mode == LoginPinScreenMode.change
          ? LoginPinHeaderStyle.compact
          : LoginPinHeaderStyle.branded;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoading.value;

      return Stack(
        children: [
          LoginPinAuthShell(
            headerStyle: _headerStyle,
            onBack: controller.mode == LoginPinScreenMode.change
                ? controller.goBackOnChangePin
                : controller.goBackOnSetup,
            showBackButton: controller.mode != LoginPinScreenMode.login,
            titleWidget: _buildTitle(context),
            subtitleWidget: _buildSubtitle(context),
            pinField: _buildPinFieldWithError(context),
            errorBanner: null,
            body: controller.mode == LoginPinScreenMode.login
                ? _buildLoginFooterActions(context)
                : const SizedBox.shrink(),
            bottom: SizedBox(height: 8.h),
          ),
          if (isLoading)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.textHeading.withValues(alpha: 0.08),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildPinFieldWithError(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPinField(context),
        SizedBox(height: 12.h),
        _buildErrorBanner(),
      ],
    );
  }

  Widget _buildPinField(BuildContext context) {
    return Obx(() {
      final disabled = controller.isInputDisabled.value ||
          controller.isBiometricLoading.value;
      final hasError = controller.hasError.value ||
          controller.errorMessage.value.isNotEmpty ||
          controller.lockCountdownLabel.value.isNotEmpty;

      final pinInput = IgnorePointer(
        ignoring: disabled,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: AppOtpField(
              controller: controller.pinController,
              length: 4,
              obscureText: true,
              fieldHeight: 70.h,
              fieldWidth: 64.w,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              hasError: hasError,
              textStyle: AppTextStyles.body.copyWith(
                fontFamily: AppTextStyles.metropolisFont,
                fontSize: 34.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.primary,
                height: 41 / 34,
                letterSpacing: -0.4,
              ),
              onCompleted: disabled ? (_) {} : controller.onPinCompleted,
              onChanged: (_) {
                if (controller.ignorePinFieldCallbacks ||
                    controller.isInputDisabled.value) {
                  return;
                }
                if (controller.hasError.value) {
                  controller.hasError.value = false;
                }
                if (controller.errorMessage.value.isNotEmpty) {
                  controller.errorMessage.value = '';
                }
              },
            ),
        ),
      );

      if (_headerStyle == LoginPinHeaderStyle.compact) {
        return Align(
          alignment: Alignment.center,
          widthFactor: 1,
          child: pinInput,
        );
      }

      return Center(child: pinInput);
    });
  }

  Widget _buildBiometricUnlockButton(
    BuildContext context, {
    required bool disabled,
  }) {
    final isBiometricLoading = controller.isBiometricLoading.value;
    final isBusy = disabled || isBiometricLoading;

    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : controller.authenticateWithBiometric,
          borderRadius: BorderRadius.circular(16.r),
          child: Opacity(
            opacity: isBiometricLoading ? 0.85 : 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.inputFocusShadow,
                          blurRadius: 0,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: isBiometricLoading
                        ? Center(
                            child: SizedBox(
                              width: 28.w,
                              height: 28.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5.w,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : Icon(
                            Iconsax.finger_scan,
                            size: 32.w,
                            color: AppColors.primary,
                          ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    AppStrings.unlockWithBiometric.tr,
                    textAlign: TextAlign.center,
                    style: LoginPinAuthShell.subtitleStyle(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (controller.mode == LoginPinScreenMode.login) {
      return Obx(() {
        final name = controller.displayName.value;
        final text = name.isNotEmpty
            ? AppStrings.welcomeBackPin.trParams({'name': name})
            : AppStrings.enterLoginPinTitle.tr;
        return Text(
          text,
          textAlign: TextAlign.center,
          style: LoginPinAuthShell.titleStyle(context, style: _headerStyle),
        );
      });
    }

    return Obx(() {
      return Text(
        controller.titleFor(
          setupStep: controller.setupStep.value,
          changeStep: controller.changeStep.value,
        ),
        textAlign: _headerStyle == LoginPinHeaderStyle.compact
            ? TextAlign.start
            : TextAlign.center,
        style: LoginPinAuthShell.titleStyle(context, style: _headerStyle),
      );
    });
  }

  Widget _buildSubtitle(BuildContext context) {
    if (controller.mode == LoginPinScreenMode.login) {
      return Text(
        AppStrings.enterLoginPinMessage.tr,
        textAlign: TextAlign.center,
        style: LoginPinAuthShell.subtitleStyle(context, style: _headerStyle),
      );
    }

    if (controller.mode == LoginPinScreenMode.change) {
      return Obx(() {
        return Text(
          controller.subtitleForChange(
            changeStep: controller.changeStep.value,
          ),
          textAlign: TextAlign.start,
          style: LoginPinAuthShell.subtitleStyle(context, style: _headerStyle),
        );
      });
    }

    return Text(
      controller.subtitleFor(maskedPhone: ''),
      textAlign: TextAlign.center,
      style: LoginPinAuthShell.subtitleStyle(context, style: _headerStyle),
    );
  }

  Widget _buildLoginFooterActions(BuildContext context) {
    return Obx(() {
      final disabled = controller.isInputDisabled.value ||
          controller.isBiometricLoading.value;
      final linkStyle = LoginPinAuthShell.subtitleStyle(context);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: disabled ? null : controller.useDifferentAccount,
                  child: Text(
                    controller.notYouLabel,
                    style: linkStyle,
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: GestureDetector(
                  onTap: disabled ? null : controller.openForgotPin,
                  child: Text(
                    AppStrings.forgotLoginPin.tr,
                    style: linkStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
          ),
          if (controller.showBiometricUnlockButton)
            _buildBiometricUnlockButton(
              context,
              disabled: controller.isInputDisabled.value,
            ),
        ],
      );
    });
  }

  Widget _buildErrorBanner() {
    return Obx(() {
      final message = controller.lockCountdownLabel.value.isNotEmpty
          ? controller.lockCountdownLabel.value
          : controller.errorMessage.value;
      if (message.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.otpErrorBackground,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.otpErrorBorder),
          ),
          child: Row(
            children: [
              SvgPictureAsset(
                AppAssets.icError,
                width: 22.w,
                height: 22.h,
                color: AppColors.otpErrorBorder,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textHeading,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
