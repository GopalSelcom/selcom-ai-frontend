import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class AppShadows {
  static List<BoxShadow> primary = [
    BoxShadow(
      color: AppColors.drawerWhiteColor,
      spreadRadius: 5,
      blurRadius: 7,
      offset: Offset(0, 3),
    ),
  ];

  static List<BoxShadow> secondary = [
    BoxShadow(
      color: AppColors.drawerWhiteColor,
      blurRadius: 5,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];
  // static List<BoxShadow> secondary = [
  //   BoxShadow(
  //     color: Colors.black.withValues(alpha: 0.03),
  //     blurRadius: 5,
  //     offset: const Offset(0, 2),
  //   ),
  //   BoxShadow(
  //     color: Colors.black.withValues(alpha: 0.08),
  //     blurRadius: 8,
  //     offset: const Offset(0, 8),
  //   ),
  // ];
}
