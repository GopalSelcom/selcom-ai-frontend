import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/widgets/svg_picture_asset.dart';
import '../utils/route_location_pin_assets.dart';

/// SVG route pin for list rows (location selection, ride details, PDF, etc.).
class AppRouteLocationPinIcon extends StatelessWidget {
  const AppRouteLocationPinIcon({
    super.key,
    required this.assetPath,
    this.tintColor,
    this.size,
  });

  AppRouteLocationPinIcon.pickup({super.key, this.size})
    : assetPath = RouteLocationPinAssets.pickup,
      tintColor = RouteLocationPinAssets.pickupColor;

  AppRouteLocationPinIcon.destination({super.key, this.size})
    : assetPath = RouteLocationPinAssets.destination,
      tintColor = null;

  AppRouteLocationPinIcon.stop(int index, {super.key, this.size})
    : assetPath = RouteLocationPinAssets.stopAssetAt(index),
      tintColor = null;

  final String assetPath;
  final Color? tintColor;
  final double? size;

  double get _aspectRatio {
    if (assetPath == RouteLocationPinAssets.pickup) return 34 / 25;
    return 19 / 13;
  }

  @override
  Widget build(BuildContext context) {
    final width = size ?? 18.w;
    final height = width * _aspectRatio;

    final picture = SvgPictureAsset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );

    return SizedBox(
      width: width,
      height: height,
      child: tintColor == null
          ? picture
          : ColorFiltered(
              colorFilter: ColorFilter.mode(tintColor!, BlendMode.srcIn),
              child: picture,
            ),
    );
  }
}
