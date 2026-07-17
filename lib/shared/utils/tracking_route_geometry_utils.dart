import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/map_math_utils.dart';

/// How to interpret `route_geometry` from tracking/status socket payloads.
enum TrackingRouteGeometryKind {
  /// Missing or unparseable coordinates.
  empty,

  /// All coordinates collapse to one location (e.g. duplicate `[lng,lat]` pairs).
  repeatedLocation,

  /// At least two distinct points — draw the path from the payload.
  path,
}

/// Helpers for `ride:tracking_update` / status payloads with `route_geometry`.
abstract final class TrackingRouteGeometryUtils {
  static const double _coordinateEpsilonMeters = 1;
  static const double _equivalentRouteEpsilonMeters = 8;

  static const double _earthRadiusMeters = 6371000;

  /// GeoJSON order: `[lng, lat]` per coordinate.
  static List<LatLng> polylineFromGeoJsonCoordinates(
    List<List<double>>? coordinates,
  ) {
    if (coordinates == null || coordinates.isEmpty) return const [];
    return coordinates
        .where((c) => c.length >= 2)
        .map((c) => LatLng(c[1], c[0]))
        .toList();
  }

  static TrackingRouteGeometryKind classify(List<List<double>>? coordinates) {
    final parsed = polylineFromGeoJsonCoordinates(coordinates);
    if (parsed.isEmpty) return TrackingRouteGeometryKind.empty;
    if (distinctPoints(parsed).length <= 1) {
      return TrackingRouteGeometryKind.repeatedLocation;
    }
    return TrackingRouteGeometryKind.path;
  }

  /// Map points to store for the active route, following the socket payload shape.
  static List<LatLng> pointsForMap(List<List<double>>? coordinates) {
    final parsed = polylineFromGeoJsonCoordinates(coordinates);
    return switch (classify(coordinates)) {
      TrackingRouteGeometryKind.empty => const [],
      TrackingRouteGeometryKind.repeatedLocation => distinctPoints(parsed),
      TrackingRouteGeometryKind.path => parsed,
    };
  }

  static bool shouldDrawPolyline(List<LatLng> points) {
    return classifyFromPoints(points) == TrackingRouteGeometryKind.path;
  }

  static TrackingRouteGeometryKind classifyFromPoints(List<LatLng> points) {
    if (points.isEmpty) return TrackingRouteGeometryKind.empty;
    if (distinctPoints(points).length <= 1) {
      return TrackingRouteGeometryKind.repeatedLocation;
    }
    return TrackingRouteGeometryKind.path;
  }

  static double haversineMeters(LatLng a, LatLng b) {
    final dLat = _degreesToRadians(b.latitude - a.latitude);
    final dLng = _degreesToRadians(b.longitude - a.longitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h =
        sinDLat * sinDLat +
        math.cos(_degreesToRadians(a.latitude)) *
            math.cos(_degreesToRadians(b.latitude)) *
            sinDLng *
            sinDLng;
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  /// Collapses repeated coordinate pairs from the socket (exact/near duplicates).
  static List<LatLng> distinctPoints(
    List<LatLng> points, {
    double epsilonMeters = _coordinateEpsilonMeters,
  }) {
    final out = <LatLng>[];
    for (final p in points) {
      if (p.latitude == 0 && p.longitude == 0) continue;
      final duplicate = out.any(
        (e) => haversineMeters(e, p) <= epsilonMeters,
      );
      if (!duplicate) out.add(p);
    }
    return out;
  }

  static bool routesEquivalent(
    List<LatLng> current,
    List<LatLng> next, {
    double epsilonMeters = _equivalentRouteEpsilonMeters,
  }) {
    if (current.length != next.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (haversineMeters(current[i], next[i]) > epsilonMeters) {
        return false;
      }
    }
    return true;
  }

  /// Bearing (degrees, clockwise from north) along the route segment nearest
  /// [position]. Used when GPS heading disagrees with the drawn polyline
  /// (e.g. chained rides: driver still finishing another trip while the
  /// rider sees the path toward their pickup).
  static double? bearingAlongRouteAt(List<LatLng> route, LatLng position) {
    if (route.length < 2) return null;

    var bestSegmentStart = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < route.length - 1; i++) {
      final dist = _distancePointToSegmentMeters(
        position,
        route[i],
        route[i + 1],
      );
      if (dist < bestDist) {
        bestDist = dist;
        bestSegmentStart = i;
      }
    }

    return MapMathUtils.calculateBearing(
      route[bestSegmentStart],
      route[bestSegmentStart + 1],
    );
  }

  static double _distancePointToSegmentMeters(
    LatLng point,
    LatLng segmentStart,
    LatLng segmentEnd,
  ) {
    final segLen = haversineMeters(segmentStart, segmentEnd);
    if (segLen <= 0.5) {
      return haversineMeters(point, segmentStart);
    }

    final t = _projectPointOntoSegmentFraction(point, segmentStart, segmentEnd)
        .clamp(0.0, 1.0);
    final projected = LatLng(
      segmentStart.latitude +
          t * (segmentEnd.latitude - segmentStart.latitude),
      segmentStart.longitude +
          t * (segmentEnd.longitude - segmentStart.longitude),
    );
    return haversineMeters(point, projected);
  }

  static double _projectPointOntoSegmentFraction(
    LatLng point,
    LatLng segmentStart,
    LatLng segmentEnd,
  ) {
    final dx = segmentEnd.longitude - segmentStart.longitude;
    final dy = segmentEnd.latitude - segmentStart.latitude;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return 0;
    final px = point.longitude - segmentStart.longitude;
    final py = point.latitude - segmentStart.latitude;
    return (px * dx + py * dy) / lenSq;
  }
}
