import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';

class AppSavedPlaceChip extends StatelessWidget {
  const AppSavedPlaceChip({
    super.key,
    required this.label,
    required this.iconAsset,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
  });

  final String label;
  final String iconAsset;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.52.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: borderColor ?? AppColors.borderWalletCard,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPictureAsset(
              iconAsset,
              width: 15.w,
              height: 15.w,
              color: iconColor,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppTextStyles.homeChip.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
