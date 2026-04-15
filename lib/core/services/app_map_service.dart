import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared map configuration and helpers for all screens that embed [GoogleMap].
///
/// Controllers still own [GoogleMapController] references and feature-specific
/// markers/polylines; this layer keeps UX defaults and safe projection helpers
/// in one place.
class AppMapService {
  AppMapService._();

  // ── Standard UI chrome (minimal; we use [AppMapGpsButton] instead of the SDK button)
  static const bool standardZoomControlsEnabled = false;
  static const bool standardMapToolbarEnabled = false;
  static const bool standardCompassEnabled = false;
  static const bool standardMyLocationButtonEnabled = false;

  /// Converts geographic coordinates to map-widget pixel coordinates.
  /// Returns null if the projection is unavailable (e.g. map not ready).
  static Future<ScreenCoordinate?> screenCoordinateFor(
    GoogleMapController controller,
    LatLng latLng,
  ) async {
    try {
      return await controller.getScreenCoordinate(latLng);
    } catch (_) {
      return null;
    }
  }

  /// Same as [screenCoordinateFor], but returns a [Offset] for overlay positioning.
  static Future<Offset?> screenOffsetFor(
    GoogleMapController controller,
    LatLng latLng,
  ) async {
    final sc = await screenCoordinateFor(controller, latLng);
    if (sc == null) return null;
    return Offset(sc.x.toDouble(), sc.y.toDouble());
  }
}
