import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class AppSkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const AppSkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.pageBackground,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 20,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
      ),
    );
  }
}
