import 'package:flutter/material.dart';

import 'app_shimmer.dart';

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
    return AppShimmer(
      child: AppShimmerBox(
        width: width,
        height: height ?? 20,
        borderRadius: borderRadius,
      ),
    );
  }
}
