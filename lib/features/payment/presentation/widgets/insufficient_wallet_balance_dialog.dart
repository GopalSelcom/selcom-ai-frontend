import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_cupertino_text_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../domain/models/insufficient_wallet_balance_details.dart';

/// Insufficient wallet balance before book ride (Figma alert).
class InsufficientWalletBalanceDialog extends StatelessWidget {
  const InsufficientWalletBalanceDialog({
    super.key,
    required this.details,
    required this.onTopUp,
    required this.onDismiss,
  });

  final InsufficientWalletBalanceDetails details;
  final VoidCallback onTopUp;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WarningIcon(),
            SizedBox(height: 4.h),
            Text(
              AppStrings.insufficientBalanceTitle.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTitle,
            ),
            SizedBox(height: 4.h),
            Text(
              AppStrings.insufficientBalanceMessage.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeSubtitle,
            ),
            SizedBox(height: 21.h),
            _AmountBreakdownCard(details: details),
            SizedBox(height: 24.h),
            AppPrimaryButton(
              label: AppStrings.topUpWallet.tr,
              onPressed: onTopUp,
              width: double.infinity,
              borderRadius: 24.r,
            ),
            AppCupertinoTextButton.insufficientBalanceDismiss(
              label: AppStrings.no.tr,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72.w,
      height: 72.w,
      decoration: const BoxDecoration(
        color: Color(0xffFFE2E2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.error_outline,
        color: const Color(0xffFB2C36),
        size: 36.sp,
      ),
    );
  }
}

class _AmountBreakdownCard extends StatelessWidget {
  const _AmountBreakdownCard({required this.details});

  final InsufficientWalletBalanceDetails details;

  @override
  Widget build(BuildContext context) {
    final currency = details.currency;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.bgWalletCard,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          _BalanceRow(
            label: AppStrings.currentBalanceLabel.tr,
            value: CurrencyFormatter.formatWithApiCurrency(
              details.currentBalance,
              currency,
            ),
            valueColor: const Color(0xff101828),
          ),
          SizedBox(height: 12.h),
          _BalanceRow(
            label: AppStrings.requiredAmountLabel.tr,
            value: CurrencyFormatter.formatWithApiCurrency(
              details.requiredAmount,
              currency,
            ),
            valueColor: const Color(0xff101828),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(height: 1.h, color: AppColors.divider),
          ),
          _BalanceRow(
            label: AppStrings.amountNeededLabel.tr,
            value: CurrencyFormatter.formatWithApiCurrency(
              details.amountNeeded,
              currency,
            ),
            valueColor: AppColors.iconHeartFilled,
            valueWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueWeight = FontWeight.w600,
  });

  final String label;
  final String value;
  final Color valueColor;
  final FontWeight valueWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.homeSubtitle)),
        Text(
          value,
          style: AppTextStyles.homeSubtitle.copyWith(
            fontWeight: valueWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
