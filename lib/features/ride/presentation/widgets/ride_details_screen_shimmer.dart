import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/data/models/responses/rides/ride_details_response.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import 'ride_details_screen_layout.dart';

/// Content-section shimmer for [RideDetailsScreen].
/// Card shells match loaded UI; inner boxes use [RideDetailsScreenLayout] heights.
abstract final class RideDetailsScreenShimmer {
  RideDetailsScreenShimmer._();

  static Widget content({
    bool showReviewAtTop = false,
    bool showReviewAtBottom = false,
    bool showBookedForOther = false,
    bool showPassengerPhone = false,
    bool showPromoLine = false,
    bool showDownloadSlip = false,
    int locationRowCount = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppShimmer(child: _headerSection()),
        if (showReviewAtTop) ...[
          SizedBox(height: RideDetailsScreenLayout.sectionGap),
          _reviewCard(),
        ],
        SizedBox(height: RideDetailsScreenLayout.sectionGap),
        _locationsCard(locationRowCount: locationRowCount),
        if (showBookedForOther) ...[
          SizedBox(height: RideDetailsScreenLayout.sectionGap),
          _bookedForOtherCard(showPassengerPhone: showPassengerPhone),
        ],
        SizedBox(height: RideDetailsScreenLayout.sectionGap),
        _fareCard(showPromoLine: showPromoLine),
        if (showReviewAtBottom) ...[
          SizedBox(height: RideDetailsScreenLayout.sectionGap),
          _reviewCard(),
        ],
        SizedBox(height: RideDetailsScreenLayout.needHelpTopGap),
        AppShimmer(child: _needHelpSection(showDownloadSlip: showDownloadSlip)),
        SizedBox(height: RideDetailsScreenLayout.scrollBottomGap),
      ],
    );
  }

  static Widget primaryButton() {
    final height = RideDetailsScreenLayout.primaryButtonHeight;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: AppShimmer(
        child: AppShimmerBox(
          width: double.infinity,
          height: height,
          borderRadius: AppRadius.button,
        ),
      ),
    );
  }

  static int locationRowCountFor(RideDetailsRide ride) {
    final endAddr = (ride.destination?.address ?? '').trim().toLowerCase();
    final stopCount = (ride.stops ?? []).where((stop) {
      return (stop.address ?? '').trim().toLowerCase() != endAddr;
    }).length;
    return 2 + stopCount;
  }

  static Widget _sectionCardShell({
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.78),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: child,
    );
  }

  static Widget _reviewCard() {
    final contentHeight =
        RideDetailsScreenLayout.reviewTitleLineHeight +
        RideDetailsScreenLayout.reviewTitleStarsGap +
        RideDetailsScreenLayout.reviewStarSize;
    return _sectionCardShell(
      padding: EdgeInsets.all(RideDetailsScreenLayout.reviewCardPadding),
      child: SizedBox(
        height: contentHeight,
        child: AppShimmer(child: _reviewContent()),
      ),
    );
  }

  static Widget _locationsCard({required int locationRowCount}) {
    final rows = locationRowCount < 2 ? 2 : locationRowCount;
    var contentHeight = 0.0;
    for (var i = 0; i < rows; i++) {
      contentHeight += RideDetailsScreenLayout.locationRowHeight(
        hasConnectorBelow: i < rows - 1,
      );
    }
    return _sectionCardShell(
      padding: EdgeInsets.all(RideDetailsScreenLayout.locationCardPadding),
      child: SizedBox(
        height: contentHeight,
        child: AppShimmer(child: _locationsSection(locationRowCount: rows)),
      ),
    );
  }

  static Widget _bookedForOtherCard({required bool showPassengerPhone}) {
    return _sectionCardShell(
      padding: EdgeInsets.all(RideDetailsScreenLayout.locationCardPadding),
      child: SizedBox(
        height: RideDetailsScreenLayout.bookedForRowHeightWithPhone(
          showPhone: showPassengerPhone,
        ),
        child: AppShimmer(
          child: _bookedForOtherContent(showPassengerPhone: showPassengerPhone),
        ),
      ),
    );
  }

  static Widget _fareCard({required bool showPromoLine}) {
    return _sectionCardShell(
      padding: EdgeInsets.fromLTRB(
        RideDetailsScreenLayout.fareCardPaddingLeft,
        RideDetailsScreenLayout.fareCardPaddingTop,
        RideDetailsScreenLayout.fareCardPaddingRight,
        RideDetailsScreenLayout.fareCardPaddingBottom,
      ),
      child: SizedBox(
        height: RideDetailsScreenLayout.fareCardContentHeight(
          showPromoLine: showPromoLine,
        ),
        child: AppShimmer(child: _fareContent(showPromoLine: showPromoLine)),
      ),
    );
  }

  static Widget _headerSection() {
    final textColumnHeight =
        RideDetailsScreenLayout.headerTitleLineHeight +
        RideDetailsScreenLayout.headerTitleDateGap +
        RideDetailsScreenLayout.headerDateLineHeight;
    return SizedBox(
      height:
          textColumnHeight > RideDetailsScreenLayout.headerVehicleImageHeight
          ? textColumnHeight
          : RideDetailsScreenLayout.headerVehicleImageHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppShimmerBox(
                  width: 132.w,
                  height: RideDetailsScreenLayout.headerTitleLineHeight,
                  borderRadius: 4.r,
                ),
                SizedBox(height: RideDetailsScreenLayout.headerTitleDateGap),
                AppShimmerBox(
                  width: 168.w,
                  height: RideDetailsScreenLayout.headerDateLineHeight,
                  borderRadius: 4.r,
                ),
              ],
            ),
          ),
          AppShimmerBox(
            width: RideDetailsScreenLayout.headerVehicleImageWidth,
            height: RideDetailsScreenLayout.headerVehicleImageHeight,
            borderRadius: 8.r,
          ),
        ],
      ),
    );
  }

  static Widget _reviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppShimmerBox(
          width: 160.w,
          height: RideDetailsScreenLayout.reviewTitleLineHeight,
          borderRadius: 4.r,
        ),
        SizedBox(height: RideDetailsScreenLayout.reviewTitleStarsGap),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            5,
            (_) => AppShimmerBox(
              width: RideDetailsScreenLayout.reviewStarSize,
              height: RideDetailsScreenLayout.reviewStarSize,
              borderRadius: 4.r,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _locationsSection({required int locationRowCount}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(locationRowCount, (index) {
        return _locationRow(showConnectorBelow: index < locationRowCount - 1);
      }),
    );
  }

  static Widget _locationRow({required bool showConnectorBelow}) {
    final rowHeight = RideDetailsScreenLayout.locationRowHeight(
      hasConnectorBelow: showConnectorBelow,
    );
    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: RideDetailsScreenLayout.locationMarkerSize,
            height: rowHeight,
            child: Column(
              children: [
                AppShimmerBox(
                  width: RideDetailsScreenLayout.locationMarkerSize,
                  height: RideDetailsScreenLayout.locationMarkerSize,
                  borderRadius: RideDetailsScreenLayout.locationMarkerSize / 2,
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
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmerBox(
                  width: 140.w,
                  height: RideDetailsScreenLayout.locationTitleLineHeight,
                  borderRadius: 4.r,
                ),
                SizedBox(
                  height: RideDetailsScreenLayout.locationTitleAddressGap,
                ),
                AppShimmerBox(
                  width: double.infinity,
                  height: RideDetailsScreenLayout.locationAddressLineHeight,
                  borderRadius: 4.r,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bookedForOtherContent({required bool showPassengerPhone}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppShimmerBox(
          width: RideDetailsScreenLayout.bookedForIconSize,
          height: RideDetailsScreenLayout.bookedForIconSize,
          borderRadius: RideDetailsScreenLayout.bookedForIconSize / 2,
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppShimmerBox(
                width: 200.w,
                height: RideDetailsScreenLayout.bookedForNameLineHeight,
                borderRadius: 4.r,
              ),
              if (showPassengerPhone) ...[
                SizedBox(height: RideDetailsScreenLayout.bookedForLineGap),
                AppShimmerBox(
                  width: 140.w,
                  height: RideDetailsScreenLayout.bookedForPhoneLineHeight,
                  borderRadius: 4.r,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget _fareContent({required bool showPromoLine}) {
    final rowCount =
        RideDetailsScreenLayout.defaultFareRowCount + (showPromoLine ? 1 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppShimmerBox(
          width: 72.w,
          height: RideDetailsScreenLayout.fareTitleLineHeight,
          borderRadius: 4.r,
        ),
        SizedBox(height: RideDetailsScreenLayout.fareTitleRowsGap),
        for (var i = 0; i < rowCount; i++) ...[
          if (i > 0) SizedBox(height: RideDetailsScreenLayout.fareRowGap),
          _fareRow(),
        ],
      ],
    );
  }

  static Widget _fareRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppShimmerBox(
            height: RideDetailsScreenLayout.fareRowLineHeight,
            borderRadius: 4.r,
          ),
        ),
        SizedBox(width: 8.w),
        AppShimmerBox(
          width: 56.w,
          height: RideDetailsScreenLayout.fareRowLineHeight,
          borderRadius: 4.r,
        ),
      ],
    );
  }

  static Widget _needHelpSection({required bool showDownloadSlip}) {
    return SizedBox(
      height: RideDetailsScreenLayout.needHelpLineHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppShimmerBox(
            width: RideDetailsScreenLayout.needHelpIconSize,
            height: RideDetailsScreenLayout.needHelpIconSize,
            borderRadius: 4.r,
          ),
          SizedBox(width: 8.w),
          AppShimmerBox(
            width: 72.w,
            height: RideDetailsScreenLayout.needHelpLineHeight,
            borderRadius: 4.r,
          ),
          if (showDownloadSlip) ...[
            SizedBox(width: 20.w),
            AppShimmerBox(
              width: 108.w,
              height: RideDetailsScreenLayout.needHelpLineHeight,
              borderRadius: 4.r,
            ),
          ],
        ],
      ),
    );
  }
}
