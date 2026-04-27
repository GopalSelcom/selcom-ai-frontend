import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';

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
  });

  final String title;
  final String address;
  final String distance;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          children: [
            Container(
              constraints: BoxConstraints(minWidth: 52.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.bgSoftCircle,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 20.sp,
                    color: AppColors.textBody,
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      distance.isEmpty ? 'SAVED' : distance,
                      style: AppTextStyles.homeCaption.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    address,
                    style: AppTextStyles.homeCaption.copyWith(
                      color: AppColors.textBody,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavoriteTap,
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.primary : AppColors.skeletonBase,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
