import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
class AppGoogleMap extends StatefulWidget {
  const AppGoogleMap({
    super.key,
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
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.mapToolbarEnabled = false,
    this.compassEnabled = false,
    this.mapType = MapType.normal,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.indoorViewEnabled = true,
    this.liteModeEnabled = false,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.gestureRecognizers,
    this.onCameraMove,
    this.onCameraIdle,
    this.onCameraMoveStarted,
    this.onTap,
    this.onLongPress,
    this.mapWidgetKey,
    this.cloudMapId,
    this.style,
    this.onUserInteraction,
    this.onGpsPressed,
    this.onNavigationPressed,
    this.showGpsButton = false,
    this.trackRider = false,
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
  final VoidCallback? onUserInteraction;
  final VoidCallback? onGpsPressed;
  final VoidCallback? onNavigationPressed;
  final bool showGpsButton;
  final bool trackRider;

  @override
  State<AppGoogleMap> createState() => _AppGoogleMapState();
}

class _AppGoogleMapState extends State<AppGoogleMap> {
  GoogleMapController? _controller;
  late bool _isTrackingRider;
  bool _isProgrammaticMove = false;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _isTrackingRider = widget.trackRider;
  }

  @override
  void didUpdateWidget(AppGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trackRider != oldWidget.trackRider) {
      _isTrackingRider = widget.trackRider;
    }
    if (_isTrackingRider) {
      final riderMarker = _findRiderMarker();
      if (riderMarker != null) {
        final oldRiderMarker = _findRiderMarker(markers: oldWidget.markers);
        if (oldRiderMarker == null ||
            oldRiderMarker.position != riderMarker.position) {
          _moveToRider();
        }
      }
    }
  }

  Marker? _findRiderMarker({Set<Marker>? markers}) {
    final searchSet = markers ?? widget.markers;
    try {
      return searchSet.firstWhere((m) => m.markerId.value == 'assigned_driver');
    } catch (_) {
      return null;
    }
  }

  void _moveToRider() {
    final rider = _findRiderMarker();
    if (rider != null && _controller != null) {
      _isProgrammaticMove = true;
      _controller!.animateCamera(
        CameraUpdate.newLatLngZoom(rider.position, 16.0),
      );
    }
  }

  void _retrack() {
    setState(() {
      _isTrackingRider = true;
    });
    _moveToRider();
    widget.onNavigationPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasRider = _findRiderMarker() != null;

    return Stack(
      children: [
        Listener(
          onPointerDown: (_) {
            _isUserInteracting = true;
            widget.onUserInteraction?.call();
          },
          onPointerUp: (_) => _isUserInteracting = false,
          onPointerCancel: (_) => _isUserInteracting = false,
          child: GoogleMap(
            key: widget.mapWidgetKey,
            initialCameraPosition: widget.initialCameraPosition,
            onMapCreated: (controller) {
              _controller = controller;
              widget.onMapCreated(controller);
              if (_isTrackingRider) _moveToRider();
            },
            markers: widget.markers,
            polylines: widget.polylines,
            circles: widget.circles,
            polygons: widget.polygons,
            heatmaps: widget.heatmaps,
            tileOverlays: widget.tileOverlays,
            padding: widget.padding,
            cameraTargetBounds: widget.cameraTargetBounds,
            myLocationEnabled: widget.myLocationEnabled,
            myLocationButtonEnabled: widget.myLocationButtonEnabled,
            zoomControlsEnabled: widget.zoomControlsEnabled,
            mapToolbarEnabled: widget.mapToolbarEnabled,
            compassEnabled: widget.compassEnabled,
            mapType: widget.mapType,
            trafficEnabled: widget.trafficEnabled,
            buildingsEnabled: widget.buildingsEnabled,
            indoorViewEnabled: widget.indoorViewEnabled,
            liteModeEnabled: widget.liteModeEnabled,
            minMaxZoomPreference: widget.minMaxZoomPreference,
            gestureRecognizers:
                widget.gestureRecognizers ??
                <Factory<OneSequenceGestureRecognizer>>{},
            onCameraMove: widget.onCameraMove,
            onCameraIdle: () {
              _isProgrammaticMove = false;
              widget.onCameraIdle?.call();
            },
            onCameraMoveStarted: () {
              if (_isUserInteracting && !_isProgrammaticMove) {
                setState(() {
                  _isTrackingRider = false;
                });
              }
              widget.onCameraMoveStarted?.call();
            },
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            cloudMapId: widget.cloudMapId,
            style: widget.style,
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 110.h,
          right: 16.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasRider && !_isTrackingRider) ...[
                _IconActionButton(
                  icon: Icons.navigation,
                  onPressed: _retrack,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 12.h),
              ],
              if (widget.showGpsButton)
                _IconActionButton(
                  icon: Icons.gps_fixed,
                  onPressed: widget.onGpsPressed,
                  color: Colors.black54,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
