import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/wallet_transaction_filter.dart';

class WalletSegmentedTabs extends StatelessWidget {
  const WalletSegmentedTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.labelForFilter,
  });

  final WalletTransactionFilter selectedFilter;
  final ValueChanged<WalletTransactionFilter> onFilterSelected;
  final String Function(WalletTransactionFilter filter) labelForFilter;

  static const List<WalletTransactionFilter> filters = [
    WalletTransactionFilter.all,
    WalletTransactionFilter.received,
    WalletTransactionFilter.sent,
  ];

  int get _selectedIndex {
    final index = filters.indexOf(selectedFilter);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackPadding = 4.w;
        final innerWidth = constraints.maxWidth - (trackPadding * 2);
        final tabWidth = innerWidth / filters.length;

        return Container(
          height: 48.h,
          padding: EdgeInsets.all(trackPadding),
          decoration: BoxDecoration(
            color: AppColors.bgSoftCircle,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: tabWidth * _selectedIndex,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(17.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textHeading.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: filters.map((filter) {
                  final isSelected = filter == selectedFilter;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onFilterSelected(filter),
                      child: Center(
                        child: Text(
                          labelForFilter(filter),
                          style: AppTextStyles.homeChip.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.walletTabLabelActive
                                : AppColors.walletTabLabelInactive,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
