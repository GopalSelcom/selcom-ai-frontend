import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Rounded profile control used on map screens (Figma ride map chrome).
class AppMapProfileChip extends StatelessWidget {
  const AppMapProfileChip({
    super.key,
    this.onTap,
    this.icon = Icons.person_outline,
    this.iconColor = AppColors.textMapIcon,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: AppColors.skeletonBase,
        highlightColor: AppColors.skeletonHighlight,
        child: Container(
          width: 64.w,
          constraints: BoxConstraints(minHeight: 61.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      );
    }

    final child = Container(
      width: 64.w,
      height: 61.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMapCard,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: 28.sp, color: iconColor),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: child,
      ),
    );
  }
}
