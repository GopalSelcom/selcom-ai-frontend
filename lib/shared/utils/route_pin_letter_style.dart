import 'package:flutter/material.dart';

import 'map_route_marker_utils.dart';
import 'route_location_pin_assets.dart';

/// Letter + circle color for Google Maps route markers (P/D or A–G).
abstract final class RoutePinLetterStyle {
  static Color get pickupColor => RouteLocationPinAssets.pickupColor;

  static Color get destinationColor => RouteLocationPinAssets.destinationColor;

  static Color intermediateColor(int sequentialIndex) =>
      RouteLocationPinAssets.mapColorForIntermediateAt(sequentialIndex);

  static String pickupLetter({required int intermediateStopCount}) =>
      intermediateStopCount == 0 ? 'P' : MapRouteMarkerUtils.letterAt(0);

  static String destinationLetter({required int intermediateStopCount}) {
    if (intermediateStopCount == 0) return 'D';
    return MapRouteMarkerUtils.letterAt(
      MapRouteMarkerUtils.destinationLetterIndex(
        intermediateStopCount: intermediateStopCount,
      ),
    );
  }

  static String intermediateLetter(int sequentialIndex) =>
      MapRouteMarkerUtils.letterAt(sequentialIndex + 1);
}
