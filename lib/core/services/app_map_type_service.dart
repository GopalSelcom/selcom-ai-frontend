import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Session-wide map layer preference (standard vs satellite) for [AppGoogleMap].
///
/// Registered as a lazy singleton so toggling on one screen updates every map
/// in the current app session. Uses [MapType.hybrid] for satellite (imagery +
/// labels) and [MapType.normal] with brand JSON styling for the default view.
class AppMapTypeService {
  final mapType = MapType.normal.obs;

  bool get isSatelliteView => mapType.value != MapType.normal;

  void toggleMapType() {
    mapType.value =
        mapType.value == MapType.normal ? MapType.hybrid : MapType.normal;
  }
}
