import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Map top bar: pickup and destination on one line (vehicle selection style).
///
/// Pass [onClose] / [onEdit] to show action icons; omit for read-only screens.
class AppMapRouteOneLineBar extends StatelessWidget {
  const AppMapRouteOneLineBar({
    super.key,
    required this.pickupLabel,
    required this.destinationLabel,
    this.onClose,
    this.onEdit,
    this.height,
  });

  final String pickupLabel;
  final String destinationLabel;
  final VoidCallback? onClose;
  final VoidCallback? onEdit;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final barHeight = height ?? 44.h;
    final hasActionIcons = onClose != null || onEdit != null;
    final horizontalPadding = hasActionIcons ? 4.w : 12.w;

    return Container(
      height: barHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                color: AppColors.textHeading,
                size: 20.sp,
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pickupLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.textHeading,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Icon(
                    Icons.arrow_right_alt,
                    color: AppColors.textHeading,
                    size: 18.sp,
                  ),
                ),
                Expanded(
                  child: Text(
                    destinationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.primary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_outlined,
                color: AppColors.textHeading,
                size: 20.sp,
              ),
            ),
        ],
      ),
    );
  }
}
