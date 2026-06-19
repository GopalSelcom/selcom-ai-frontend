import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// Route row + map pin colors (pickup, intermediate stops, destination).
abstract final class RouteLocationPinAssets {
  static const Color destinationColor = AppColors.routePinDestination;

  static Color get pickupColor => AppColors.primary;

  /// Classic map pin — pickup only (different shape from [waypointPin]).
  static String get pickup => AppAssets.locationIcPickupPin;

  /// Teardrop pin shared by intermediate stops and destination (tint per role).
  static String get waypointPin => AppAssets.locationIcDestinationPin;

  static String get destination => waypointPin;

  /// Distinct tint per intermediate stop (cycles when there are many stops).
  static const List<Color> intermediatePinColors = [
    AppColors.routePinStop1,
    AppColors.routePinStop2,
    AppColors.iconPurple,
    AppColors.iconOrange,
    AppColors.iconWarning,
  ];

  static Color colorForIntermediateAt(int sequentialIndex) {
    if (sequentialIndex < 0) {
      return intermediatePinColors.first;
    }
    return intermediatePinColors[
        sequentialIndex % intermediatePinColors.length];
  }

  /// Map circle color for an intermediate stop at [sequentialIndex] (0 = first).
  static Color mapColorForIntermediateAt(int sequentialIndex) =>
      colorForIntermediateAt(sequentialIndex);
}
