import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../utils/tracking_route_geometry_utils.dart';

/// Brand-consistent, high-contrast route line for [AppGoogleMap] polylines.
abstract final class AppMapRoutePolyline {
  AppMapRoutePolyline._();

  static const int lineWidth = 4;
  static const int casingWidth = 6;

  static Set<Polyline> set({
    required String polylineId,
    required List<LatLng> points,
  }) {
    if (!TrackingRouteGeometryUtils.shouldDrawPolyline(points)) {
      return const {};
    }

    return {
      Polyline(
        polylineId: PolylineId('${polylineId}_casing'),
        points: points,
        color: AppColors.mapRouteLineCasing,
        width: casingWidth,
        zIndex: 0,
      ),
      Polyline(
        polylineId: PolylineId(polylineId),
        points: points,
        color: AppColors.mapRouteLine,
        width: lineWidth,
        zIndex: 1,
      ),
    };
  }
}
