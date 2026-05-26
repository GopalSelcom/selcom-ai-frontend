import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'home_sheet_layout.dart';

/// Shimmer placeholders for the home draggable sheet — sizes match [HomeSheetLayout].
class HomeSheetLoadingContent {
  HomeSheetLoadingContent._();

  static List<Widget> buildChildren({required double horizontalPadding}) {
    return [
      _sheetHeaderSection(horizontalPadding),
      SizedBox(height: 8.h),
      _chipsSection(horizontalPadding),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: HomeSheetLayout.sectionGap.h),
            _sectionTitleSkeleton(),
            SizedBox(height: HomeSheetLayout.titleContentGap.h),
            ..._recentLocationSkeletons(),
            SizedBox(height: HomeSheetLayout.sectionGap.h),
            _sectionTitleSkeleton(width: 140.w),
            SizedBox(height: HomeSheetLayout.titleContentGap.h),
            _vehicleRowSkeleton(),
          ],
        ),
      ),
    ];
  }

  static Widget _sheetHeaderSection(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding.w),
      child: AppShimmer(
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Center(
              child: AppShimmerBox(
                width: 48.w,
                height: 5.h,
                borderRadius: 37.r,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.white, width: 0.8),
              ),
              child: Row(
                children: [
                  AppShimmerBox(
                    width: 19.w,
                    height: 19.w,
                    borderRadius: 10.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppShimmerBox(
                      height: 15.h,
                      borderRadius: 8.r,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _chipsSection(double horizontalPadding) {
    return SizedBox(
      height: HomeSheetLayout.chipsRowHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding.w),
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

  static Widget _sectionTitleSkeleton({double? width}) {
    return AppShimmer(
      child: AppShimmerBox(
        width: width ?? 120.w,
        height: HomeSheetLayout.sectionTitleHeight,
        borderRadius: 8.r,
      ),
    );
  }

  static List<Widget> _recentLocationSkeletons() {
    return List.generate(HomeSheetLayout.shimmerRecentRowCount, (index) {
      final isLast = index == HomeSheetLayout.shimmerRecentRowCount - 1;
      return Column(
        children: [
          _recentLocationRowSkeleton(),
          if (!isLast) ...[
            SizedBox(height: HomeSheetLayout.recentItemGap.h),
            Divider(height: 1.h, color: AppColors.bgSoftCircle),
            SizedBox(height: HomeSheetLayout.recentItemGap.h),
          ],
        ],
      );
    });
  }

  static Widget _recentLocationRowSkeleton() {
    return SizedBox(
      height: HomeSheetLayout.recentRowHeight,
      child: AppShimmer(
        child: Row(
          children: [
            AppShimmerBox(
              width: 52.w,
              height: 52.w,
              borderRadius: 12.r,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppShimmerBox(
                    width: 130.w,
                    height: 14.h,
                    borderRadius: 8.r,
                  ),
                  SizedBox(height: 8.h),
                  AppShimmerBox(
                    height: 12.h,
                    borderRadius: 8.r,
                  ),
                ],
              ),
            ),
            AppShimmerBox(
              width: 21.w,
              height: 21.w,
              borderRadius: 6.r,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _vehicleRowSkeleton() {
    return SizedBox(
      height: HomeSheetLayout.vehicleRowHeight.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: AppShimmer(
          child: Row(
            children: List.generate(
              HomeSheetLayout.shimmerVehicleCount,
              (_) => Padding(
                padding: EdgeInsets.only(right: 29.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppShimmerBox(
                      width: 62.w,
                      height: 42.h,
                      borderRadius: 16.r,
                    ),
                    SizedBox(height: 4.h),
                    AppShimmerBox(
                      width: 52.w,
                      height: 10.h,
                      borderRadius: 8.r,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
