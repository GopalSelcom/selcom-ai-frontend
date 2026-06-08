import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/svg_picture_asset.dart';
import 'app_profile_user_avatar.dart';

/// Profile row: square avatar, name, phone, rating (GO UI / home map style).
class AppProfileUserSummary extends StatelessWidget {
  const AppProfileUserSummary({
    super.key,
    required this.name,
    required this.phone,
    required this.rating,
    this.imageUrl,
    this.imageFile,
    this.avatarSize,
    this.trailing,
    this.onEditTap,
  });

  final String name;
  final String phone;
  final double rating;
  final String? imageUrl;
  final File? imageFile;
  final double? avatarSize;
  final Widget? trailing;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppProfileUserAvatar(
            size: avatarSize,
            imageUrl: imageUrl,
            imageFile: imageFile,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.homeTitle.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 20.sp,
                          height: 34 / 20,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEditTap != null) ...[
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: onEditTap,
                        child: SvgPictureAsset(
                          AppAssets.icProfileEdit,
                          color: AppColors.black,
                          width: 22.w,
                          height: 24.75.h,
                          placeholderBuilder: (_) => Icon(
                            Iconsax.user_edit,
                            color: AppColors.black,
                            size: 22.w,
                          ),
                        ),
                      ),
                    ],
                    if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    phone,
                    style: AppTextStyles.homeSubtitle.copyWith(
                      color: AppColors.black,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      height: 20 / 15,
                    ),
                  ),
                ],
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPictureAsset(
                      AppAssets.icRatingStar,
                      width: 14.w,
                      height: 14.w,
                      color: AppColors.black.withValues(alpha: 0.9),
                      placeholderBuilder: (_) => Icon(
                        Icons.star,
                        color: AppColors.black.withValues(alpha: 0.9),
                        size: 14.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      rating.toStringAsFixed(1),
                      style: AppTextStyles.homeCaption.copyWith(
                        color: AppColors.black.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
