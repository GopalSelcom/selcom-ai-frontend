import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/phone_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/wallet_topup_controller.dart';
import 'mobile_money_topup_status_dialog.dart';

class MobileMoneyTopupBottomSheet extends StatefulWidget {
  const MobileMoneyTopupBottomSheet({super.key});

  static Future<void> show({String? title}) {
    return AppDialogs.showStandardBottomSheet<void>(
      title: title ?? AppStrings.mobileMoney.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: const MobileMoneyTopupBottomSheet(),
      footer: const _MobileMoneyTopupFooter(),
    );
  }

  static Future<void> startTopupFlowFromFooter() async {
    final controller = Get.find<WalletTopupController>();
    if (!controller.validateInputs()) return;

    Get.back<void>();

    final countdown = ValueNotifier<int>(120);
    final status = ValueNotifier<MobileMoneyTopupDialogType>(
      MobileMoneyTopupDialogType.request,
    );
    final dialogFuture = AppDialogs.showAnimatedDialog<void>(
      barrierDismissible: false,
      child: ValueListenableBuilder<MobileMoneyTopupDialogType>(
        valueListenable: status,
        builder: (_, value, __) => PopScope(
          canPop: value == MobileMoneyTopupDialogType.success,
          child: MobileMoneyTopupStatusDialog(
            type: value,
            secondsListenable: value == MobileMoneyTopupDialogType.request
                ? countdown
                : null,
          ),
        ),
      ),
    );

    final succeeded = await controller.submitTopupWithFeedback();
    if (!succeeded) {
      countdown.dispose();
      status.dispose();
      final navigator = Get.key.currentState;
      if (navigator != null) {
        navigator.maybePop();
      } else if (Get.isDialogOpen == true) {
        Get.back<void>();
      }
      await dialogFuture.timeout(
        const Duration(milliseconds: 600),
        onTimeout: () {},
      );
      return;
    }

    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      countdown.value = (countdown.value - 1).clamp(0, 120);
    }
    status.value = MobileMoneyTopupDialogType.success;
    countdown.dispose();
    await Future<void>.delayed(const Duration(seconds: 2));
    final navigator = Get.key.currentState;
    if (navigator != null) {
      navigator.maybePop();
    } else if (Get.isDialogOpen == true) {
      Get.back<void>();
    }
    status.dispose();
    await dialogFuture.timeout(const Duration(milliseconds: 600), onTimeout: () {});
  }

  @override
  State<MobileMoneyTopupBottomSheet> createState() =>
      _MobileMoneyTopupBottomSheetState();
}

class _MobileMoneyTopupFooter extends StatelessWidget {
  const _MobileMoneyTopupFooter();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletTopupController>();
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.back.tr,
              onPressed: controller.isSubmitting.value ? null : () => Get.back<void>(),
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
              onPressed: controller.isSubmitting.value
                  ? null
                  : MobileMoneyTopupBottomSheet.startTopupFlowFromFooter,
              borderRadius: 16.r,
              height: 56.h,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileMoneyTopupBottomSheetState
    extends State<MobileMoneyTopupBottomSheet> {
  late final TextEditingController _phoneController;
  late final TextEditingController _amountController;
  late final WalletTopupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WalletTopupController>();
    _phoneController = TextEditingController(text: _controller.phoneInput.value);
    _amountController = TextEditingController(text: _controller.amountInput.value);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        Obx(
          () => AppTextField(
            readOnly: false,
            enabled: !_controller.isSubmitting.value,
            hintText: '987 654 321',
            keyboardType: TextInputType.phone,
            maxLength: 11,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TanzaniaPhoneFormatter(),
            ],
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: _phoneController,
            errorText: _controller.phoneError.value,
            onChanged: _controller.updatePhone,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '+255',
                  style: AppTextStyles.homeTitle.copyWith(
                    fontSize: 16.sp,
                    height: 22 / 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
            ),
            textColor: AppColors.iconHeartFilled,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          AppStrings.amount.tr,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: AppColors.textMutedStrong,
          ),
        ),
        SizedBox(height: 4.h),
        Obx(
          () => AppTextField(
            readOnly: false,
            enabled: !_controller.isSubmitting.value,
            hintText: '43,000',
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: _amountController,
            errorText: _controller.amountError.value,
            onChanged: _controller.updateAmount,
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
            textColor: AppColors.iconHeartFilled,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 42.h),
      ],
    );
  }
}
