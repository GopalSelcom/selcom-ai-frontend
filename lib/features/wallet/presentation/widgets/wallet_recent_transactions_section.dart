import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_cupertino_text_button.dart';
import '../models/wallet_transaction_item.dart';
import 'wallet_transaction_row.dart';

class WalletRecentTransactionsSection extends StatelessWidget {
  const WalletRecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onViewAll,
    this.onRefresh,
  });

  final List<WalletTransactionItem> transactions;
  final VoidCallback onViewAll;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.recentTransactions.tr,
                style: AppTextStyles.homeSubtitle,
              ),
            ),
            AppCupertinoTextButton(
              label: AppStrings.viewAll.tr,
              onPressed: onViewAll,
              textStyle: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.walletCardText,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (transactions.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 48.h),
            child: Center(
              child: Text(
                AppStrings.noTransactionsYet.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
          )
        else
          ...transactions.map(
            (item) => WalletTransactionRow(item: item),
          ),
      ],
    );

    if (onRefresh == null) {
      return list;
    }

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: list,
    );
  }
}
