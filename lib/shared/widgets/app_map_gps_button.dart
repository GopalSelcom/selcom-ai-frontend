import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/svg_picture_asset.dart';

/// Circular GPS / recenter control for map screens.
class AppMapGpsButton extends StatelessWidget {
  const AppMapGpsButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
            child: SvgPictureAsset(
              AppAssets.icGps,
              width: 24.w,
              height: 24.w,
            ),
          ),
        ),
      ),
    );
  }
}
