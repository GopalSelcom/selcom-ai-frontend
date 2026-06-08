/// Lettered route markers for multi-stop rides (A = pickup, B… = stops, last = destination).
class MapRouteMarkerUtils {
  MapRouteMarkerUtils._();

  static const List<String> routeLetters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
  ];

  static bool stopMatchesDestination({
    required double stopLat,
    required double stopLng,
    required String stopAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
  }) {
    final normalizedDestination = destinationAddress.trim().toLowerCase();
    if (normalizedDestination.isNotEmpty &&
        stopAddress.trim().toLowerCase() == normalizedDestination) {
      return true;
    }
    return (stopLat - destinationLat).abs() < 0.000001 &&
        (stopLng - destinationLng).abs() < 0.000001;
  }

  static bool stopMatchesPickup({
    required double stopLat,
    required double stopLng,
    required String stopAddress,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
  }) {
    final normalizedPickup = pickupAddress.trim().toLowerCase();
    if (normalizedPickup.isNotEmpty &&
        stopAddress.trim().toLowerCase() == normalizedPickup) {
      return true;
    }
    return (stopLat - pickupLat).abs() < 0.000001 &&
        (stopLng - pickupLng).abs() < 0.000001;
  }

  /// Removes duplicate waypoint rows that share the same location.
  static List<T> dedupeByLocation<T>({
    required List<T> items,
    required double Function(T) lat,
    required double Function(T) lng,
    required String Function(T) address,
  }) {
    final seen = <String>{};
    final out = <T>[];
    for (final item in items) {
      final key =
          '${lat(item).toStringAsFixed(5)}|'
          '${lng(item).toStringAsFixed(5)}|'
          '${address(item).trim().toLowerCase()}';
      if (seen.add(key)) {
        out.add(item);
      }
    }
    return out;
  }

  /// Letter index for the final destination (A = 0 pickup, B = 1, …).
  static int destinationLetterIndex({required int intermediateStopCount}) =>
      intermediateStopCount + 1;

  static String letterAt(int index) {
    if (index < 0) return routeLetters.first;
    if (index >= routeLetters.length) return routeLetters.last;
    return routeLetters[index];
  }

  static bool usesMultiStopMarkers({
    required bool isMultiStopFlag,
    required int intermediateStopCount,
  }) =>
      isMultiStopFlag || intermediateStopCount > 0;
}
