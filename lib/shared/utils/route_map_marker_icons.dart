import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/map_marker_utils.dart';
import 'map_route_marker_utils.dart';
import 'route_pin_letter_style.dart';

/// Cached circle + letter bitmaps for Google Maps route markers.
abstract final class RouteMapMarkerIcons {
  static final Map<String, BitmapDescriptor> _cache = {};

  static String _cacheKey(String letter, int colorValue) => '$letter|$colorValue';

  static Future<BitmapDescriptor> pin({
    required String letter,
    required Color color,
  }) async {
    final key = _cacheKey(letter, color.toARGB32());
    final cached = _cache[key];
    if (cached != null) return cached;

    final icon = await MapMarkerUtils.createTextMarker(
      text: letter,
      color: color,
    );
    _cache[key] = icon;
    return icon;
  }

  static BitmapDescriptor? cached({
    required String letter,
    required Color color,
  }) =>
      _cache[_cacheKey(letter, color.toARGB32())];

  static Future<void> ensureLetterPinCache() async {
    await pin(letter: 'P', color: RoutePinLetterStyle.pickupColor);
    await pin(letter: 'D', color: RoutePinLetterStyle.destinationColor);
    await pin(letter: 'A', color: RoutePinLetterStyle.pickupColor);

    for (int i = 0; i < MapRouteMarkerUtils.routeLetters.length - 1; i++) {
      final letter = MapRouteMarkerUtils.letterAt(i + 1);
      await pin(
        letter: letter,
        color: RoutePinLetterStyle.intermediateColor(i),
      );
    }

    for (int i = 1; i < MapRouteMarkerUtils.routeLetters.length; i++) {
      final letter = MapRouteMarkerUtils.routeLetters[i];
      await pin(letter: letter, color: RoutePinLetterStyle.destinationColor);
    }
  }
}
