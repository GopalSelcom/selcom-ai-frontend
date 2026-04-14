import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Rounded profile control used on map screens (Figma ride map chrome).
class AppMapProfileChip extends StatelessWidget {
  const AppMapProfileChip({
    super.key,
    this.onTap,
    this.icon = Icons.person_outline,
    this.iconColor = Colors.black87,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;

  static const Color _borderColor = Color(0xFFD3DDE7);

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 64.w,
      constraints: BoxConstraints(minHeight: 61.h),
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
