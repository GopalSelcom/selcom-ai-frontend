import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SafeSpacing {
  static double bottom = 0;
  static double top = 0;
  static double left = 0;
  static double right = 0;

  static getSpacing(MediaQueryData mediaQuery) {
    bottom = _getBottom(mediaQuery);
    top = _getTop(mediaQuery);
    left = _getLeft(mediaQuery);
    right = _getRight(mediaQuery);
  }

  static double _getBottom(MediaQueryData mediaQuery) {
    double space = 13.sp;

    if (Platform.isAndroid) {
      final padding = mediaQuery.viewPadding.bottom;
      if (padding > 24) {
        space = space + padding;
      } else {
        space = space + (mediaQuery.viewPadding.bottom / 4);
      }
    } else {
      space = space + (mediaQuery.viewPadding.bottom / 4);
    }

    return space;
  }

  static double _getTop(MediaQueryData mediaQuery) {
    return mediaQuery.padding.top;
  }

  static double _getLeft(MediaQueryData mediaQuery) {
    return mediaQuery.padding.left;
  }

  static double _getRight(MediaQueryData mediaQuery) {
    return mediaQuery.padding.right;
  }
}
