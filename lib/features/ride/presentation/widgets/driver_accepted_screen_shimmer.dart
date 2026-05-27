import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Content-section shimmer for [DriverAcceptedScreen] bottom sheets.
/// Sizes mirror loaded text [fontSize] values — not line-height boxes.
abstract final class DriverAcceptedScreenShimmer {
  DriverAcceptedScreenShimmer._();

  static Widget driverAssignedSheet({
    bool showPin = true,
    int pinDigitCount = 4,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppShimmer(child: _driverAssignedEtaSection()),
        SizedBox(height: 17.h),
        if (showPin) _pinSection(digitCount: pinDigitCount),
        _plateCard(),
        SizedBox(height: 17.h),
        const Divider(color: AppColors.borderWalletCard, height: 1),
        SizedBox(height: 17.h),
        AppShimmer(child: _driverDetailsRow()),
        SizedBox(height: 16.h),
        _cancelButton(),
      ],
    );
  }

  static Widget rideStartedSheetBody({bool showChangeDropLink = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppShimmer(child: _rideProgressHeader()),
        SizedBox(height: 7.94.h),
        _locationsCard(showChangeDropLink: showChangeDropLink),
        SizedBox(height: 8.h),
        _fareCard(),
        SizedBox(height: 12.h),
      ],
    );
  }

  static Widget rideStartedSheetTitle() {
    return AppShimmer(
      child: Center(
        child: AppShimmerBox(
          width: 180.w,
          height: 20.sp,
          borderRadius: 4.r,
        ),
      ),
    );
  }

  static Widget rideStartedSheet({bool showChangeDropLink = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rideStartedSheetTitle(),
        SizedBox(height: 14.h),
        const Divider(color: AppColors.borderWalletCard, height: 1),
        SizedBox(height: 16.h),
        rideStartedSheetBody(showChangeDropLink: showChangeDropLink),
      ],
    );
  }

  static Widget _driverAssignedEtaSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppShimmerBox(
              width: 29.w,
              height: 29.w,
              borderRadius: 14.5.r,
            ),
            SizedBox(width: 2.w),
            AppShimmerBox(
              width: 160.w,
              height: 15.sp,
              borderRadius: 4.r,
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Center(
          child: AppShimmerBox(
            width: 200.w,
            height: 20.sp,
            borderRadius: 4.r,
          ),
        ),
      ],
    );
  }

  static Widget _pinSection({int digitCount = 4}) {
    final digits = digitCount < 1 ? 4 : digitCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppShimmer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppShimmerBox(
                width: 28.w,
                height: 15.sp,
                borderRadius: 4.r,
              ),
              SizedBox(width: 8.w),
              for (var i = 0; i < digits; i++)
                Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: AppShimmerBox(
                    width: 28.w,
                    height: 28.w,
                    borderRadius: 16.r,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 22.h),
      ],
    );
  }

  static Widget _plateCard() {
    return Center(
      child: IntrinsicWidth(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.ratingGoldDark,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.borderWalletCard,
              width: 0.787,
            ),
          ),
          child: AppShimmer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppShimmerBox(
                      width: 22.w,
                      height: 14.h,
                      borderRadius: 2.r,
                    ),
                    SizedBox(width: 6.w),
                    AppShimmerBox(
                      width: 120.w,
                      height: 26.sp,
                      borderRadius: 4.r,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Center(
                  child: AppShimmerBox(
                    width: 140.w,
                    height: 15.sp,
                    borderRadius: 4.r,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _driverDetailsRow() {
    const avatarSize = 51.66;
    const actionSize = 33.81;
    const starSize = 11.12;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppShimmerBox(
          width: avatarSize.w,
          height: avatarSize.w,
          borderRadius: avatarSize.w / 2,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  AppShimmerBox(
                    width: 108.w,
                    height: 20.sp,
                    borderRadius: 4.r,
                  ),
                  SizedBox(width: 9.w),
                  AppShimmerBox(
                    width: starSize.w,
                    height: starSize.w,
                    borderRadius: 2.r,
                  ),
                  SizedBox(width: 3.w),
                  AppShimmerBox(
                    width: 20.w,
                    height: 15.sp,
                    borderRadius: 4.r,
                  ),
                ],
              ),
              AppShimmerBox(
                width: 130.w,
                height: 15.sp,
                borderRadius: 4.r,
              ),
            ],
          ),
        ),
        AppShimmerBox(
          width: actionSize.w,
          height: actionSize.w,
          borderRadius: actionSize.w / 2,
        ),
        SizedBox(width: 9.w),
        AppShimmerBox(
          width: actionSize.w,
          height: actionSize.w,
          borderRadius: actionSize.w / 2,
        ),
      ],
    );
  }

  static Widget _cancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: AppShimmer(
        child: AppShimmerBox(
          width: double.infinity,
          height: 56.h,
          borderRadius: 16.r,
        ),
      ),
    );
  }

  static Widget _rideProgressHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmerBox(
                width: 100.w,
                height: 20.sp,
                borderRadius: 4.r,
              ),
              Row(
                children: [
                  AppShimmerBox(
                    width: 72.w,
                    height: 15.sp,
                    borderRadius: 4.r,
                  ),
                  SizedBox(width: 5.w),
                  AppShimmerBox(
                    width: 48.w,
                    height: 21.sp,
                    borderRadius: 6.r,
                  ),
                ],
              ),
            ],
          ),
        ),
        AppShimmerBox(
          width: 76.w,
          height: 60.67.h,
          borderRadius: 8.r,
        ),
      ],
    );
  }

  static Widget _locationsCard({required bool showChangeDropLink}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: AppShimmer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _locationRow(showConnectorBelow: true),
            _locationRow(
              showConnectorBelow: false,
              showChangeDropFooter: showChangeDropLink,
            ),
          ],
        ),
      ),
    );
  }

  static Widget _locationRow({
    required bool showConnectorBelow,
    bool showChangeDropFooter = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AppShimmerBox(
                width: 24.w,
                height: 24.w,
                borderRadius: 12.r,
              ),
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
                  AppShimmerBox(
                    width: 120.w,
                    height: 15.sp,
                    borderRadius: 4.r,
                  ),
                  SizedBox(height: 1.h),
                  AppShimmerBox(
                    width: double.infinity,
                    height: 12.sp,
                    borderRadius: 4.r,
                  ),
                  if (showChangeDropFooter)
                    AppShimmerBox(
                      width: 140.w,
                      height: 12.sp,
                      borderRadius: 4.r,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _fareCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 11.w, 24.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox(
              width: 72.w,
              height: 15.sp,
              borderRadius: 4.r,
            ),
            SizedBox(height: 6.h),
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) SizedBox(height: 4.h),
              _fareRow(),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _fareRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppShimmerBox(
            height: 12.sp,
            borderRadius: 4.r,
          ),
        ),
        SizedBox(width: 8.w),
        AppShimmerBox(
          width: 56.w,
          height: 12.sp,
          borderRadius: 4.r,
        ),
      ],
    );
  }
}
