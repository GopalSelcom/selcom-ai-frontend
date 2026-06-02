import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Content-section shimmer for [SelectSavedLocationScreen].
/// Card shells match loaded tiles; inner boxes shimmer individual content.
abstract final class SelectSavedLocationScreenShimmer {
  SelectSavedLocationScreenShimmer._();

  static const int _recentTileCount = 4;
  static const int _suggestionTileCount = 3;

  static Widget recentList() {
    return _tileList(itemCount: _recentTileCount, showFavorite: true);
  }

  static Widget suggestionsList() {
    return _tileList(itemCount: _suggestionTileCount, showFavorite: false);
  }

  static Widget _tileList({
    required int itemCount,
    required bool showFavorite,
  }) {
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const ClampingScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => locationTile(showFavorite: showFavorite),
    );
  }

  /// Matches [SelectSavedLocationScreen._locationTile] layout.
  static Widget locationTile({bool showFavorite = false}) {
    const iconSize = 20.0;
    const iconPadding = 8.0;
    final circleSize = (iconPadding * 2) + iconSize;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderWalletCard, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppShimmer(
        child: Row(
          children: [
            Container(
              width: circleSize.w,
              height: circleSize.w,
              padding: EdgeInsets.all(iconPadding.w),
              decoration: const BoxDecoration(
                color: AppColors.bgSoftCircle,
                shape: BoxShape.circle,
              ),
              child: AppShimmerBox(
                width: iconSize.w,
                height: iconSize.w,
                borderRadius: iconSize.w / 2,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox(width: 140.w, height: 15.sp, borderRadius: 4.r),
                  SizedBox(height: 4.h),
                  AppShimmerBox(
                    width: double.infinity,
                    height: 13.sp,
                    borderRadius: 4.r,
                  ),
                ],
              ),
            ),
            if (showFavorite)
              AppShimmerBox(width: 22.w, height: 22.w, borderRadius: 11.r),
          ],
        ),
      ),
    );
  }
}
