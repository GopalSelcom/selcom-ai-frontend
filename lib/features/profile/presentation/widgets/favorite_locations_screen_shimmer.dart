import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'favorite_locations_screen_layout.dart';

/// Content-section shimmer for [FavoriteLocationsScreen].
abstract final class FavoriteLocationsScreenShimmer {
  FavoriteLocationsScreenShimmer._();

  static Widget listContent() {
    return Padding(
      padding: EdgeInsets.all(FavoriteLocationsScreenLayout.listPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          FavoriteLocationsScreenLayout.shimmerTileCount,
          (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index <
                        FavoriteLocationsScreenLayout.shimmerTileCount - 1
                    ? FavoriteLocationsScreenLayout.tileSeparatorGap
                    : 0,
              ),
              child: locationTile(),
            );
          },
        ),
      ),
    );
  }

  static Widget locationTile() {
    return Container(
      height: FavoriteLocationsScreenLayout.tileHeight,
      padding: EdgeInsets.all(FavoriteLocationsScreenLayout.tilePadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(
          FavoriteLocationsScreenLayout.tileBorderRadius,
        ),
        border: Border.all(color: AppColors.divider),
      ),
      child: AppShimmer(
        child: Row(
          children: [
            AppShimmerBox(
              width: FavoriteLocationsScreenLayout.tileIconSize,
              height: FavoriteLocationsScreenLayout.tileIconSize,
              borderRadius:
                  FavoriteLocationsScreenLayout.tileIconSize / 2,
            ),
            SizedBox(width: FavoriteLocationsScreenLayout.tileIconTextGap),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: FavoriteLocationsScreenLayout.tileTextHeartGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppShimmerBox(
                      width: 120.w,
                      height:
                          FavoriteLocationsScreenLayout.tileTitleLineHeight,
                      borderRadius: 4.r,
                    ),
                    SizedBox(
                      height:
                          FavoriteLocationsScreenLayout.tileTitleAddressGap,
                    ),
                    AppShimmerBox(
                      width: double.infinity,
                      height:
                          FavoriteLocationsScreenLayout.tileAddressLineHeight,
                      borderRadius: 4.r,
                    ),
                  ],
                ),
              ),
            ),
            AppShimmerBox(
              width: FavoriteLocationsScreenLayout.tileHeartIconSize,
              height: FavoriteLocationsScreenLayout.tileHeartIconSize,
              borderRadius: 4.r,
            ),
          ],
        ),
      ),
    );
  }
}
