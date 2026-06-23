import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import 'app_shimmer.dart';

/// Document-style shimmer for [WebViewScreen] while page loads.
abstract final class WebViewContentShimmer {
  WebViewContentShimmer._();

  static const List<double> _lineWidthFactors = [
    1.0,
    0.92,
    0.78,
    1.0,
    0.85,
    0.7,
    0.95,
    0.6,
    1.0,
    0.88,
    0.72,
  ];

  static double get lineHeight => 14.h;

  static double get paragraphGap => 16.h;

  static double get lineGap => 10.h;

  static double get contentPadding => 16.w;

  static Widget content() {
    return ColoredBox(
      color: AppColors.pageBackground,
      child: Padding(
        padding: EdgeInsets.all(contentPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_lineWidthFactors.length, (index) {
                  final width = constraints.maxWidth * _lineWidthFactors[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _lineWidthFactors.length - 1
                          ? 0
                          : (index % 4 == 3 ? paragraphGap : lineGap),
                    ),
                    child: AppShimmerBox(
                      width: width,
                      height: lineHeight,
                      borderRadius: 4.r,
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }
}
