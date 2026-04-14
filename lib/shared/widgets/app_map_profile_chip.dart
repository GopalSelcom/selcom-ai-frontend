import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Rounded profile control used on map screens (Figma ride map chrome).
class AppMapProfileChip extends StatelessWidget {
  const AppMapProfileChip({
    super.key,
    this.onTap,
    this.icon = Icons.person_outline,
    this.iconColor = Colors.black87,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;

  static const Color _borderColor = Color(0xFFD3DDE7);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          width: 64.w,
          constraints: BoxConstraints(minHeight: 66.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      );
    }

    final child = Container(
      width: 64.w,
      height: 75.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 2,
            offset: const Offset(0, 1),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: child,
      ),
    );
  }
}
