import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'my_rides_screen_layout.dart';

/// Content-section shimmer for [MyRidesScreen] (matches [RideHistoryCard] layout).
abstract final class MyRidesScreenShimmer {
  MyRidesScreenShimmer._();

  static Widget loadMoreItems() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(
          MyRidesScreenLayout.lazyLoadShimmerCardCount,
          (_) => rideHistoryItem(),
        ),
      ),
    );
  }

  static Widget listContent() {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MyRidesScreenLayout.sectionTitleHorizontalInset,
            ),
            child: AppShimmer(
              child: AppShimmerBox(
                width: 48.w,
                height: MyRidesScreenLayout.sectionTitleHeight,
                borderRadius: 4.r,
              ),
            ),
          ),
          SizedBox(height: MyRidesScreenLayout.sectionTitleBottomGap),
          ...List.generate(
            MyRidesScreenLayout.shimmerRideCardCount,
            (_) => rideHistoryItem(),
          ),
        ],
      ),
    );
  }

  /// One ride row: header, route, payment sections (same structure as loaded card).
  static Widget rideHistoryItem() {
    return Container(
      margin: EdgeInsets.only(bottom: MyRidesScreenLayout.rideCardBottomMargin),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppShimmer(child: _headerSection()),
          Divider(
            color: AppColors.black.withValues(alpha: 0.1),
            height: 1,
            thickness: 0.5,
          ),
          AppShimmer(child: _locationsSection()),
          Divider(
            color: AppColors.black.withValues(alpha: 0.1),
            height: 1,
            thickness: 0.5,
          ),
          AppShimmer(child: _footerSection()),
        ],
      ),
    );
  }

  static Widget _headerSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 17.h, 12.w, 13.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppShimmerBox(height: 20.h, borderRadius: 4.r),
          ),
          SizedBox(width: 8.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppShimmerBox(width: 6.w, height: 6.w, borderRadius: 3.r),
              SizedBox(width: 3.w),
              AppShimmerBox(width: 68.w, height: 20.h, borderRadius: 4.r),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _locationsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      child: Column(
        children: [
          _locationRow(showConnectorBelow: true),
          _locationRow(showConnectorBelow: false),
        ],
      ),
    );
  }

  static Widget _locationRow({required bool showConnectorBelow}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AppShimmerBox(width: 24.w, height: 24.w, borderRadius: 12.r),
              if (showConnectorBelow)
                Expanded(
                  child: Container(
                    width: 1.w,
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    color: AppColors.white,
                  ),
                ),
            ],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnectorBelow ? 16.h : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox(width: 140.w, height: 20.h, borderRadius: 4.r),
                  SizedBox(height: 1.h),
                  AppShimmerBox(height: 20.h, borderRadius: 4.r),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _footerSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 13.h, 12.w, 17.h),
      child: Row(
        children: [
          AppShimmerBox(width: 132.w, height: 20.h, borderRadius: 4.r),
          const Spacer(),
          AppShimmerBox(width: 72.w, height: 20.h, borderRadius: 4.r),
        ],
      ),
    );
  }
}
