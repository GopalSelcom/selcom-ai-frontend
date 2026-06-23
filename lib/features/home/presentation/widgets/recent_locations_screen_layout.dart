import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared metrics for [RecentLocationsScreen] loaded UI and shimmer.
abstract final class RecentLocationsScreenLayout {
  static double get listHorizontalPadding => 24.w;

  static double get listVerticalPadding => 20.h;

  /// Matches `RecentLocationsScreen` separator spacing (`SizedBox(height: 20.h)`).
  static const double itemSeparatorGap = 20;

  static double get itemSeparatorHeight => itemSeparatorGap.h;

  /// Full list placeholder count on view-more screen.
  static const int shimmerRowCount = 6;
}
