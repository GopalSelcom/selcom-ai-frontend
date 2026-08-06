import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Shared helpers for ride navigation argument coordinates.
///
/// Callers must **not** invent city defaults (e.g. Dar es Salaam) when lat/lng
/// are missing — fail clearly or fall back to a known live map center instead.
abstract final class RideNavigationCoords {
  RideNavigationCoords._();

  /// Reads a lat/lng value from route args. Supports [num] and numeric [String].
  static double? read(Map<String, dynamic> args, String key) {
    final raw = args[key];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim());
    return null;
  }

  /// True when both values are present and within valid WGS84 ranges.
  ///
  /// Rejects `(0, 0)` so missing/placeholder coords are not treated as a real pin.
  static bool isValidLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  /// Returns a [LatLng] only when [isValidLatLng] passes; otherwise `null`.
  static LatLng? toLatLng(double? lat, double? lng) {
    if (!isValidLatLng(lat, lng)) return null;
    return LatLng(lat!, lng!);
  }
}
