import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared metrics for [RideDetailsScreen] loaded UI and shimmer.
abstract final class RideDetailsScreenLayout {
  static double get scrollHorizontalPadding => 16.w;

  static double get scrollVerticalPadding => 14.h;

  static double get sectionGap => 10.h;

  static double get needHelpTopGap => 13.h;

  static double get scrollBottomGap => 8.h;

  static double get headerVehicleImageWidth => 76.w;

  static double get headerVehicleImageHeight => 50.67.h;

  static double get headerTitleLineHeight => 20.sp * (34 / 20);

  static double get headerDateLineHeight => 15.sp * (20 / 15);

  static double get headerTitleDateGap => 4.h;

  static double get reviewCardPadding => 14.w;

  static double get reviewTitleLineHeight => 15.sp * (20 / 15);

  static double get reviewTitleStarsGap => 12.h;

  static double get reviewStarSize => 37.w;

  static double get locationCardPadding => 16.w;

  static double get locationMarkerSize => 24.w;

  static double get locationTitleLineHeight => 15.sp * (20 / 15);

  static double get locationAddressLineHeight => 12.sp * (20 / 12);

  static double get locationTitleAddressGap => 1.h;

  static double get locationRowConnectorGap => 16.h;

  static double locationRowHeight({required bool hasConnectorBelow}) {
    final content =
        locationTitleLineHeight +
        locationTitleAddressGap +
        locationAddressLineHeight;
    return content + (hasConnectorBelow ? locationRowConnectorGap : 0);
  }

  static double get bookedForIconSize => 36.w;

  static double get bookedForNameLineHeight => 15.sp;

  static double get bookedForPhoneLineHeight => 13.sp;

  static double get bookedForLineGap => 6.h;

  static double get bookedForRowHeight {
    final textBlock =
        bookedForNameLineHeight + bookedForLineGap + bookedForPhoneLineHeight;
    return bookedForIconSize > textBlock ? bookedForIconSize : textBlock;
  }

  static double bookedForRowHeightWithPhone({required bool showPhone}) {
    if (!showPhone) return bookedForIconSize;
    return bookedForRowHeight;
  }

  static double get fareCardPaddingLeft => 14.w;

  static double get fareCardPaddingTop => 14.h;

  static double get fareCardPaddingRight => 11.w;

  static double get fareCardPaddingBottom => 14.h;

  static double get fareTitleLineHeight => 15.sp * (20 / 15);

  static double get fareTitleRowsGap => 6.h;

  static double get fareRowLineHeight => 12.sp * (20 / 12);

  static double get fareRowGap => 4.h;

  static int get defaultFareRowCount => 3;

  static double fareCardContentHeight({
    int fareLineRowCount = 0,
  }) {
    final rowCount = fareLineRowCount > 0
        ? fareLineRowCount.clamp(1, 50)
        : defaultFareRowCount;
    return fareTitleLineHeight +
        fareTitleRowsGap +
        rowCount * fareRowLineHeight +
        (rowCount > 1 ? (rowCount - 1) * fareRowGap : 0);
  }

  static double get needHelpIconSize => 18.w;

  static double get needHelpLineHeight => 20.h;

  static double get primaryButtonHeight => 56.h;

  static double get primaryButtonHorizontalPadding => 16.w;

  static double get primaryButtonBottomPadding => 16.h;
}
