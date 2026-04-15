import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/app_map_service.dart';

/// **Canonical embedded map for the app** (`lib/shared/widgets/`).
///
/// All feature screens that show a Google Map must compose this widget — **do
/// not** construct [GoogleMap] directly outside [AppGoogleMap] (this file is
/// the only allowed wrapper). That keeps zoom/toolbar/compass defaults and
/// future global styling changes in one place.
///
/// Import via `map_widgets.dart` when you also need [AppMapService],
/// [AppMapGpsButton], or [AppMapTopHeader].
///
/// See [AppMapService] for projection helpers (`screenOffsetFor`, etc.).
class AppGoogleMap extends StatelessWidget {
  const AppGoogleMap({
    super.key,
    this.mapWidgetKey,
    required this.initialCameraPosition,
    required this.onMapCreated,
    this.markers = const <Marker>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.polygons = const <Polygon>{},
    this.heatmaps = const <Heatmap>{},
    this.tileOverlays = const <TileOverlay>{},
    this.padding = EdgeInsets.zero,
    this.cameraTargetBounds = CameraTargetBounds.unbounded,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = AppMapService.standardMyLocationButtonEnabled,
    this.zoomControlsEnabled = AppMapService.standardZoomControlsEnabled,
    this.mapToolbarEnabled = AppMapService.standardMapToolbarEnabled,
    this.compassEnabled = AppMapService.standardCompassEnabled,
    this.mapType = MapType.normal,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.indoorViewEnabled = false,
    this.liteModeEnabled = false,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.gestureRecognizers,
    this.onCameraMove,
    this.onCameraIdle,
    this.onCameraMoveStarted,
    this.onTap,
    this.onLongPress,
    this.cloudMapId,
    this.style,
  });

  /// Optional key on the inner [GoogleMap] (per-screen identity for rebuilds).
  final Key? mapWidgetKey;

  final CameraPosition initialCameraPosition;
  final void Function(GoogleMapController controller) onMapCreated;

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Circle> circles;
  final Set<Polygon> polygons;
  final Set<Heatmap> heatmaps;
  final Set<TileOverlay> tileOverlays;
  final EdgeInsets padding;
  final CameraTargetBounds cameraTargetBounds;

  final bool myLocationEnabled;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;
  final bool mapToolbarEnabled;
  final bool compassEnabled;
  final MapType mapType;
  final bool trafficEnabled;
  final bool buildingsEnabled;
  final bool indoorViewEnabled;
  final bool liteModeEnabled;
  final MinMaxZoomPreference minMaxZoomPreference;

  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  final ArgumentCallback<CameraPosition>? onCameraMove;
  final VoidCallback? onCameraIdle;
  final VoidCallback? onCameraMoveStarted;
  final ArgumentCallback<LatLng>? onTap;
  final ArgumentCallback<LatLng>? onLongPress;

  final String? cloudMapId;
  final String? style;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      key: mapWidgetKey,
      initialCameraPosition: initialCameraPosition,
      onMapCreated: onMapCreated,
      markers: markers,
      polylines: polylines,
      circles: circles,
      polygons: polygons,
      heatmaps: heatmaps,
      tileOverlays: tileOverlays,
      padding: padding,
      cameraTargetBounds: cameraTargetBounds,
      myLocationEnabled: myLocationEnabled,
      myLocationButtonEnabled: myLocationButtonEnabled,
      zoomControlsEnabled: zoomControlsEnabled,
      mapToolbarEnabled: mapToolbarEnabled,
      compassEnabled: compassEnabled,
      mapType: mapType,
      trafficEnabled: trafficEnabled,
      buildingsEnabled: buildingsEnabled,
      indoorViewEnabled: indoorViewEnabled,
      liteModeEnabled: liteModeEnabled,
      minMaxZoomPreference: minMaxZoomPreference,
      gestureRecognizers:
          gestureRecognizers ?? <Factory<OneSequenceGestureRecognizer>>{},
      onCameraMove: onCameraMove,
      onCameraIdle: onCameraIdle,
      onCameraMoveStarted: onCameraMoveStarted,
      onTap: onTap,
      onLongPress: onLongPress,
      cloudMapId: cloudMapId,
      style: style,
    );
  }
}
