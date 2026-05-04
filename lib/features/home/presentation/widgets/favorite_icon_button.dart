import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/svg_picture_asset.dart';

class FavoriteIconButton extends StatelessWidget {
  const FavoriteIconButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.size = 22,
    this.padding,
    this.constraints,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final double size;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: padding,
      constraints: constraints,
      onPressed: onPressed,
      icon: SvgPictureAsset(
        isFavorite
            ? AppAssets.locationIcHeartFilled
            : AppAssets.locationIcHeartOutline,
        width: size.w,
        height: size.h,
        color: isFavorite
            ? AppColors.iconHeartFilled
            : AppColors.iconHeartOutline,
        placeholderBuilder: (_) => Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite
              ? AppColors.iconHeartFilled
              : AppColors.iconHeartOutline,
          size: size.sp,
        ),
      ),
    );
  }
}
