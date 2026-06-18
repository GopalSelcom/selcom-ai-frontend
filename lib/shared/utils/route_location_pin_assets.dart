import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Route row pin assets and map marker colors (pickup, stops, destination).
abstract final class RouteLocationPinAssets {
  static const Color stop1Color = AppColors.routePinStop1;
  static const Color stop2Color = AppColors.routePinStop2;
  static const Color destinationColor = AppColors.routePinDestination;

  static Color get pickupColor => AppColors.primary;

  static String get pickup => AppAssets.locationIcPickupPin;

  static String get destination => AppAssets.locationIcDestinationPin;

  static String stopAssetAt(int index) {
    if (index <= 0) return AppAssets.locationIcStop1;
    return AppAssets.locationIcStop2;
  }

  /// Map circle color for an intermediate stop at [sequentialIndex] (0 = first).
  static Color mapColorForIntermediateAt(int sequentialIndex) {
    if (sequentialIndex <= 0) return stop1Color;
    return stop2Color;
  }
}
