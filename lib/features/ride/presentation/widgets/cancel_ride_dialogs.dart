import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/data/models/ride_cancel_info_model.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/app_dialogs.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_cancel_flow_dialog.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../controllers/cancel_reason_selection_controller.dart';

class CancelConfirmationDialog extends StatelessWidget {
  const CancelConfirmationDialog({super.key, this.cancelInfo});

  /// Backend `cancel_info` — title/subtitle rendered verbatim when present.
  final RideCancelInfoModel? cancelInfo;

  @override
  Widget build(BuildContext context) {
    final info = cancelInfo;
    final title = (info?.title.trim().isNotEmpty ?? false)
        ? info!.title
        : AppStrings.areYouSureYouWantToCancel.tr;
    final subtitle = info?.subtitle.trim() ?? '';
    final hasFee = info?.hasFee ?? false;

    return AppCancelFlowDialog(
      title: title,
      // Neutral subtitle when free; fee copy uses warning color in [content].
      subtitle: (!hasFee && subtitle.isNotEmpty) ? subtitle : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasFee && subtitle.isNotEmpty) ...[
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
          ],
          _ActionButton(
            title: AppStrings.yesCancel.tr,
            color: AppColors.primaryButton,
            textColor: AppColors.white,
            onTap: () => Get.back(result: true),
          ),
          SizedBox(height: 16.h),
          _ActionButton(
            title: AppStrings.no.tr,
            color: AppColors.white,
            textColor: AppColors.textNeutralButton,
            outlined: true,
            outlinedBorderColor: AppColors.textNeutralButton,
            onTap: () => Get.back(result: false),
          ),
        ],
      ),
    );
  }
}

class CancelAssignmentWarningDialog extends StatelessWidget {
  const CancelAssignmentWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCancelFlowDialog(
      title:
          "${AppStrings.areYouSureYouWantToCancel.tr}\n${AppStrings.yourDriverIsAlreadyOnTheWay.tr}",
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 15.sp,
                color: AppColors.textSlate,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(text: AppStrings.cancellationFeeOf.tr),
                TextSpan(
                  text: '${CurrencyFormatter.displaySymbol} 150',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: AppStrings.willBeChargedSinceDriverOnWay.tr),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          _ActionButton(
            title: AppStrings.keepRide.tr,
            color: AppColors.primaryButton,
            textColor: AppColors.white,
            onTap: () => Get.back(result: false),
          ),
          SizedBox(height: 12.h),
          _ActionButton(
            title: AppStrings.cancelAndPay.tr,
            color: AppColors.bgSoftCircle,
            textColor: AppColors.textSlateSoft,
            onTap: () => Get.back(result: true),
          ),
        ],
      ),
    );
  }
}

class CancelReasonSelectionDialog extends StatelessWidget {
  const CancelReasonSelectionDialog._({required this.controllerTag});

  final String controllerTag;

  CancelReasonSelectionController get controller =>
      Get.find<CancelReasonSelectionController>(tag: controllerTag);

  factory CancelReasonSelectionDialog({
    required List<String> reasons,
    Future<void> Function(String reason)? onContinueTap,
  }) {
    final controllerTag =
        'cancel_reason_selection_${DateTime.now().microsecondsSinceEpoch}';
    Get.put(
      CancelReasonSelectionController(
        reasons: reasons,
        onContinueTap: onContinueTap,
      ),
      tag: controllerTag,
    );
    return CancelReasonSelectionDialog._(controllerTag: controllerTag);
  }

  void disposeController() {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (Get.isRegistered<CancelReasonSelectionController>(
        tag: controllerTag,
      )) {
        Get.delete<CancelReasonSelectionController>(tag: controllerTag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedReason = controller.selectedReason.value;
      final reasons = controller.reasons;

      return AppCancelFlowDialog(
        canPop: false,
        title: AppStrings.whyDoYouWantToCancel.tr,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < reasons.length; index++) ...[
                  if (index > 0)
                    Divider(height: 1.h, color: AppColors.bgSoftCircle),
                  _buildReasonOption(
                    reason: reasons[index],
                    isSelected: selectedReason == reasons[index],
                    isFirst: index == 0,
                    isLast: index == reasons.length - 1,
                    onTap: () => controller.selectReason(reasons[index]),
                  ),
                ],
              ],
            ),
            SizedBox(height: 32.h),
            _ActionButton(
              title: AppStrings.continueLabel.tr,
              color: controller.hasSelection
                  ? AppColors.primaryButton
                  : AppColors.bgSoftCircle,
              textColor: controller.hasSelection
                  ? AppColors.white
                  : AppColors.textSlateSoft,
              onTap: controller.hasSelection ? controller.onContinue : null,
            ),
            SizedBox(height: 12.h),
            _ActionButton(
              title: AppStrings.no.tr,
              color: AppColors.white,
              textColor: AppColors.textNeutralButton,
              outlined: true,
              outlinedBorderColor: AppColors.textNeutralButton,
              onTap: () => Get.back(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReasonOption({
    required String reason,
    required bool isSelected,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: isFirst ? 0 : 14.h,
          bottom: isLast ? 0 : 14.h,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason,
                style: AppTextStyles.homeSubtitle.copyWith(
                  color: AppColors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  height: 20 / 15,
                ),
              ),
            ),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.iconHeartOutline,
                  width: 1.5,
                ),
                color: isSelected ? AppColors.primary : AppColors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14.sp, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class CancellationChargesDialog extends StatelessWidget {
  const CancellationChargesDialog({
    super.key,
    required this.canCancel,
    required this.cancellationFee,
    required this.netRefund,
    this.onConfirmTap,
  });

  final bool canCancel;
  final int cancellationFee;
  final int netRefund;
  final Future<void> Function()? onConfirmTap;

  @override
  Widget build(BuildContext context) {
    final feeLabel = '${CurrencyFormatter.displaySymbol} $cancellationFee';
    final refundLabel = '${CurrencyFormatter.displaySymbol} $netRefund';

    return AppCancelFlowDialog(
      canPop: false,
      title:
          "${AppStrings.areYouSureYouWantToCancel.tr}\n${AppStrings.yourDriverIsAlreadyOnTheWay.tr}",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.textSlate,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              children: [
                TextSpan(text: AppStrings.cancellationFeeOf.tr),
                TextSpan(
                  text: feeLabel,
                  style: AppTextStyles.price.copyWith(
                    fontSize: 15.sp,
                    height: 1.4,
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: AppStrings.willBeChargedSinceDriverOnWay.tr),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: AppStrings.netAmountRefunded.tr,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.textSlate,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: refundLabel,
                  style: AppTextStyles.price.copyWith(
                    fontSize: 15.sp,
                    height: 1.4,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Divider(height: 1.h, color: AppColors.bgSoftCircle),
          SizedBox(height: 20.h),
          _ActionButton(
            title: AppStrings.keepRide.tr,
            color: AppColors.primaryButton,
            textColor: AppColors.white,
            onTap: () => Get.back(result: false),
          ),
          SizedBox(height: 10.h),
          _ActionButton(
            title: AppStrings.cancelAndPay.tr,
            color: AppColors.white,
            textColor: AppColors.textNeutralButton,
            outlined: true,
            outlinedBorderColor: AppColors.textNeutralButton,
            onTap: () async {
              if (!canCancel) {
                AppDialogs.showErrorDialog(
                  title: AppStrings.cancelFailed.tr,
                  message: AppStrings.couldNotCancelTryAgain.tr,
                );
                return;
              }
              if (onConfirmTap != null) {
                await onConfirmTap!.call();
              } else {
                Get.back(result: true);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Post-cancel settlement summary from `PUT .../cancel` (`cancellation_fee` / `net_refund`).
class CancelResultDialog extends StatelessWidget {
  const CancelResultDialog({
    super.key,
    required this.cancellationFee,
    required this.netRefund,
  });

  final int cancellationFee;
  final int netRefund;

  @override
  Widget build(BuildContext context) {
    final feeLabel = CurrencyFormatter.format(cancellationFee);
    final refundLabel = CurrencyFormatter.format(netRefund);
    final bodyStyle = AppTextStyles.homeSubtitle.copyWith(
      color: AppColors.textSlate,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );

    return AppCancelFlowDialog(
      canPop: false,
      title: AppStrings.rideCancelled.tr,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: bodyStyle,
              children: [
                if (cancellationFee > 0) ...[
                  TextSpan(text: AppStrings.cancellationFeeOf.tr),
                  TextSpan(
                    text: feeLabel,
                    style: bodyStyle.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: AppStrings.hasBeenChargedPeriod.tr),
                ],
                if (cancellationFee > 0 && netRefund > 0)
                  const TextSpan(text: '\n\n'),
                if (netRefund > 0) ...[
                  TextSpan(text: AppStrings.netRefundOf.tr),
                  TextSpan(
                    text: refundLabel,
                    style: bodyStyle.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: AppStrings.hasBeenRefundedPeriod.tr),
                ],
              ],
            ),
          ),
          SizedBox(height: 24.h),
          _ActionButton(
            title: AppStrings.ok.tr,
            color: AppColors.primaryButton,
            textColor: AppColors.white,
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.title,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.outlined = false,
    this.outlinedBorderColor,
  });

  final String title;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool outlined;
  final Color? outlinedBorderColor;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: title,
      showBottomInnerShadow: false,
      onPressed: onTap,
      height: 54.h,
      borderRadius: 100.r,
      backgroundColor: color,
      textColor: textColor,
      outlined: outlined,
      outlinedBorderColor: outlinedBorderColor,
      outlinedBorderWidth: outlined ? 1.0 : null,
      outlinedTextColor: textColor,
    );
  }
}
