import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_assets.dart';
import '../../core/utils/map_math_utils.dart';

/// Resolves map driver-marker SVG assets (not UI vehicle illustrations).
class MapVehicleMarkerUtils {
  const MapVehicleMarkerUtils._();

  static const int defaultMarkerWidth = 70;

  /// Minimum movement before recalculating facing from GPS path (meters).
  static const double minMovementMetersForBearing = 2.0;

  /// Below this speed, keep the last rotation instead of trusting noisy heading.
  static const double minSpeedMpsForRotationUpdate = 0.3;

  static String markerAssetForVehicleType(
    String? vehicleType, {
    String fallbackAsset = AppAssets.mapMarkerCab,
  }) {
    final type = (vehicleType ?? '').toLowerCase().trim();
    if (type.isEmpty) return fallbackAsset;

    if (_containsAny(type, const ['boda', 'bike', 'motor', 'moto'])) {
      return AppAssets.mapMarkerBoda;
    }

    if (_containsAny(type, const [
      'bajaj',
      'bajaji',
      'auto',
      'rickshaw',
      'tuk',
      'wheeler',
    ])) {
      return AppAssets.mapMarkerBajaji;
    }

    if (_containsAny(type, const [
      'car',
      'cab',
      'taxi',
      'van',
      'four wheeler',
    ])) {
      return AppAssets.mapMarkerCab;
    }

    return fallbackAsset;
  }

  static bool _containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) return true;
    }
    return false;
  }

  /// Parses socket/API heading (degrees clockwise from north).
  static double? parseHeadingDegrees(dynamic heading) {
    if (heading == null) return null;
    if (heading is num) {
      final value = heading.toDouble();
      return value.isFinite ? value : null;
    }
    if (heading is String) {
      final value = double.tryParse(heading.trim());
      return value != null && value.isFinite ? value : null;
    }
    return null;
  }

  /// Map marker SVGs face **north** at 0°. Prefer movement bearing so the icon
  /// matches travel direction (N/S/E/W); fall back to GPS heading when idle.
  static double resolveMarkerRotation({
    LatLng? previousPosition,
    required LatLng currentPosition,
    double? headingDegrees,
    double? previousRotation,
    double speedMps = 0,
  }) {
    if (previousRotation != null && speedMps < minSpeedMpsForRotationUpdate) {
      return previousRotation;
    }

    if (previousPosition != null &&
        speedMps >= minSpeedMpsForRotationUpdate) {
      final movedMeters = _distanceMeters(previousPosition, currentPosition);
      if (movedMeters >= minMovementMetersForBearing) {
        return MapMathUtils.calculateBearing(
          previousPosition,
          currentPosition,
        );
      }
    }

    if (headingDegrees != null && speedMps >= minSpeedMpsForRotationUpdate) {
      return _normalizeDegrees(headingDegrees);
    }

    if (previousRotation != null) {
      return previousRotation;
    }

    if (headingDegrees != null) {
      return _normalizeDegrees(headingDegrees);
    }

    return 0;
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _degreesToRadians(b.latitude - a.latitude);
    final dLng = _degreesToRadians(b.longitude - a.longitude);
    final lat1 = _degreesToRadians(a.latitude);
    final lat2 = _degreesToRadians(b.latitude);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _degreesToRadians(double degrees) =>
      degrees * math.pi / 180.0;

  static double _normalizeDegrees(double degrees) {
    final mod = degrees % 360;
    return mod < 0 ? mod + 360 : mod;
  }
}
