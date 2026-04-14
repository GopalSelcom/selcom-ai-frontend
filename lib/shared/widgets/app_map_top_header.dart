import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_map_profile_chip.dart';

/// Reusable top map header with address area + profile chip.
class AppMapTopHeader extends StatelessWidget {
  const AppMapTopHeader({
    super.key,
    required this.top,
    required this.addressWidget,
    this.left = 20,
    this.right = 20,
    this.spacing = 12,
    this.onProfileTap,
    this.profileIcon = Icons.person,
    this.profileIconColor = Colors.black,
  });

  final double top;
  final Widget addressWidget;
  final double left;
  final double right;
  final double spacing;
  final VoidCallback? onProfileTap;
  final IconData profileIcon;
  final Color profileIconColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left.w,
      right: right.w,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            addressWidget,
            SizedBox(width: spacing.w),
            AppMapProfileChip(
              onTap: onProfileTap,
              icon: profileIcon,
              iconColor: profileIconColor,
            ),
          ],
        ),
      ),
    );
  }
}
