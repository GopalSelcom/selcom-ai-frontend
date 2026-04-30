import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMathUtils {
  /// Calculates the bearing between two coordinates in degrees.
  static double calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * pi / 180.0;
    final double lon1 = start.longitude * pi / 180.0;
    final double lat2 = end.latitude * pi / 180.0;
    final double lon2 = end.longitude * pi / 180.0;

    final double dLon = lon2 - lon1;

    final double y = sin(dLon) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    double bearing = atan2(y, x) * 180.0 / pi;
    return (bearing + 360.0) % 360.0;
  }

  /// Linearly interpolates between two LatLngs.
  static LatLng interpolate(LatLng start, LatLng end, double fraction) {
    final double lat = (end.latitude - start.latitude) * fraction + start.latitude;
    double lngDelta = end.longitude - start.longitude;

    // Handle wrapping around the 180th meridian
    if (lngDelta.abs() > 180.0) {
      lngDelta -= lngDelta.sign * 360.0;
    }
    final double lng = lngDelta * fraction + start.longitude;

    return LatLng(lat, lng);
  }

  /// Linearly interpolates between two angles in degrees, handling wrapping.
  static double interpolateRotation(double start, double end, double fraction) {
    double diff = (end - start + 180) % 360 - 180;
    return (start + diff * fraction + 360) % 360;
  }

  /// Manhattan distance (approximate for short distances)
  static double calculateSimpleDist(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() + (a.longitude - b.longitude).abs();
  }
}
