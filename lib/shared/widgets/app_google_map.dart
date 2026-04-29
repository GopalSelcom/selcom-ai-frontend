import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/app_map_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/map_math_utils.dart';
import 'map_rider_tracking_mixin.dart';

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
    this.onRiderPositionUpdate,
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
  final void Function(LatLng)? onRiderPositionUpdate;

  @override
  State<AppGoogleMap> createState() => AppGoogleMapState();
}

class AppGoogleMapState extends State<AppGoogleMap>
    with TickerProviderStateMixin<AppGoogleMap>, MapRiderTrackingMixin {
  GoogleMapController? _controller;
  late bool _isTrackingRider;
  DateTime? _lastCameraUpdateAt;
  bool _isProgrammaticMove = false;
  bool _isUserInteracting = false;
  LatLng? _initialRiderPos;
  bool _didAutoTrackFirstMove = false;

  @override
  void initState() {
    super.initState();
    _isTrackingRider = widget.trackRider;

    // Link the animated marker position to the camera for smooth following
    onAnimatedPositionUpdate = (position) {
      final now = DateTime.now();

      // Auto-focus on the first real movement of the rider
      if (!_didAutoTrackFirstMove && _initialRiderPos != null) {
        final dist =
            MapMathUtils.calculateSimpleDist(position, _initialRiderPos!);
        // If moved more than ~10 meters, auto-track
        if (dist > 0.0001) {
          _didAutoTrackFirstMove = true;
          // Only auto-track if not already tracking
          if (!_isTrackingRider) {
            _retrack();
          }
        }
      }

      if (_isTrackingRider && _controller != null) {
        // Throttle camera updates to ~10fps to prevent vibration/jitter and battery drain.
        if (_lastCameraUpdateAt == null ||
            now.difference(_lastCameraUpdateAt!) >
                const Duration(milliseconds: 100)) {
          _lastCameraUpdateAt = now;
          // Maintain 18.5 zoom during active tracking
          _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(position, 18.5),
          );
        }
      }
      widget.onRiderPositionUpdate?.call(position);
    };
  }

  @override
  void didUpdateWidget(AppGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trackRider != oldWidget.trackRider) {
      _isTrackingRider = widget.trackRider;
    }
    final riderMarker = _findRiderMarker();
    if (riderMarker != null) {
      _initialRiderPos ??= riderMarker.position;
      updateRiderTracking(riderMarker);
      if (_isTrackingRider) {
        final oldRiderMarker = _findRiderMarker(markers: oldWidget.markers);
        // Only use animateCamera for the very first time we see the rider
        // or if tracking was just enabled. Subsequent movement is handled
        // frame-by-frame in the mixin's onAnimatedPositionUpdate.
        if (oldRiderMarker == null) {
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
        CameraUpdate.newLatLngZoom(rider.position, 18.5),
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

  void retrack() => _retrack();

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
            markers: getAnimatedMarkers(widget.markers),
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
                  color: AppColors.textMapHint,
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
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
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
