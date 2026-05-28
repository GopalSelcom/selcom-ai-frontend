import '../../core/constants/app_assets.dart';

/// Resolves map driver-marker SVG assets (not UI vehicle illustrations).
class MapVehicleMarkerUtils {
  const MapVehicleMarkerUtils._();

  static const int defaultMarkerWidth = 70;

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
}
