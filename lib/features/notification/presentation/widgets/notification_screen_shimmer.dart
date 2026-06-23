import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/widgets/app_shimmer.dart';

/// Shimmer placeholders for notification list initial load.
abstract final class NotificationScreenShimmer {
  NotificationScreenShimmer._();

  static Widget listContent({int itemCount = 5}) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, __) => _notificationCard(),
    );
  }

  static Widget _notificationCard() {
    return AppShimmer(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox(width: 40.w, height: 40.w, borderRadius: 20.r),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox(
                    width: double.infinity,
                    height: 14.h,
                    borderRadius: 4.r,
                  ),
                  SizedBox(height: 8.h),
                  AppShimmerBox(width: 180.w, height: 12.h, borderRadius: 4.r),
                  SizedBox(height: 8.h),
                  AppShimmerBox(width: 72.w, height: 10.h, borderRadius: 4.r),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
