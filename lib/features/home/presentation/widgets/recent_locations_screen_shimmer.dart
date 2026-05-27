import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'recent_location_tile_layout.dart';
import 'recent_locations_screen_layout.dart';

/// Shimmer for [RecentLocationsScreen] only — mirrors [RecentLocationTile] layout.
abstract final class RecentLocationsScreenShimmer {
  RecentLocationsScreenShimmer._();

  static Widget listContent() {
    const count = RecentLocationsScreenLayout.shimmerRowCount;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: RecentLocationsScreenLayout.listHorizontalPadding,
        vertical: RecentLocationsScreenLayout.listVerticalPadding,
      ),
      children: [
        for (var i = 0; i < count; i++) ...[
          _recentLocationRow(),
          if (i < count - 1) listSeparator(),
        ],
      ],
    );
  }

  static Widget listSeparator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1.h, color: AppColors.bgSoftCircle),
        SizedBox(height: RecentLocationsScreenLayout.itemSeparatorHeight),
      ],
    );
  }

  static Widget _recentLocationRow() {
    return AppShimmer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            constraints: BoxConstraints(
              minWidth: RecentLocationTileLayout.leadingMinWidth,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: RecentLocationTileLayout.leadingPaddingHorizontal,
              vertical: RecentLocationTileLayout.leadingPaddingVertical,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmerBox(
                  width: RecentLocationTileLayout.leadingIconSize,
                  height: RecentLocationTileLayout.leadingIconSize,
                  borderRadius: 6.r,
                ),
                SizedBox(height: RecentLocationTileLayout.leadingIconDistanceGap),
                AppShimmerBox(
                  width: 32.w,
                  height: RecentLocationTileLayout.leadingDistanceLineHeight,
                  borderRadius: 6.r,
                ),
              ],
            ),
          ),
          SizedBox(width: RecentLocationTileLayout.leadingToTextGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmerBox(
                  width: 130.w,
                  height: RecentLocationTileLayout.titleLineHeight,
                  borderRadius: 8.r,
                ),
                SizedBox(height: RecentLocationTileLayout.titleToAddressGap),
                AppShimmerBox(
                  width: double.infinity,
                  height: RecentLocationTileLayout.addressLineHeight,
                  borderRadius: 8.r,
                ),
              ],
            ),
          ),
          SizedBox(
            width: RecentLocationTileLayout.favoriteButtonSize,
            height: RecentLocationTileLayout.favoriteButtonSize,
            child: Center(
              child: AppShimmerBox(
                width: RecentLocationTileLayout.favoriteIconWidth,
                height: RecentLocationTileLayout.favoriteIconHeight,
                borderRadius: 6.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
