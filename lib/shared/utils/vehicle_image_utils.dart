import '../../core/constants/app_assets.dart';

class VehicleImageUtils {
  const VehicleImageUtils._();

  static String imageAssetForVehicleType(
    String? vehicleType, {
    String fallbackAsset = AppAssets.imgCab,
  }) {
    final type = (vehicleType ?? '').toLowerCase().trim();
    if (type.isEmpty) return fallbackAsset;

    if (_containsAny(type, const ['boda', 'bike', 'motor', 'moto'])) {
      return AppAssets.imgBoda;
    }

    if (_containsAny(type, const [
      'bajaj',
      'auto',
      'rickshaw',
      'tuk',
      'wheeler',
    ])) {
      return AppAssets.imgBajaji;
    }

    return AppAssets.imgCab;
  }

  static bool _containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) return true;
    }
    return false;
  }
}
