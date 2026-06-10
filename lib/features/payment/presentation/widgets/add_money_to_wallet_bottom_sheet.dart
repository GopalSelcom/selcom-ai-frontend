import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/thousands_separator_input_formatter.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_standard_bottom_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/tanqr_wallet_topup_controller.dart';
import '../../data/models/go_other_payment_methods_models.dart';
import 'mobile_money_topup_bottom_sheet.dart';
import 'selcom_pesa_to_wallet_bottom_sheet.dart';
import 'steps_to_load_go_wallet_bottom_sheet.dart';
import 'tanqr_tips_bottom_sheet.dart';

/// Add-money options after insufficient-balance "Top up Wallet" (Figma sheet).
class AddMoneyToWalletBottomSheet extends StatelessWidget {
  const AddMoneyToWalletBottomSheet({super.key, required this.controllerTag});

  final String controllerTag;

  static Future<TanQrTopupResult?> show() {
    final tag = 'tanqr_wallet_${DateTime.now().millisecondsSinceEpoch}';
    Get.put(TanQrWalletTopupController(), tag: tag);
    return AppDialogs.showStandardBottomSheet<TanQrTopupResult?>(
      sheet: AddMoneyToWalletBottomSheet(controllerTag: tag),
    ).whenComplete(() {
      unawaited(
        AppDialogs.runAfterBottomSheetDismissed(() async {
          if (!Get.isRegistered<TanQrWalletTopupController>(tag: tag)) return;
          final controller = Get.find<TanQrWalletTopupController>(tag: tag);
          controller.handleSheetDismissed();
          Get.delete<TanQrWalletTopupController>(tag: tag);
        }),
      );
    });
  }

  TanQrWalletTopupController get _controller {
    if (!Get.isRegistered<TanQrWalletTopupController>(tag: controllerTag)) {
      throw FlutterError(
        'TanQrWalletTopupController(tag: $controllerTag) is not registered.',
      );
    }
    return Get.find<TanQrWalletTopupController>(tag: controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TanQrWalletTopupController>(tag: controllerTag)) {
      return const SizedBox.shrink();
    }
    final controller = _controller;
    return Obx(() {
      final step = controller.step.value;
      return PopScope(
        canPop: step != TanQrTopupStep.qrDisplay,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            controller.handleSheetDismissed();
          }
        },
        child: AppStandardBottomSheet(
          title: _titleForStep(step),
          headerTextAlign: TextAlign.center,
          showHeaderDivider:
              step != TanQrTopupStep.options &&
              step != TanQrTopupStep.qrDisplay,
          content: _contentForStep(step, controller),
          footer: _footerForStep(step, controller),
        ),
      );
    });
  }

  String? _titleForStep(TanQrTopupStep step) {
    switch (step) {
      case TanQrTopupStep.options:
        return AppStrings.addMoneyToWallet.tr;
      case TanQrTopupStep.amountEntry:
        return AppStrings.addMoneyTanQrTips.tr;
      case TanQrTopupStep.qrDisplay:
        return AppStrings.addMoneyTanQrTips.tr;
    }
  }

  Widget _contentForStep(TanQrTopupStep step, TanQrWalletTopupController controller) {
    switch (step) {
      case TanQrTopupStep.options:
        return _OptionsContent(controller: controller);
      case TanQrTopupStep.amountEntry:
        return _AmountEntryContent(controller: controller);
      case TanQrTopupStep.qrDisplay:
        return _TanQrDisplayContent(controller: controller);
    }
  }

  Widget? _footerForStep(
    TanQrTopupStep step,
    TanQrWalletTopupController controller,
  ) {
    switch (step) {
      case TanQrTopupStep.options:
        return null;
      case TanQrTopupStep.amountEntry:
        return _AmountEntryFooter(controller: controller);
      case TanQrTopupStep.qrDisplay:
        return _TanQrDisplayFooter(controller: controller);
    }
  }
}

class _OptionsContent extends StatelessWidget {
  const _OptionsContent({required this.controller});

  final TanQrWalletTopupController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AddMoneyOptionTile(
          title: AppStrings.selcomPesa.tr,
          subtitle: AppStrings.addMoneySelcomPesaSubtitle.tr,
          onTap: _onSelcomPesaTap,
        ),
        SizedBox(height: 12.h),
        // _AddMoneyOptionTile(
        //   title: AppStrings.addMoneyTanQrTips.tr,
        //   subtitle: AppStrings.addMoneyTanQrTipsSubtitle.tr,
        //   onTap: controller.openTanQrAmountEntry,
        // ),
        // SizedBox(height: 12.h),
        _AddMoneyOptionTile(
          title: AppStrings.mobileMoney.tr,
          subtitle: AppStrings.addMoneyMobileMoneySubtitle.tr,
          onTap: () => _onOptionTap(_AddMoneyOption.mobileMoney),
        ),
        SizedBox(height: 8.h),
        // _AddMoneyOptionTile(
        //   title: AppStrings.addMoneyStepsToLoadGoWallet.tr,
        //   subtitle: AppStrings.addMoneyStepsToLoadGoWalletSubtitle.tr,
        //   onTap: () => _onOptionTap(_AddMoneyOption.stepsToLoad),
        // ),
        // SizedBox(height: 8.h),
      ],
    );
  }

  void _onSelcomPesaTap() {
    Get.back<void>();
    SelcomPesaToWalletBottomSheet.show();
  }

  void _onOptionTap(_AddMoneyOption option) {
    Get.back<void>();
    switch (option) {
      case _AddMoneyOption.stepsToLoad:
        StepsToLoadGoWalletBottomSheet.show();
        break;
      case _AddMoneyOption.mobileMoney:
        MobileMoneyTopupBottomSheet.show();
        break;
    }
  }
}

class _AmountEntryContent extends StatelessWidget {
  const _AmountEntryContent({required this.controller});

  final TanQrWalletTopupController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final apiError = controller.apiError.value;
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
            textColor: AppColors.iconHeartFilled,
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

class _AmountEntryFooter extends StatelessWidget {
  const _AmountEntryFooter({required this.controller});

  final TanQrWalletTopupController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final canContinue = controller.canContinue;
      return Row(
        children: [
          Expanded(
            child: AppPrimaryButton(
              label: AppStrings.back.tr,
              onPressed: controller.isSubmitting.value
                  ? null
                  : controller.backToOptions,
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
              onPressed: canContinue ? _onContinuePressed : null,
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
    final validation = controller.validateAmountForDisplay();
    controller.amountError.value = validation;
    if (validation != null) return;
    unawaited(controller.submitAmount());
  }
}

class _TanQrDisplayContent extends StatelessWidget {
  const _TanQrDisplayContent({required this.controller});

  final TanQrWalletTopupController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seconds = controller.countdownSeconds.value;
      return TanQrTipsContent(
        qrData: controller.session.value?.qr ?? '',
        accountName: controller.displayName.value,
        accountNumber: controller.displayWalletNumber.value,
        countdownText: AppStrings.expiresInTimer.trParams({
          'timer': controller.formatCountdown(seconds),
        }),
      );
    });
  }
}

class _TanQrDisplayFooter extends StatelessWidget {
  const _TanQrDisplayFooter({required this.controller});

  final TanQrWalletTopupController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasTransid =
          (controller.session.value?.transid.trim().isNotEmpty ?? false);
      return AppPrimaryButton(
        label: AppStrings.tanQrCancelRequest.tr,
        onPressed: hasTransid && !controller.isCancelling.value
            ? () => unawaited(controller.cancelPaymentRequest())
            : null,
        isLoading: controller.isCancelling.value,
        width: double.infinity,
        height: 56.h,
        borderRadius: 16.r,
      );
    });
  }
}

enum _AddMoneyOption { mobileMoney, stepsToLoad }

class _AddMoneyOptionTile extends StatelessWidget {
  const _AddMoneyOptionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderWalletCard, width: 0.8.w),
          color: AppColors.surfaceSubtle,
        ),
        child: CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
          minimumSize: Size.zero,
          alignment: Alignment.centerLeft,
          onPressed: onTap,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.textHeading,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(subtitle, style: AppTextStyles.homeSubtitle),
                  ],
                ),
              ),
              SvgPictureAsset(
                AppAssets.icArrowForward,
                width: 20.w,
                height: 20.w,
                color: AppColors.iconHeartOutline,
                placeholderBuilder: (_) => Icon(
                  Icons.arrow_forward_ios,
                  size: 20.sp,
                  color: AppColors.textMapHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
