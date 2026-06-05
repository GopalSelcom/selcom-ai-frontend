import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'profile_screen_layout.dart';
import 'wallet_summary_card.dart';

/// Shimmer placeholders for [ProfileScreen] initial load.
abstract final class ProfileScreenShimmer {
  ProfileScreenShimmer._();

  /// Matches [_buildNormalModeContent] user row + wallet card.
  static Widget headerContent() {
    return Column(
      key: const ValueKey('profile_header_shimmer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ProfileScreenLayout.userInfoPadding,
          child: SizedBox(
            height: ProfileScreenLayout.userRowHeight,
            child: AppShimmer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppShimmerBox(
                    width: ProfileScreenLayout.avatarSize,
                    height: ProfileScreenLayout.avatarSize,
                    borderRadius: ProfileScreenLayout.avatarSize / 2,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(child: _userTextBlockShimmer()),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: ProfileScreenLayout.walletPadding,
          child: SizedBox(
            height: ProfileScreenLayout.walletCardHeight,
            child: walletCard(),
          ),
        ),
      ],
    );
  }

  static Widget _userTextBlockShimmer() {
    return SizedBox(
      height: ProfileScreenLayout.userTextBlockHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: ProfileScreenLayout.nameRowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppShimmerBox(
                width: 168.w,
                height: ProfileScreenLayout.nameRowHeight,
                borderRadius: 8.r,
              ),
            ),
          ),
          SizedBox(
            height: ProfileScreenLayout.phoneLineHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppShimmerBox(
                width: 128.w,
                height: 14.h,
                borderRadius: 6.r,
              ),
            ),
          ),
          SizedBox(height: ProfileScreenLayout.ratingGap),
          SizedBox(
            height: ProfileScreenLayout.ratingRowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppShimmerBox(
                width: 52.w,
                height: ProfileScreenLayout.ratingRowHeight,
                borderRadius: 6.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget walletCard() => const WalletSummaryCard(
    balance: '',
    walletNumber: '',
    isLoading: true,
  );

  /// Menu block height matches [itemCount] (same as loaded settings list).
  static Widget settingsMenu({required int itemCount}) {
    final count = itemCount.clamp(1, ProfileScreenLayout.maxMenuItemCount);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        count,
        (index) => _menuItemRow(isLast: index == count - 1),
      ),
    );
  }

  /// Matches profile logout row below settings.
  static Widget logoutButton() {
    return AppShimmer(
      child: Container(
        height: ProfileScreenLayout.logoutButtonHeight,
        padding: EdgeInsets.symmetric(
          horizontal: ProfileScreenLayout.logoutHorizontalPadding,
          vertical: ProfileScreenLayout.logoutVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(
            ProfileScreenLayout.logoutBorderRadius,
          ),
        ),
        child: Row(
          children: [
            AppShimmerBox(width: 24.w, height: 24.w, borderRadius: 8.r),
            SizedBox(width: 7.w),
            AppShimmerBox(width: 72.w, height: 15.h, borderRadius: 6.r),
          ],
        ),
      ),
    );
  }

  static Widget _menuItemRow({required bool isLast}) {
    return AppShimmer(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 8.w,
              bottom: ProfileScreenLayout.menuRowPaddingBottom,
            ),
            child: SizedBox(
              height: ProfileScreenLayout.menuRowContentHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppShimmerBox(width: 24.w, height: 24.w, borderRadius: 8.r),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: AppShimmerBox(height: 15.h, borderRadius: 6.r),
                  ),
                  AppShimmerBox(width: 18.w, height: 18.w, borderRadius: 6.r),
                ],
              ),
            ),
          ),
          if (!isLast) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            SizedBox(height: 17.h),
          ],
        ],
      ),
    );
  }
}
