import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../profile/presentation/controllers/payment_methods_controller.dart';
import 'mobile_money_topup_status_dialog.dart';
import 'selcom_pesa_another_number_bottom_sheet.dart';

class SelcomPesaToWalletBottomSheet extends StatefulWidget {
  const SelcomPesaToWalletBottomSheet({super.key});

  static final ValueNotifier<String> _amountInput = ValueNotifier<String>('');
  static final ValueNotifier<String?> _amountError = ValueNotifier<String?>(
    null,
  );

  static PaymentMethodsController _paymentController() {
    if (Get.isRegistered<PaymentMethodsController>()) {
      return Get.find<PaymentMethodsController>();
    }
    return Get.put(PaymentMethodsController(), permanent: true);
  }

  static Future<void> show() {
    _amountInput.value = '';
    _amountError.value = null;
    _paymentController();
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selcomPesaToGoWallet.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: const SelcomPesaToWalletBottomSheet(),
      footer: AppPrimaryButton(
        label: AppStrings.done.tr,
        onPressed: _startRequestFlow,
        borderRadius: 16.r,
        height: 56.h,
      ),
    );
  }

  static Future<void> _startRequestFlow() async {
    final amount = _amountInput.value.trim();
    if (amount.isEmpty) {
      _amountError.value = AppStrings.amount.tr;
      return;
    }
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
            requestTitle: AppStrings
                .requestSentPleaseCompletePaymentOnSelcomPesaToBookYourRide
                .tr,
            requestSubtitle: AppStrings.expiresInWithTime.trParams({
              'time': '2:00',
            }),
            secondsListenable: value == MobileMoneyTopupDialogType.request
                ? countdown
                : null,
          ),
        ),
      ),
    );

    // TODO(payment-backend): replace timer with request-money API callback.
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
  State<SelcomPesaToWalletBottomSheet> createState() =>
      _SelcomPesaToWalletBottomSheetState();
}

class _SelcomPesaToWalletBottomSheetState
    extends State<SelcomPesaToWalletBottomSheet> {
  late final PaymentMethodsController _paymentController;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _paymentController = SelcomPesaToWalletBottomSheet._paymentController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
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
          AppStrings.paymentMethodsTitle.tr,
          style: AppTextStyles.homeSubtitle,
        ),
        SizedBox(height: 8.h),
        Obx(() => _selcomCard(_paymentController)),
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () async {
              Get.back<void>();
              await SelcomPesaAnotherNumberBottomSheet.show();
            },
            child: Text(
              AppStrings.useAnotherNumber.tr,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.iconHeartFilled,
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Text(
          AppStrings.amount.tr,
          style: AppTextStyles.homeSubtitle.copyWith(
            color: AppColors.textMutedStrong,
          ),
        ),
        SizedBox(height: 4.h),
        ValueListenableBuilder<String?>(
          valueListenable: SelcomPesaToWalletBottomSheet._amountError,
          builder: (_, amountError, __) => AppTextField(
            readOnly: false,
            enabled: true,
            hintText: '43,000',
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: _amountController,
            errorText: amountError,
            onChanged: (value) {
              SelcomPesaToWalletBottomSheet._amountInput.value = value;
              if (SelcomPesaToWalletBottomSheet._amountError.value != null) {
                SelcomPesaToWalletBottomSheet._amountError.value = null;
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
            textColor: AppColors.iconPaymentSuccess,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 25.h),
      ],
    );
  }

  Widget _selcomCard(PaymentMethodsController controller) {
    final linked = controller.isSelcomPesaLinked.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: linked
            ? controller.openLinkedAccountSheet
            : controller.linkSelcomPesa,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.selcomPesa.tr,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.black,
                  ),
                ),
                if (linked) ...[
                  SizedBox(width: 7.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textVerified,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      AppStrings.defaultLabel.tr,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (linked)
                  Icon(
                    Icons.check_circle,
                    size: 22.sp,
                    color: AppColors.textVerified,
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              linked
                  ? AppStrings.selcomPesaLinkedNumber.trParams({
                      'number': '+255 711 410 410',
                    })
                  : AppStrings.connectSelcomPesaRideChargesSubtitle.tr,
              style: linked
                  ? AppTextStyles.bodySecondary.copyWith(height: 20 / 14)
                  : AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textBody,
                      fontSize: 12.sp,
                      height: 20 / 12,
                    ),
            ),
            if (!linked) ...[
              SizedBox(height: 5.h),
              Text(
                AppStrings.linkAccount.tr,
                style: AppTextStyles.homeSubtitle.copyWith(
                  color: AppColors.iconHeartFilled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
