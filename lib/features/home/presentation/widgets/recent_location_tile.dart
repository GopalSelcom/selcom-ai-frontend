import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';
import 'package:selcom_rides_frontend/core/widgets/svg_picture_asset.dart';

import '../../../../core/constants/app_assets.dart';

class RecentLocationTile extends StatelessWidget {
  const RecentLocationTile({
    super.key,
    required this.title,
    required this.address,
    required this.distance,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    this.bottomSpacing = 24,
    this.topSpacing = 24,
  });

  final String title;
  final String address;
  final String distance;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final double bottomSpacing;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topSpacing.h, bottom: bottomSpacing.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            Container(
              constraints: BoxConstraints(minWidth: 52.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPictureAsset(
                    AppAssets.locationIcTime,
                    width: 21.sp,
                    height: 21.sp,
                    color: AppColors.textBody,
                  ),
                  SizedBox(height: 2.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      distance.isEmpty ? 'SAVED' : distance,
                      style: AppTextStyles.homeCaption.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textBody
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    address,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.textBody,
                      fontSize: 14.sp,
                      fontWeight:FontWeight.w500
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavoriteTap,
              icon: SvgPictureAsset(
                isFavorite ? AppAssets.locationIcHeartFilled : AppAssets.locationIcHeartOutline,
                width: 21.sp,
                height: 19.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
