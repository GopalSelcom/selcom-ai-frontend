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
    this.spacing = 9,
    this.onProfileTap,
    this.profileImageUrl,
    this.isLoading = false,
    this.isExpanded = false,
    this.isProfileIconVisible = true,
  });

  final double top;
  final Widget addressWidget;
  final double left;
  final double right;
  final double spacing;
  final VoidCallback? onProfileTap;
  final String? profileImageUrl;
  final bool isLoading;
  final bool isExpanded;
  final bool isProfileIconVisible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left.w,
      right: right.w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          addressWidget,
          SizedBox(width: spacing.w),
          Visibility(
            visible: isProfileIconVisible,
            child: AppMapProfileChip(
              onTap: onProfileTap,
              imageUrl: profileImageUrl,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}
