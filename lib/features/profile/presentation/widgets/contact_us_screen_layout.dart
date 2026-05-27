import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared metrics for [ContactUsScreen] loaded UI and shimmer.
abstract final class ContactUsScreenLayout {
  static double get horizontalPadding => 24.w;

  static double get headerBottomGap => 16.h;

  static double get fieldLabelLineHeight => 15.sp * (20 / 15);

  static double get labelFieldGap => 8.h;

  static double get reasonFieldVerticalPadding => 14.h;

  static double get reasonFieldLineHeight => 14.sp * (20 / 14);

  static double get reasonFieldHeight =>
      reasonFieldVerticalPadding * 2 + reasonFieldLineHeight;

  static double get reasonFieldBorderRadius => 12.r;

  static int get messageFieldMaxLines => 5;

  static double get messageFieldLineHeight => 15.sp * (22 / 15);

  static double get messageFieldVerticalPadding => 14.h;

  static double get messageFieldHeight =>
      messageFieldVerticalPadding * 2 +
      messageFieldLineHeight * messageFieldMaxLines;

  static double get messageFieldBorderRadius => 12.r;

  static double get contentHeight =>
      fieldLabelLineHeight +
      labelFieldGap +
      reasonFieldHeight +
      labelFieldGap +
      fieldLabelLineHeight +
      labelFieldGap +
      messageFieldHeight;
}
