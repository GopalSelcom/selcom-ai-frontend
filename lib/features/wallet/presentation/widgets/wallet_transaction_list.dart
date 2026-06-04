import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/wallet_transaction_item.dart';
import 'wallet_transaction_row.dart';

class WalletTransactionList extends StatelessWidget {
  const WalletTransactionList({
    super.key,
    required this.items,
    this.scrollController,
    this.padding,
  });

  final List<WalletTransactionItem> items;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: padding ?? EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 120.h),
          Center(
            child: Text(
              AppStrings.noTransactionsYet.tr,
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
      itemCount: items.length,
      itemBuilder: (context, index) =>
          WalletTransactionRow(item: items[index]),
    );
  }
}
