import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_national_rules.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/mobile_money_topup_controller.dart';
import 'wallet_topup_sheet_lifecycle.dart';

class MobileMoneyTopupBottomSheet extends GetView<MobileMoneyTopupController> {
  const MobileMoneyTopupBottomSheet({super.key, required this.controllerTag});

  final String controllerTag;

  static Future<void> show() {
    final tag = 'mobile_money_${DateTime.now().millisecondsSinceEpoch}';
    Get.put(
      MobileMoneyTopupController(controllerTag: tag),
      tag: tag,
    );
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.mobileMoney.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: MobileMoneyTopupBottomSheet(controllerTag: tag),
      footer: _MobileMoneyFooter(controllerTag: tag),
    ).whenComplete(() => disposeMobileMoneyTopupAfterSheetClosed(tag));
  }

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MobileMoneyTopupController>(tag: controllerTag) ||
        controller.textFieldsDisposed) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      if (!Get.isRegistered<MobileMoneyTopupController>(tag: controllerTag) ||
          controller.textFieldsDisposed) {
        return const SizedBox.shrink();
      }
      final apiError = controller.apiError.value;
      final iso = controller.countryIso;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.enterPhoneNumber.tr,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textMutedStrong,
            ),
          ),
          SizedBox(height: 4.h),
          AppTextField(
            readOnly: false,
            enabled: !controller.isSubmitting.value,
            hintText: PhoneNationalRules.hintForIso(iso),
            keyboardType: TextInputType.phone,
            maxLength: PhoneNationalRules.maxDisplayCharactersForIso(iso),
            inputFormatters: PhoneNationalRules.inputFormattersForIso(iso),
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: controller.phoneController,
            errorText: controller.phoneError.value,
            onChanged: controller.onPhoneChanged,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              child: Center(
                widthFactor: 1,
                child: Text(
                  controller.countryDialCodeDisplay,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 16.sp,
                    height: 22 / 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ),
            textColor: AppColors.textHeading,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: 12.h),
          Text(
            AppStrings.amount.tr,
            style: AppTextStyles.homeSubtitle.copyWith(
              color: AppColors.textMutedStrong,
            ),
          ),
          SizedBox(height: 4.h),
          AppTextField(
            readOnly: false,
            enabled: !controller.isSubmitting.value,
            hintText: '5,000',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: controller.amountController,
            errorText: controller.amountError.value,
            onChanged: controller.onAmountChanged,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              child: Center(
                widthFactor: 1,
                child: Text(
                  AppStrings.defaultCurrencyTzs.tr,
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 16.sp,
                    height: 22 / 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ),
            textColor: AppColors.textHeading,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
          if (apiError != null && apiError.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              apiError,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.error,
                fontSize: 13.sp,
              ),
            ),
          ],
          SizedBox(height: 42.h),
        ],
      );
    });
  }
}

class _MobileMoneyFooter extends GetView<MobileMoneyTopupController> {
  const _MobileMoneyFooter({required this.controllerTag});

  final String controllerTag;

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.isRegistered<MobileMoneyTopupController>(tag: controllerTag) ||
          controller.textFieldsDisposed) {
        return const SizedBox.shrink();
      }
      return Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.back.tr,
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => Get.back<void>(),
              outlined: true,
              backgroundColor: AppColors.white,
              outlinedTextColor: AppColors.black,
              outlinedBorderColor: AppColors.black,
              outlinedBorderWidth: 1,
              borderRadius: 16.r,
              height: 56.h,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.continueLabel.tr,
              onPressed: controller.canContinue ? _onContinuePressed : null,
              isLoading: controller.isSubmitting.value,
              borderRadius: 16.r,
              height: 56.h,
            ),
          ),
        ],
      );
    });
  }

  void _onContinuePressed() {
    controller.phoneError.value = controller.validatePhoneForDisplay();
    controller.amountError.value = controller.validateAmountForDisplay();
    if (controller.phoneError.value != null ||
        controller.amountError.value != null) {
      return;
    }
    unawaited(controller.submit());
  }
}
