import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Layout metrics for [RecentLocationTile] on [RecentLocationsScreen] shimmer only.
abstract final class RecentLocationTileLayout {
  RecentLocationTileLayout._();

  static double get leadingMinWidth => 52.w;

  static double get leadingPaddingHorizontal => 4.w;

  static double get leadingPaddingVertical => 8.h;

  static double get leadingIconSize => 21.sp;

  static double get leadingIconDistanceGap => 2.h;

  static double get leadingDistanceLineHeight => 12.sp;

  static double get leadingToTextGap => 16.w;

  static double get titleLineHeight => 16.sp * (20 / 15);

  static double get titleToAddressGap => 2.h;

  static double get addressLineHeight => 14.sp;

  static double get favoriteButtonSize => 48.w;

  static double get favoriteIconWidth => 21.w;

  static double get favoriteIconHeight => 19.h;
}