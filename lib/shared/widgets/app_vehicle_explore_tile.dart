import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';
import 'vehicle_type_image.dart';

/// GO UI vehicle chip: bordered tile with illustration overflowing the sides.
class AppVehicleExploreTile extends StatelessWidget {
  const AppVehicleExploreTile({
    super.key,
    required this.assetPath,
    this.tileSize = defaultTileSize,
    this.imageSideOverflow = defaultImageSideOverflow,
  });

  static const double defaultTileSize = 72;
  static const double defaultImageSideOverflow = 16;

  final String assetPath;
  final double tileSize;
  final double imageSideOverflow;

  BoxDecoration get _tileDecoration => BoxDecoration(
    color: AppColors.bgSoftCircle,
    borderRadius: BorderRadius.circular(16.r),
    border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tileSize.w,
      height: tileSize.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(child: DecoratedBox(decoration: _tileDecoration)),
          Positioned(
            left: 0.8,
            right: -imageSideOverflow.w,
            bottom: 0,
            height: tileSize.h,
            child: VehicleTypeImage(
              assetPath: assetPath,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              fallbackIconColor: AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }
}
