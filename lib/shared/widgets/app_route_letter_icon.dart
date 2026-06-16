import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';

/// Circular A/B/C route letter badge (pickup, stops, destination).
class AppRouteLetterIcon extends StatelessWidget {
  const AppRouteLetterIcon({
    super.key,
    required this.letter,
    required this.color,
    this.size,
  });

  final String letter;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dimension = size ?? 24.w;
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: AppColors.white,
          fontSize: (dimension * 0.5).sp,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
