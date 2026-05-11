import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/svg_picture_asset.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/domain/entities/ride_entity.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RideDateFormatter {
  static String formatDate(String apiDate) {
    try {
      final parts = apiDate.split(', ');
      if (parts.length < 2) return apiDate;

      final dateParts = parts[0].split('-');
      if (dateParts.length < 3) return apiDate;

      final year = dateParts[0];
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final time = parts[1].replaceAll(' ', ''); // 08:08PM

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      String daySuffix = 'th';
      if (day >= 11 && day <= 13) {
        daySuffix = 'th';
      } else {
        switch (day % 10) {
          case 1:
            daySuffix = 'st';
            break;
          case 2:
            daySuffix = 'nd';
            break;
          case 3:
            daySuffix = 'rd';
            break;
          default:
            daySuffix = 'th';
        }
      }

      final dayStr = day.toString().padLeft(2, '0');
      return '$dayStr$daySuffix ${months[month - 1]} $year . $time';
    } catch (e) {
      return apiDate;
    }
  }
}

class RideLocationsTimeline extends StatelessWidget {
  final String startLocation;
  final String startAddress;
  final String endLocation;
  final String endAddress;
  final List<RideStopEntity>? stops;
  final bool showStopsAsSummary;
  final bool showAddStopBeforeDestination;
  final VoidCallback? onAddStopTap;

  /// When true, shows a red text action under the destination (ride-started sheet only).
  final bool showChangeDropLocationLink;
  final VoidCallback? onChangeDropLocationTap;

  const RideLocationsTimeline({
    super.key,
    required this.startLocation,
    required this.startAddress,
    required this.endLocation,
    required this.endAddress,
    this.stops,
    this.showStopsAsSummary = false,
    this.showAddStopBeforeDestination = false,
    this.onAddStopTap,
    this.showChangeDropLocationLink = false,
    this.onChangeDropLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    // Filter stops to avoid duplicating final destination
    final filteredStops = (stops ?? []).where((s) {
      final stopAddr = s.address.trim().toLowerCase();
      final endAddr = endAddress.trim().toLowerCase();
      return stopAddr != endAddr;
    }).toList();

    final bool isMulti = filteredStops.isNotEmpty;
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

    return Column(
      children: [
        // Start Location Row
        _buildLocationRow(
          title: startLocation,
          address: startAddress,
          icon: _buildLetterIcon(
            isMulti ? 'A' : 'P',
            color: AppColors.mapPickupMarkerBlue,
          ),
          bottomSpacingWhenLine:
              showAddStopBeforeDestination && filteredStops.isEmpty ? 0 : null,
          showBottomLine: true,
        ),

        // Intermediate Stops (full rows) or compact summary marker
        if (showStopsAsSummary && filteredStops.isNotEmpty)
          _buildLocationRow(
            title:
                '${filteredStops.length} ${AppStrings.stop.tr}${filteredStops.length > 1 ? 's' : ''}',
            address: null,
            icon: _buildStopCountIcon(filteredStops.length),
            bottomSpacingWhenLine: showAddStopBeforeDestination ? 0 : null,
            showBottomLine: true,
          )
        else
          for (int i = 0; i < filteredStops.length; i++)
            _buildLocationRow(
              title: filteredStops[i].address.split(',').first,
              address: filteredStops[i].address,
              icon: _buildLetterIcon(
                letters[i + 1],
                color: AppColors.mapStopMarkerRed,
              ),
              bottomSpacingWhenLine:
                  showAddStopBeforeDestination && i == filteredStops.length - 1
                  ? 0
                  : null,
              showBottomLine: true,
            ),

        if (showAddStopBeforeDestination) _buildAddStopDividerRow(),

        // End Location Row
        _buildLocationRow(
          title: endLocation,
          address: endAddress,
          icon: _buildLetterIcon(
            isMulti ? letters[filteredStops.length + 1] : 'D',
            color: AppColors.mapDropMarkerGreen,
          ),
          showBottomLine: false,
          footer: showChangeDropLocationLink && onChangeDropLocationTap != null
              ? GestureDetector(
                  onTap: onChangeDropLocationTap,
                  child: Text(
                    AppStrings.changeDropLocation.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontSize: 12.sp,
                      height: 20 / 12,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildLetterIcon(String label, {required Color color}) {
    return Container(
      width: 24.w,
      height: 24.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildStopCountIcon(int count) {
    return Container(
      width: 22.w,
      height: 22.w,
      decoration: const BoxDecoration(
        color: AppColors.mapStopMarkerRed,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required String title,
    String? address,
    required Widget icon,
    Widget? trailing,
    double? bottomSpacingWhenLine,
    required bool showBottomLine,
    Widget? footer,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              icon,
              if (showBottomLine)
                Expanded(
                  child: Container(
                    width: 1.w,
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    child: CustomPaint(
                      painter: DashedLinePainter(
                        color: AppColors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: showBottomLine ? (bottomSpacingWhenLine ?? 16.h) : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTextStyles.metropolisFont,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      fontSize: 15.sp,
                      height: 20 / 15,
                    ),
                  ),
                  if (address != null && address.trim().isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      address,
                      style: TextStyle(
                        fontFamily: AppTextStyles.metropolisFont,
                        color: AppColors.textBody,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        height: 20 / 12,
                      ),
                    ),
                  ],
                  if (footer != null) footer,
                ],
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 8.w),
            Padding(
              padding: EdgeInsets.only(
                bottom: showBottomLine ? (bottomSpacingWhenLine ?? 8.h) : 0,
              ),
              child: Align(alignment: Alignment.center, child: trailing),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddStopPill() {
    return GestureDetector(
      onTap: onAddStopTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 6.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: AppColors.borderWalletCard),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPictureAsset(
              AppAssets.locationIcAdd,
              width: 16.w,
              height: 16.w,
              color: AppColors.primary,
              placeholderBuilder: (_) => Container(
                width: 16.w,
                height: 16.w,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.add, color: AppColors.white, size: 12.sp),
              ),
            ),
            SizedBox(width: 4.80.w),
            Text(
              AppStrings.add.tr,
              style: AppTextStyles.homeSubtitle.copyWith(
                color: AppColors.textMutedStrong,
                fontSize: 14.sp,
                height: 20 / 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddStopDividerRow() {
    return SizedBox(
      height: 34.h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22.w,
            child: Center(
              child: SizedBox(
                width: 1.w,
                height: double.infinity,
                child: CustomPaint(
                  painter: DashedLinePainter(
                    color: AppColors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 1.h,
                    color: AppColors.borderWalletCard,
                  ),
                ),
                _buildAddStopPill(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.w
      ..style = PaintingStyle.stroke;

    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    double currentY = 0;

    while (currentY < size.height) {
      canvas.drawLine(
        Offset(0, currentY),
        Offset(0, currentY + dashWidth),
        paint,
      );
      currentY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class FareBreakdownRow extends StatelessWidget {
  final String title;
  final String amount;
  final bool isTotal;

  const FareBreakdownRow({
    super.key,
    required this.title,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.homeCaption.copyWith(
              fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
              height: 20 / 12,
            ),
          ),
        ),
        Text(
          amount,
          style: AppTextStyles.homeCaption.copyWith(
            fontWeight: isTotal ? FontWeight.w500 : FontWeight.w400,
            height: 20 / 12,
          ),
        ),
      ],
    );
  }
}

class NeedHelpRow extends StatelessWidget {
  const NeedHelpRow({
    super.key,
    this.showDownloadSlip = false,
    this.onDownloadTap,
  });

  final bool showDownloadSlip;
  final VoidCallback? onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPictureAsset(
          AppAssets.icHeadPhone,
          width: 18.w,
          height: 18.w,
          color: AppColors.textBody,
          placeholderBuilder: (_) => Icon(
            Icons.headset_mic_outlined,
            color: AppColors.textBody,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.contactUs),
          child: Text(
            AppStrings.needHelp.tr,
            style: AppTextStyles.homeSubtitle.copyWith(height: 20 / 15),
          ),
        ),
        if (showDownloadSlip) ...[
          SizedBox(width: 20.w),
          GestureDetector(
            onTap: onDownloadTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPictureAsset(
                  AppAssets.icDownload,
                  width: 19.w,
                  height: 19.w,
                  color: AppColors.textBody,
                  placeholderBuilder: (_) => Icon(
                    Icons.download_rounded,
                    color: AppColors.textBody,
                    size: 19.sp,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  AppStrings.downloadSlip.tr,
                  style: AppTextStyles.homeSubtitle.copyWith(height: 20 / 15),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class RideRatingStars extends StatelessWidget {
  final double? rating;
  final double starSize;

  const RideRatingStars({super.key, this.rating, this.starSize = 32});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final isFilled = rating != null && index < rating!.floor();
        final starColor = isFilled
            ? AppColors.ratingStarActive
            : AppColors.ratingStarInactive;
        return SvgPictureAsset(
          AppAssets.icRatingStar,
          width: starSize.w,
          height: starSize.w,
          color: starColor,
          placeholderBuilder: (_) =>
              Icon(Icons.star, color: starColor, size: starSize.w),
        );
      }),
    );
  }
}
