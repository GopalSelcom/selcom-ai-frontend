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
import '../../../profile/data/models/selcom_pesa_link_models.dart';
import '../../../profile/domain/entities/selcom_pesa_linked_account_entity.dart';
import '../controllers/selcom_pesa_topup_controller.dart';
import 'wallet_topup_sheet_lifecycle.dart';

class SelcomPesaSelfBottomSheet extends StatefulWidget {
  const SelcomPesaSelfBottomSheet({
    super.key,
    required this.controllerTag,
    this.account,
  });

  final String controllerTag;
  final Account? account;

  static Future<void> show({Account? account}) {
    final tag = account != null
        ? 'selcom_pesa_linked_${account.id}_${DateTime.now().millisecondsSinceEpoch}'
        : 'selcom_pesa_self_${DateTime.now().millisecondsSinceEpoch}';
    Get.put(SelcomPesaTopupController(controllerTag: tag), tag: tag);

    return AppDialogs.showStandardBottomSheet<void>(
      title: AppStrings.selcomPesa.tr,
      headerTextAlign: TextAlign.center,
      showHeaderDivider: true,
      barrierDismissible: true,
      content: SelcomPesaSelfBottomSheet(controllerTag: tag, account: account),
      footer: _SelcomPesaSelfSheetFooter(controllerTag: tag, account: account),
    ).whenComplete(() => disposeSelcomPesaTopupAfterSheetClosed(tag));
  }

  @override
  State<SelcomPesaSelfBottomSheet> createState() =>
      _SelcomPesaSelfBottomSheetState();
}

class _SelcomPesaSelfBottomSheetState extends State<SelcomPesaSelfBottomSheet> {
  late final TextEditingController _amountController;

  SelcomPesaTopupController get _controller =>
      Get.find<SelcomPesaTopupController>(tag: widget.controllerTag);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _controller.bindPhoneController(TextEditingController()); // Empty or dummy phone controller as it's self.
  }

  @override
  void dispose() {
    if (Get.isRegistered<SelcomPesaTopupController>(tag: widget.controllerTag)) {
      _controller.unbindPhoneController();
    }
    final amount = _amountController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      amount.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            controller: _amountController,
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
            textColor: AppColors.success,
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
          SizedBox(height: 20.h),
        ],
      );
    });
  }
}

class _SelcomPesaSelfSheetFooter extends GetView<SelcomPesaTopupController> {
  const _SelcomPesaSelfSheetFooter({
    required this.controllerTag,
    this.account,
  });

  final String controllerTag;
  final Account? account;

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
              label: AppStrings.cancel.tr,
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
              onPressed: controller.canSubmitSelf ? _onContinuePressed : null,
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
    controller.amountError.value = controller.validateAmountForDisplay();
    if (controller.amountError.value != null) {
      return;
    }
    if (account != null) {
      unawaited(
        controller.submitSelectedLinkedAccountTopUp(
          account: account!,
          closeSheetFirst: true,
        ),
      );
    } else {
      unawaited(controller.submitSelfTopUp(closeSheetFirst: true));
    }
  }
}
