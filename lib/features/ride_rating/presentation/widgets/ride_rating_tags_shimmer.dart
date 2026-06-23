import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/app_shimmer.dart';

/// Shimmer placeholders for review tag chips while tags load.
abstract final class RideRatingTagsShimmer {
  RideRatingTagsShimmer._();

  static const List<double> _chipWidthFactors = [
    0.22,
    0.28,
    0.18,
    0.24,
    0.2,
    0.26,
  ];

  static double get chipHeight => 38.h;

  static double get chipBorderRadius => 999.r;

  static Widget tagChips({int count = 6}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return AppShimmer(
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(count, (index) {
              final widthFactor =
                  _chipWidthFactors[index % _chipWidthFactors.length];
              final width = (maxWidth * widthFactor).clamp(72.w, 160.w);
              return AppShimmerBox(
                width: width,
                height: chipHeight,
                borderRadius: chipBorderRadius,
              );
            }),
          ),
        );
      },
    );
  }
}
