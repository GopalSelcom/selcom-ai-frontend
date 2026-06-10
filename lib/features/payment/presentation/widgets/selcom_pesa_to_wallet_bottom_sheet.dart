import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../profile/presentation/controllers/payment_methods_controller.dart';
import '../controllers/selcom_pesa_topup_controller.dart';
import 'selcom_pesa_another_number_bottom_sheet.dart';
import 'wallet_topup_sheet_lifecycle.dart';

class SelcomPesaToWalletBottomSheet extends GetView<SelcomPesaTopupController> {
  const SelcomPesaToWalletBottomSheet({
    super.key,
    required this.controllerTag,
    required this.paymentController,
  });

  final String controllerTag;
  final PaymentMethodsController paymentController;

  static Future<void> show() {
    final tag = 'selcom_pesa_self_${DateTime.now().millisecondsSinceEpoch}';
    final paymentController = _paymentController();
    Get.put(SelcomPesaTopupController(controllerTag: tag), tag: tag);
    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selcomPesaToGoWallet.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: SelcomPesaToWalletBottomSheet(
        controllerTag: tag,
        paymentController: paymentController,
      ),
      footer: _SelcomPesaSelfFooter(controllerTag: tag),
    ).whenComplete(() => disposeSelcomPesaTopupAfterSheetClosed(tag));
  }

  static PaymentMethodsController _paymentController() {
    if (Get.isRegistered<PaymentMethodsController>()) {
      return Get.find<PaymentMethodsController>();
    }
    return Get.put(PaymentMethodsController(), permanent: true);
  }

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SelcomPesaTopupController>(tag: controllerTag) ||
        controller.textFieldsDisposed) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.paymentMethodsTitle.tr,
          style: AppTextStyles.homeSubtitle,
        ),
        SizedBox(height: 8.h),
        Obx(() => _selcomCard(paymentController)),
        SizedBox(height: 8.h),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () async {
              controller.retainForOtherNumberSheet();
              Get.back<void>();
              await SelcomPesaAnotherNumberBottomSheet.show(
                controllerTag: controllerTag,
              );
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
        Obx(() {
          if (!Get.isRegistered<SelcomPesaTopupController>(tag: controllerTag) ||
              controller.textFieldsDisposed) {
            return const SizedBox.shrink();
          }
          final apiError = controller.apiError.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              SizedBox(height: 25.h),
            ],
          );
        }),
      ],
    );
  }

  Widget _selcomCard(PaymentMethodsController paymentMethodsController) {
    final linked = paymentMethodsController.isSelcomPesaLinked.value;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: linked
            ? paymentMethodsController.openLinkedAccountSheet
            : paymentMethodsController.linkSelcomPesa,
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

class _SelcomPesaSelfFooter extends GetView<SelcomPesaTopupController> {
  const _SelcomPesaSelfFooter({required this.controllerTag});

  final String controllerTag;

  @override
  String? get tag => controllerTag;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!Get.isRegistered<SelcomPesaTopupController>(tag: controllerTag) ||
          controller.textFieldsDisposed) {
        return const SizedBox.shrink();
      }
      return AppPrimaryButton(
        label: AppStrings.done.tr,
        onPressed: controller.canSubmitSelf ? _onDonePressed : null,
        isLoading: controller.isSubmitting.value,
        borderRadius: 16.r,
        height: 56.h,
      );
    });
  }

  void _onDonePressed() {
    controller.amountError.value = controller.validateAmountForDisplay();
    if (controller.amountError.value != null) return;
    unawaited(controller.submitSelfTopUp(closeSheetFirst: true));
  }
}
