import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'home_sheet_layout.dart';

/// Shimmer placeholders for [LocationSelectionScreen] (chips + location lists).
abstract final class LocationSelectionShimmer {
  LocationSelectionShimmer._();

  static const int _savedPlaceSkeletonCount = 2;
  static const int _recentSkeletonCount = 3;

  /// Favorite chips row while home saved places load.
  static Widget chipsRow() {
    return SizedBox(
      height: HomeSheetLayout.chipsRowHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        clipBehavior: Clip.none,
        child: AppShimmer(
          child: Row(
            children: List.generate(
              4,
              (index) => Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: AppShimmerBox(
                  width: 88.w,
                  height: 38.h,
                  borderRadius: 12.r,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Saved + recent sections on first open while lists load.
  ///
  /// Top-aligned only — avoids a full-height [ListView] leaving empty white
  /// scrollable space below the placeholders (same layout as loaded lists).
  static Widget savedAndRecentList() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitleSkeleton(width: 100.w),
            SizedBox(height: 12.h),
            ...List.generate(
              _savedPlaceSkeletonCount,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < _savedPlaceSkeletonCount - 1 ? 8.h : 0,
                ),
                child: locationTile(),
              ),
            ),
            SizedBox(height: 24.h),
            _sectionTitleSkeleton(width: 130.w),
            SizedBox(height: 12.h),
            ...List.generate(
              _recentSkeletonCount,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index < _recentSkeletonCount - 1 ? 8.h : 0,
                ),
                child: locationTile(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionTitleSkeleton({required double width}) {
    return AppShimmer(
      child: AppShimmerBox(
        width: width,
        height: HomeSheetLayout.sectionTitleHeight,
        borderRadius: 8.r,
      ),
    );
  }

  /// One row — layout aligned with [LocationSelectionScreen._locationTile].
  static Widget locationTile() {
    return AppShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.fromLTRB(14.w, 15.h, 13.w, 14.56.h),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmerBox(
                  width: 21.w,
                  height: 21.h,
                  borderRadius: 10.r,
                ),
                SizedBox(height: 4.h),
                AppShimmerBox(
                  width: 32.w,
                  height: 12.h,
                  borderRadius: 6.r,
                ),
              ],
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox(
                    width: 140.w,
                    height: 16.h,
                    borderRadius: 8.r,
                  ),
                  SizedBox(height: 4.h),
                  AppShimmerBox(
                    height: 14.h,
                    borderRadius: 8.r,
                  ),
                ],
              ),
            ),
            AppShimmerBox(
              width: 24.w,
              height: 24.h,
              borderRadius: 12.r,
            ),
          ],
        ),
      ),
    );
  }
}
