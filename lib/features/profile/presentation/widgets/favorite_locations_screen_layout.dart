import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared metrics for [FavoriteLocationsScreen] loaded UI and shimmer.
abstract final class FavoriteLocationsScreenLayout {
  static double get listPadding => 16.w;

  static double get tileSeparatorGap => 12.h;

  static const int shimmerTileCount = 4;

  static double get tilePadding => 12.w;

  static double get tileBorderRadius => 16.r;

  static double get tileIconSize => 44.w;

  static double get tileIconTextGap => 12.w;

  static double get tileTitleLineHeight => 14.sp * (20 / 14);

  static double get tileAddressLineHeight => 12.sp * (20 / 12);

  static double get tileTitleAddressGap => 4.h;

  static double get tileHeartIconSize => 24.w;

  /// Space between subtitle and heart (matches [IconButton] inset on loaded tile).
  static double get tileTextHeartGap => 12.w;

  static double get tileContentHeight {
    final textBlock =
        tileTitleLineHeight + tileTitleAddressGap + tileAddressLineHeight;
    return tileIconSize > textBlock ? tileIconSize : textBlock;
  }

  static double get tileHeight => tilePadding * 2 + tileContentHeight;
}
