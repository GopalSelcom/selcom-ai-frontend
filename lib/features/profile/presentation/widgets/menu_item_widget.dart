import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/theme/app_colors.dart';
import 'package:selcom_rides_frontend/core/theme/app_text_styles.dart';

class MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.w, bottom: 11.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 24.w, color: AppColors.textHeading),
                SizedBox(width: 9.w),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textHeading,
                      fontSize: 15.sp,
                      height: 20 / 15,
                    ),
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 18.w,
                  color: AppColors.textHeading.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          if (showDivider) ...[
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            SizedBox(height: 17.h),
          ],
        ],
      ),
    );
  }
}
