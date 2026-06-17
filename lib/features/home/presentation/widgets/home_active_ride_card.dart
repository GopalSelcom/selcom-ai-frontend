import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/vehicle_type_image.dart';

/// Floating active-ride banner on Home (above the "Where to?" sheet).
class HomeActiveRideCard extends StatelessWidget {
  const HomeActiveRideCard({
    super.key,
    required this.vehicleAssetPath,
    required this.routeTitle,
    required this.remainingLabel,
    required this.additionalRidesCount,
    required this.onViewRide,
    this.onMoreBadgeTap,
  });

  static const double cardHeight = 52;
  static const double badgeHeight = 28;
  static const double badgeOutsideCardFraction = 0.7;
  static const double gapAboveSheet = 8;
  static const double gpsGapAboveCard = 4;

  /// Matches [AppMapGpsButton] internal bottom inset (`24.w`).
  static const double gpsButtonBottomInset = 24;

  /// Vertical space reserved above the card (70% of badge sits outside the card).
  static double get badgeTopOverflow => badgeHeight * badgeOutsideCardFraction;

  /// Portion of the badge that overlaps the top of the active ride card (30%).
  static double get badgeOverlapOnCard =>
      badgeHeight * (1 - badgeOutsideCardFraction);

  /// Total widget height including optional badge overflow above the card.
  static double totalHeightPx({required bool showsMoreBadge}) =>
      (showsMoreBadge ? badgeTopOverflow.h : 0) + cardHeight.h;

  /// Space occupied above the bottom sheet (gap + card footprint).
  static double footprintAboveSheet({required bool showsMoreBadge}) =>
      gapAboveSheet.h + totalHeightPx(showsMoreBadge: showsMoreBadge);

  /// Bottom edge for [AppMapGpsButton] — icon sits just above the white card.
  static double gpsButtonBottom({required double sheetBottomFromScreenBottom}) {
    final cardBottom = sheetBottomFromScreenBottom + gapAboveSheet.h;
    final whiteCardTop = cardBottom + cardHeight.h;
    return whiteCardTop + gpsGapAboveCard.h - gpsButtonBottomInset.w;
  }

  final String vehicleAssetPath;
  final String routeTitle;
  final String remainingLabel;
  final int additionalRidesCount;
  final VoidCallback onViewRide;
  final VoidCallback? onMoreBadgeTap;

  bool get _showsMoreBadge => additionalRidesCount > 0;

  @override
  Widget build(BuildContext context) {
    final badgeOutside = badgeTopOverflow.h;
    final badgeOverlap = badgeOverlapOnCard.h;

    return SizedBox(
      height: (_showsMoreBadge ? badgeOutside : 0) + cardHeight.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeActiveRideCardContent(
              vehicleAssetPath: vehicleAssetPath,
              routeTitle: routeTitle,
              remainingLabel: remainingLabel,
              onViewRide: onViewRide,
            ),
          ),
          if (_showsMoreBadge)
            Positioned(
              left: 0,
              right: 0,
              bottom: cardHeight.h - badgeOverlap,
              child: Center(
                child: _MoreActiveRidesBadge(
                  count: additionalRidesCount,
                  onTap: onMoreBadgeTap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White active-ride row reused in collapsed and expanded states.
class HomeActiveRideCardContent extends StatelessWidget {
  const HomeActiveRideCardContent({
    super.key,
    required this.vehicleAssetPath,
    required this.routeTitle,
    required this.remainingLabel,
    required this.onViewRide,
  });

  final String vehicleAssetPath;
  final String routeTitle;
  final String remainingLabel;
  final VoidCallback onViewRide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 4,
      shadowColor: AppColors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        height: HomeActiveRideCard.cardHeight.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.black.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56.w,
              height: 48.h,
              child: VehicleTypeImage(
                assetPath: vehicleAssetPath,
                width: 56.w,
                height: 48.h,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            SizedBox(width: 8.6.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPaymentDialogMessage,
                    ),
                  ),
                  if (remainingLabel.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      remainingLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            AppPrimaryButton(
              label: AppStrings.viewRide.tr,
              onPressed: onViewRide,
              height: 38.h,
              width: 116.w,
              borderRadius: 8.r,
              labelStyle: AppTextStyles.homeCaption.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                height: 19 / 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreActiveRidesBadge extends StatelessWidget {
  const _MoreActiveRidesBadge({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap?.call(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: HomeActiveRideCard.badgeHeight.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.activeRideMoreCount.trParams({'count': '$count'}),
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.primaryButton,
              ),
            ),
            Icon(
              Icons.arrow_drop_up,
              size: 20.sp,
              color: AppColors.primaryButton,
            ),
          ],
        ),
      ),
    );
  }
}
