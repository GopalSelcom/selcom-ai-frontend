import 'package:get/get.dart';

import '../../core/localization/app_strings.dart';

/// Display formatting for trip / route distances in kilometres.
abstract final class DistanceDisplay {
  DistanceDisplay._();

  static String formatKm(double? km) {
    if (km == null || km <= 0) return '';
    if (km < 0.1) return AppStrings.distanceMinKm.tr;
    if (km > 999) return AppStrings.distanceMaxKm.tr;

    final rounded = (km * 10).roundToDouble() / 10;
    final value = rounded % 1 == 0
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(1);

    return AppStrings.distanceKmFormat.trParams({'value': value});
  }
}
