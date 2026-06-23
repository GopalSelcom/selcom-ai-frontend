import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared layout metrics for home bottom sheet (loaded UI + shimmer).
abstract final class HomeSheetLayout {
  static const double horizontalPadding = 16;
  static const double vehicleRowHeight = 96;

  static const double sectionGap = 12;
  static const double titleContentGap = 10;
  static const double recentItemGap = 12;

  /// Placeholder rows while [isLoadingHomeData] (matches preview cap).
  static const int shimmerRecentRowCount = 3;
  static const int shimmerVehicleCount = 3;

  /// Handle (12+5+8) + search row (~51) ≈ header block in estimates.
  static double get headerBlockHeight => 12.h + 5.h + 8.h + 51.h;

  static double get chipsRowHeight => 46.h;

  static double get sectionTitleHeight => 16.h;

  /// Matches [RecentLocationTile] row height (icon column + heart control).
  static double get recentRowHeight => 56.h;

  static double get recentDividerBlockHeight =>
      recentItemGap.h + 1.h + recentItemGap.h;

  static double estimatedContentHeight({
    required bool includeRecent,
    required int recentRowCount,
    required bool includeVehicles,
    required double bottomPadding,
  }) {
    var h = headerBlockHeight + chipsRowHeight;

    if (includeRecent && recentRowCount > 0) {
      h += sectionGap.h + sectionTitleHeight + titleContentGap.h;
      h += recentRowCount * recentRowHeight;
      if (recentRowCount > 1) {
        h += (recentRowCount - 1) * recentDividerBlockHeight;
      }
    }

    if (includeVehicles) {
      h += sectionGap.h + sectionTitleHeight + titleContentGap.h;
      h += vehicleRowHeight.h;
    }

    return h + bottomPadding;
  }
}
