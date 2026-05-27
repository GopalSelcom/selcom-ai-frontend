import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared metrics for ride-started bottom sheet loaded UI and shimmer.
abstract final class DriverAcceptedRideStartedLayout {
  DriverAcceptedRideStartedLayout._();

  static double get progressTitleLineHeight => 20.sp * (34 / 20);

  static double get vehicleLabelLineHeight => 20.sp * (34 / 20);

  static double get subtitleLineHeight => 15.sp * (20 / 15);

  static double get vehicleImageWidth => 76.w;

  static double get vehicleImageHeight => 60.67.h;

  static double get etaBadgeHorizontalPadding => 5.05.w;

  static double get etaBadgeVerticalPadding => 3.03.h;

  static double get etaBadgeHeight =>
      (etaBadgeVerticalPadding * 2) + subtitleLineHeight;

  static double get headerRowHeight => vehicleImageHeight;

  static double headerTextColumnHeight({required bool showEtaBadge}) {
    if (showEtaBadge) {
      final secondLine = subtitleLineHeight > etaBadgeHeight
          ? subtitleLineHeight
          : etaBadgeHeight;
      return vehicleLabelLineHeight + secondLine;
    }
    return vehicleLabelLineHeight + subtitleLineHeight;
  }

  static double get headerToLocationsGap => 7.94.h;

  static double get locationsToFareGap => 8.h;

  static double get bodyBottomGap => 12.h;

  static double get locationCardPaddingH => 12.w;

  static double get locationCardPaddingV => 15.h;

  static double get locationMarkerSize => 24.w;

  static double get locationTitleLineHeight => 15.sp * (20 / 15);

  static double get locationAddressLineHeight => 12.sp * (20 / 12);

  static double get locationTitleAddressGap => 1.h;

  static double get locationRowBottomPadding => 16.h;

  static double get changeDropLinkLineHeight => 12.sp * (20 / 12);

  static double locationRowHeight({
    required bool hasConnectorBelow,
    bool showChangeDropFooter = false,
  }) {
    var height =
        locationTitleLineHeight +
        locationTitleAddressGap +
        locationAddressLineHeight;
    if (hasConnectorBelow) {
      height += locationRowBottomPadding;
    }
    if (showChangeDropFooter) {
      height += changeDropLinkLineHeight;
    }
    return height;
  }

  static double locationsContentHeight({required bool showChangeDropLink}) {
    return locationRowHeight(hasConnectorBelow: true) +
        locationRowHeight(
          hasConnectorBelow: false,
          showChangeDropFooter: showChangeDropLink,
        );
  }

  static double get fareCardPaddingLeft => 14.w;

  static double get fareCardPaddingTop => 14.h;

  static double get fareCardPaddingRight => 11.w;

  static double get fareCardPaddingBottom => 24.h;

  static double get fareTitleLineHeight => 15.sp * (20 / 15);

  static double get fareTitleRowsGap => 6.h;

  static double get fareRowLineHeight => 12.sp * (20 / 12);

  static double get fareRowGap => 4.h;

  static int get fareRowCount => 4;

  static double get fareContentHeight =>
      fareTitleLineHeight +
      fareTitleRowsGap +
      (fareRowCount * fareRowLineHeight) +
      ((fareRowCount - 1) * fareRowGap);
}
