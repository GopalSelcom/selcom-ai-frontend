import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/widgets/svg_picture_asset.dart';

/// Renders a vehicle illustration from [assetPath] (PNG or SVG).
class VehicleTypeImage extends StatelessWidget {
  const VehicleTypeImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallbackIcon = Icons.directions_car,
    this.fallbackIconColor,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;

  @override
  Widget build(BuildContext context) {
    final w = width;
    final h = height;

    if (assetPath.endsWith('.svg')) {
      return SvgPictureAsset(
        assetPath,
        width: w,
        height: h,
        fit: fit,
        alignment: alignment,
        placeholderBuilder: (_) => _fallbackIcon(),
      );
    }

    return Align(
      alignment: alignment,
      child: Image.asset(
        assetPath,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      fallbackIcon,
      color: fallbackIconColor,
      size: (height ?? width ?? 28).sp,
    );
  }
}
