import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_spacing.dart';

/// Shared metrics for [LoginSupportScreen] loaded UI and shimmer.
abstract final class LoginSupportScreenLayout {
  static double get horizontalPadding => 24.w;

  static double get sectionGap => 16.h;

  static double get labelFieldGap => 8.h;

  static double get fieldLabelLineHeight => 15.sp * (20 / 15);

  static double get singleLineFieldVerticalPadding => 18.h;

  static double get singleLineFieldLineHeight => 14.sp * (20 / 14);

  static double get singleLineFieldHeight =>
      singleLineFieldVerticalPadding * 2 + singleLineFieldLineHeight;

  static double get singleLineFieldBorderRadius => AppRadius.input;

  static double get reasonFieldVerticalPadding => 14.h;

  static double get reasonFieldLineHeight => 14.sp * (20 / 14);

  static double get reasonFieldHeight =>
      reasonFieldVerticalPadding * 2 + reasonFieldLineHeight;

  static double get reasonFieldBorderRadius => AppRadius.input;

  static int get messageFieldMaxLines => 5;

  static double get messageFieldLineHeight => 15.sp * (22 / 15);

  static double get messageFieldVerticalPadding => 14.h;

  static double get messageFieldHeight =>
      messageFieldVerticalPadding * 2 +
      messageFieldLineHeight * messageFieldMaxLines;

  static double get messageFieldBorderRadius => AppRadius.input;

  static double get phoneChipWidth => 72.w;

  static double get phoneChipHeight => 28.h;

  static double get phoneChipGap => 8.w;

  static double get phoneFieldInnerPadding => 12.w;
}
