import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/app_shimmer.dart';

/// Shimmer for the map address card — same layout as loaded header (icon + 2 lines).
class HomeAddressHeaderSkeleton extends StatelessWidget {
  const HomeAddressHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        children: [
          AppShimmerBox(
            width: 28.w,
            height: 28.w,
            borderRadius: 8.r,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppShimmerBox(
                  width: 108.w,
                  height: 15.h,
                  borderRadius: 4.r,
                ),
                SizedBox(height: 4.h),
                AppShimmerBox(
                  height: 15.h,
                  borderRadius: 4.r,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
