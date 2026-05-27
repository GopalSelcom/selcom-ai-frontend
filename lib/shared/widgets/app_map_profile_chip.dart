import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import 'app_profile_user_avatar.dart';
import 'app_shimmer.dart';

/// Map header profile control — same avatar/placeholder as [AppProfileUserAvatar].
class AppMapProfileChip extends StatelessWidget {
  const AppMapProfileChip({
    super.key,
    this.onTap,
    this.imageUrl,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final String? imageUrl;
  final bool isLoading;

  static const double _chipSize = 64;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AppShimmer(
        child: AppShimmerBox(
          width: 64.w,
          height: 61.h,
          borderRadius: 16.r,
        ),
      );
    }

    final avatar = AppProfileUserAvatar(
      size: _chipSize.w,
      imageUrl: imageUrl,
    );

    if (onTap == null) {
      return avatar;
    }

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: avatar,
      ),
    );
  }
}
