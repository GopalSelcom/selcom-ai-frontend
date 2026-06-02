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
import 'mobile_money_topup_status_dialog.dart';

class SelcomPesaAnotherNumberBottomSheet extends StatefulWidget {
  const SelcomPesaAnotherNumberBottomSheet({super.key});

  static final ValueNotifier<String> _phoneInput = ValueNotifier<String>('');
  static final ValueNotifier<String> _amountInput = ValueNotifier<String>('');
  static final ValueNotifier<String?> _phoneError = ValueNotifier<String?>(
    null,
  );
  static final ValueNotifier<String?> _amountError = ValueNotifier<String?>(
    null,
  );

  static Future<void> show() {
    _phoneInput.value = '';
    _amountInput.value = '';
    _phoneError.value = null;
    _amountError.value = null;
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selcomPesa.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: const SelcomPesaAnotherNumberBottomSheet(),
      footer: Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.back.tr,
              onPressed: () => Get.back<void>(),
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
              onPressed: _startRequestFlow,
              borderRadius: 16.r,
              height: 56.h,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _startRequestFlow() async {
    final phone = _phoneInput.value.replaceAll(RegExp(r'\s+'), '');
    final amount = _amountInput.value.trim();
    if (phone.length < 9) {
      _phoneError.value = AppStrings.enterPhoneNumber.tr;
      return;
    }
    if (amount.isEmpty) {
      _amountError.value = AppStrings.amount.tr;
      return;
    }

    _phoneError.value = null;
    _amountError.value = null;
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
            requestTitle: AppStrings.requestSentCompleteSelcomTopup.tr,
            requestSubtitle: null,
            secondsListenable: value == MobileMoneyTopupDialogType.request
                ? countdown
                : null,
          ),
        ),
      ),
    );

    // TODO(payment-backend): replace mock timer with Selcom top-up request status API.
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
    await dialogFuture.timeout(
      const Duration(milliseconds: 600),
      onTimeout: () {},
    );
  }

  @override
  State<SelcomPesaAnotherNumberBottomSheet> createState() =>
      _SelcomPesaAnotherNumberBottomSheetState();
}

class _SelcomPesaAnotherNumberBottomSheetState
    extends State<SelcomPesaAnotherNumberBottomSheet> {
  late final TextEditingController _phoneController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _amountController = TextEditingController();
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
        ValueListenableBuilder<String?>(
          valueListenable: SelcomPesaAnotherNumberBottomSheet._phoneError,
          builder: (_, phoneError, __) => AppTextField(
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
            errorText: phoneError,
            onChanged: (value) {
              SelcomPesaAnotherNumberBottomSheet._phoneInput.value = value;
              if (SelcomPesaAnotherNumberBottomSheet._phoneError.value !=
                  null) {
                SelcomPesaAnotherNumberBottomSheet._phoneError.value = null;
              }
            },
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
        ValueListenableBuilder<String?>(
          valueListenable: SelcomPesaAnotherNumberBottomSheet._amountError,
          builder: (_, amountError, __) => AppTextField(
            hintText: '43,000',
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: _amountController,
            errorText: amountError,
            onChanged: (value) {
              SelcomPesaAnotherNumberBottomSheet._amountInput.value = value;
              if (SelcomPesaAnotherNumberBottomSheet._amountError.value !=
                  null) {
                SelcomPesaAnotherNumberBottomSheet._amountError.value = null;
              }
            },
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
        Padding(
          padding: EdgeInsets.fromLTRB(35.w, 12.h, 35.w, 35.h),
          child: Text(
            AppStrings.enterSelcomPesaCustomerPhoneHint.tr,
            style: AppTextStyles.homeSubtitle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
