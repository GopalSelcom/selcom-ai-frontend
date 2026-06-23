import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared metrics for [MyRidesScreen] loaded UI and shimmer.
abstract final class MyRidesScreenLayout {
  static const int shimmerRideCardCount = 4;

  /// Cards shown at the list bottom while paginating.
  static const int lazyLoadShimmerCardCount = 1;

  static double get listHorizontalPadding => 16.w;

  static double get listVerticalPadding => 18.h;

  static double get sectionTitleHorizontalInset => 4.w;

  static double get sectionTitleHeight => 20.h;

  static double get sectionTitleBottomGap => 9.h;

  static double get rideCardBottomMargin => 12.h;
}
