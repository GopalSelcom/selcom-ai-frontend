import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_adaptive_bottom_safe_scaffold.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../controllers/wallet_history_controller.dart';
import '../widgets/wallet_segmented_tabs.dart';
import '../widgets/wallet_transaction_list.dart';

class WalletHistoryScreen extends GetView<WalletHistoryController> {
  const WalletHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveBottomSafeScaffold(
      backgroundColor: AppColors.white,
      hasBottomWidget: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppProfileHeader(title: AppStrings.recentTransactionTitle.tr),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Obx(
              () => WalletSegmentedTabs(
                selectedFilter: controller.selectedFilter.value,
                onFilterSelected: controller.selectFilter,
                labelForFilter: controller.filterLabel,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _HistoryShimmer();
              }

              final initialIndex = WalletSegmentedTabs.filters.indexOf(
                controller.selectedFilter.value,
              );

              return Swiper(
                controller: controller.swiperController,
                index: initialIndex < 0 ? 0 : initialIndex,
                loop: false,
                itemCount: WalletSegmentedTabs.filters.length,
                onIndexChanged: controller.onSwiperIndexChanged,
                itemBuilder: (context, index) {
                  final filter = WalletSegmentedTabs.filters[index];
                  return WalletTransactionList(
                    items: controller.transactionsForFilter(filter),
                    onRefresh: controller.refreshTransactions,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HistoryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        children: List.generate(
          5,
          (_) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: AppShimmerBox(
              height: 88.h,
              width: double.infinity,
              borderRadius: 16.r,
            ),
          ),
        ),
      ),
    );
  }
}
