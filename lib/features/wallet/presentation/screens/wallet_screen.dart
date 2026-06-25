import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/wallet_info_card.dart';
import '../widgets/wallet_recent_transactions_section.dart';

class WalletScreen extends GetView<WalletController> {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppProfileHeader(
            title: AppStrings.wallet.tr,
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _WalletShimmer();
              }
              return Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WalletInfoCard(
                      balanceText: controller.formattedBalance,
                      walletNumberText: controller.formattedWalletNumber,
                      onCopyWalletNumber: controller.copyWalletNumber,
                      onAddMoney: controller.openAddMoney,
                      onEStatement: controller.openEStatement,
                    ),
                    SizedBox(height: 20.h),
                    Expanded(
                      child: WalletRecentTransactionsSection(
                        transactions: controller.recentTransactions,
                        onViewAll: controller.openTransactionHistory,
                        onRefresh: controller.refreshWallet,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WalletShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppShimmerBox(
              height: 210.h,
              width: double.infinity,
              borderRadius: 20.r,
            ),
            SizedBox(height: 24.h),
            AppShimmerBox(height: 18.h, width: 160.w, borderRadius: 8.r),
            SizedBox(height: 16.h),
            ...List.generate(
              3,
              (_) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AppShimmerBox(
                  height: 88.h,
                  width: double.infinity,
                  borderRadius: 16.r,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
