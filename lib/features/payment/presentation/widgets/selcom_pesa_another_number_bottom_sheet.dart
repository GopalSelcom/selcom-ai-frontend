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
import '../../domain/wallet_payment_phone_country.dart';
import '../controllers/selcom_pesa_topup_controller.dart';
import 'wallet_topup_sheet_lifecycle.dart';

class SelcomPesaAnotherNumberBottomSheet extends StatefulWidget {
  const SelcomPesaAnotherNumberBottomSheet({
    super.key,
    required this.controllerTag,
  });

  final String controllerTag;

  static Future<void> show({required String controllerTag}) {
    if (!Get.isRegistered<SelcomPesaTopupController>(tag: controllerTag)) {
      Get.put(
        SelcomPesaTopupController(controllerTag: controllerTag),
        tag: controllerTag,
      );
    }

    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selcomPesa.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: SelcomPesaAnotherNumberBottomSheet(controllerTag: controllerTag),
      footer: _SelcomPesaOtherFooter(controllerTag: controllerTag),
    ).whenComplete(() async {
      if (!Get.isRegistered<SelcomPesaTopupController>(tag: controllerTag)) {
        return;
      }
      final selcomController = Get.find<SelcomPesaTopupController>(
        tag: controllerTag,
      );
      selcomController.clearRetainForFollowUpSheet();
      await disposeSelcomPesaTopupAfterSheetClosed(controllerTag);
    });
  }

  @override
  State<SelcomPesaAnotherNumberBottomSheet> createState() =>
      _SelcomPesaAnotherNumberBottomSheetState();
}

class _SelcomPesaAnotherNumberBottomSheetState
    extends State<SelcomPesaAnotherNumberBottomSheet> {
  late final TextEditingController _phoneController;

  SelcomPesaTopupController get _controller =>
      Get.find<SelcomPesaTopupController>(tag: widget.controllerTag);

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _controller.bindPhoneController(_phoneController);
  }

  @override
  void dispose() {
    if (Get.isRegistered<SelcomPesaTopupController>(tag: widget.controllerTag)) {
      _controller.unbindPhoneController();
    }
    final phone = _phoneController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      phone.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const iso = WalletPaymentPhoneCountry.iso;
    const dialCodeDisplay = WalletPaymentPhoneCountry.dialCodeDisplay;

    return Obx(() {
      if (!mounted ||
          !Get.isRegistered<SelcomPesaTopupController>(
            tag: widget.controllerTag,
          ) ||
          _controller.textFieldsDisposed) {
        return const SizedBox.shrink();
      }
      final apiError = _controller.apiError.value;
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
            enabled: !_controller.isSubmitting.value,
            hintText: PhoneNationalRules.hintForIso(iso),
            keyboardType: TextInputType.phone,
            maxLength: PhoneNationalRules.maxDisplayCharactersForIso(iso),
            inputFormatters: PhoneNationalRules.inputFormattersForIso(iso),
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: _phoneController,
            errorText: _controller.phoneError.value,
            onChanged: _controller.onPhoneChanged,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 8.w),
              child: Center(
                widthFactor: 1,
                child: Text(
                  dialCodeDisplay,
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
            enabled: !_controller.isSubmitting.value,
            hintText: '5,000',
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            textFieldBackgroundColor: AppColors.surfaceSubtle,
            borderColor: AppColors.borderWalletCard,
            controller: _controller.amountController,
            errorText: _controller.amountError.value,
            onChanged: _controller.onAmountChanged,
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
    });
  }
}

class _SelcomPesaOtherFooter extends GetView<SelcomPesaTopupController> {
  const _SelcomPesaOtherFooter({required this.controllerTag});

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
              onPressed: controller.canSubmitOther ? _onContinuePressed : null,
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
    unawaited(controller.submitOtherTopUp(closeSheetFirst: true));
  }
}
