import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/widgets/svg_picture_asset.dart';

/// Circular GPS / recenter control for map screens.
class AppMapGpsButton extends StatelessWidget {
  const AppMapGpsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.only(bottom: 24.w),
        child: SvgPictureAsset(AppAssets.icGps, width: 48.w, height: 48.w),
      ),
    );
  }
}
