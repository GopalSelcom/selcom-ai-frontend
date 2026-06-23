import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../shared/widgets/app_shimmer.dart';

/// Shimmer placeholders for settings / safety screens during initial load.
abstract final class SettingsScreenShimmer {
  SettingsScreenShimmer._();

  static Widget settingsMenu() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      children: [
        AppShimmer(
          child: Container(
            padding: EdgeInsets.fromLTRB(10.w, 19.h, 10.w, 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                _menuRow(),
                SizedBox(height: 8.h),
                _menuRow(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget safetyContent() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      children: [
        AppShimmer(child: AppShimmerBox(width: double.infinity, height: 14.h)),
        SizedBox(height: 14.h),
        AppShimmer(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppShimmerBox(width: 36.w, height: 36.w, borderRadius: 10.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: AppShimmerBox(
                        width: double.infinity,
                        height: 16.h,
                        borderRadius: 4.r,
                      ),
                    ),
                    AppShimmerBox(width: 44.w, height: 24.h, borderRadius: 12.r),
                  ],
                ),
                SizedBox(height: 12.h),
                AppShimmerBox(width: double.infinity, height: 12.h),
                SizedBox(height: 8.h),
                AppShimmerBox(width: 220.w, height: 12.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _menuRow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          AppShimmerBox(width: 24.w, height: 24.w, borderRadius: 6.r),
          SizedBox(width: 12.w),
          Expanded(
            child: AppShimmerBox(
              width: double.infinity,
              height: 14.h,
              borderRadius: 4.r,
            ),
          ),
          AppShimmerBox(width: 16.w, height: 16.w, borderRadius: 4.r),
        ],
      ),
    );
  }
}
