import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared MediaQuery helpers for ride draggable sheets (finding / accepted).
///
/// Keeps nav-bar inset math in one place so both screens stay aligned.
abstract final class RideSheetLayout {
  RideSheetLayout._();

  static double systemBottomInsetPx(BuildContext context) {
    final mq = MediaQuery.of(context);
    final paddingBottom = mq.padding.bottom;
    final viewBottom = mq.viewPadding.bottom;
    return paddingBottom > viewBottom ? paddingBottom : viewBottom;
  }

  /// Slightly taller sheet sizes when a system nav bar is present.
  static double sizeWithNavInset(BuildContext context, double base) {
    final inset = systemBottomInsetPx(context);
    final h = MediaQuery.sizeOf(context).height;
    if (inset <= 0 || h <= 0) return base;
    return base + (inset / h) * 0.55;
  }

  static double scrollBottomPad(BuildContext context) {
    return systemBottomInsetPx(context) > 0 ? 2.h : 0;
  }
}
