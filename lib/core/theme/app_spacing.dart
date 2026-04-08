import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSpacing {
  static double xs  = 4.0.w;
  static double sm  = 8.0.w;
  static double md  = 16.0.w;
  static double lg  = 24.0.w;
  static double xl  = 32.0.w;
  static double xxl = 48.0.w;

  // Page padding
  static EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16.0.w);
  static EdgeInsets pageVertical = EdgeInsets.symmetric(vertical: 16.0.h);

  // Bottom sheet
  static EdgeInsets sheetPadding = EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h);
}

class AppRadius {
  static double button     = 100.0.r;  // Fully rounded pill
  static double card       = 12.0.r;   // Cards, vehicle options
  static double input      = 12.0.r;   // Text fields
  static double chip       = 100.0.r;  // Category chips (pill)
  static double modal      = 16.0.r;   // Center modals
  static double bottomSheet= 24.0.r;   // Bottom sheets (top corners only)
  static double small      = 8.0.r;    // Small components
}
