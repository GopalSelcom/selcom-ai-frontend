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
    this.onRefresh,
  });

  final List<WalletTransactionItem> items;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ?? EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h);
    final listBody = _buildListBody(resolvedPadding);

    if (onRefresh == null) {
      return listBody;
    }

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: listBody,
    );
  }

  Widget _buildListBody(EdgeInsetsGeometry resolvedPadding) {
    if (items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: resolvedPadding,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: Text(
                  AppStrings.noTransactionsYet.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: resolvedPadding,
      itemCount: items.length,
      itemBuilder: (context, index) => WalletTransactionRow(item: items[index]),
    );
  }
}
