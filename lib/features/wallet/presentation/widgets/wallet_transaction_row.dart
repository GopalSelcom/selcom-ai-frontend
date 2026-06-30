import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/wallet_transaction_item.dart';
import '../utils/wallet_format_utils.dart';

class WalletTransactionRow extends StatelessWidget {
  const WalletTransactionRow({super.key, required this.item});

  final WalletTransactionItem item;

  @override
  Widget build(BuildContext context) {
    final amountText = formatWalletTransactionAmount(
      amount: item.amount,
      isCredit: item.isCredit,
      currency: item.currency,
      showSign: item.showAmountSign,
    );
    final amountColor = !item.showAmountSign
        ? AppColors.black
        : item.isCredit
        ? AppColors.success
        : AppColors.iconHeartFilled;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.fromLTRB(23.w, 13.h, 10.w, 14.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.merchantName,
                  style: AppTextStyles.homeSubtitle.copyWith(
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(item.categoryLabel, style: AppTextStyles.homeSubtitle),
                SizedBox(height: 2.h),
                Text(item.createdAtLabel, style: AppTextStyles.homeSubtitle),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            amountText,
            textAlign: TextAlign.end,
            style: AppTextStyles.homeSubtitle.copyWith(
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
