import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/utils/map_math_utils.dart';
import 'app_google_map.dart';

mixin MapRiderTrackingMixin on State<AppGoogleMap>, TickerProviderStateMixin<AppGoogleMap> {
  late AnimationController _positionController;

  DateTime? _lastUpdateAt;

  LatLng? _currentAnimatedPosition;
  LatLng? _previousPosition;
  LatLng? _targetPosition;
  double? _currentAnimatedRotation;
  double? _previousRotation;
  double? _targetRotation;
  final List<int> _intervalHistory = [];

  /// Callback called on every frame of the position animation.
  void Function(LatLng position, double rotation)? onAnimatedPositionUpdate;

  /// The current interpolated position of the rider icon.
  LatLng? get currentAnimatedPosition => _currentAnimatedPosition;

  @override
  void initState() {
    super.initState();
    _positionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Initial guess
    );

    _positionController.addListener(() {
      if (_previousPosition != null && _targetPosition != null) {
        setState(() {
          _currentAnimatedPosition = MapMathUtils.interpolate(
            _previousPosition!,
            _targetPosition!,
            _positionController.value,
          );
          
          if (_previousRotation != null && _targetRotation != null) {
            _currentAnimatedRotation = MapMathUtils.interpolateRotation(
              _previousRotation!,
              _targetRotation!,
              _positionController.value,
            );
          } else {
            _currentAnimatedRotation = _targetRotation;
          }

          onAnimatedPositionUpdate?.call(
            _currentAnimatedPosition!,
            _currentAnimatedRotation ?? 0.0,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  void updateRiderTracking(Marker? riderMarker) {
    if (riderMarker == null) return;

    final newPosition = riderMarker.position;

    // Handle first point case
    if (_targetPosition == null) {
      _currentAnimatedPosition = newPosition;
      _targetPosition = newPosition;
      _previousPosition = newPosition;
      _currentAnimatedRotation = riderMarker.rotation;
      _targetRotation = riderMarker.rotation;
      _previousRotation = riderMarker.rotation;
      return;
    }

    final now = DateTime.now();
    if (_lastUpdateAt != null) {
      final lastInterval = now.difference(_lastUpdateAt!).inMilliseconds;
      if (lastInterval > 500) {
        _intervalHistory.add(lastInterval);
        if (_intervalHistory.length > 3) _intervalHistory.removeAt(0);
      }

      final avgInterval = _intervalHistory.isEmpty
          ? 15000
          : _intervalHistory.reduce((a, b) => a + b) ~/ _intervalHistory.length;

      // For long intervals (15s+), use a 1.1x multiplier to provide a buffer
      // that keeps the bike gliding even if the next update is slightly late.
      // For short intervals (< 5s), use 0.8x to catch up quickly.
      double multiplier = avgInterval > 8000 ? 1.1 : 0.8;

      _positionController.duration = Duration(
        milliseconds: (avgInterval * multiplier).toInt().clamp(1000, 30000),
      );
    } else {
      // Default guess for the first update
      _positionController.duration = const Duration(seconds: 15);
    }
    _lastUpdateAt = now;
  }

  /// Instantly snaps the rider icon to a position without animation.
  void snapPosition(LatLng position, {double rotation = 0.0}) {
    _positionController.stop();
    _currentAnimatedPosition = position;
    _targetPosition = position;
    _previousPosition = position;
    _currentAnimatedRotation = rotation;
    _targetRotation = rotation;
    _previousRotation = rotation;
  }

  /// Updates the rider's target position and starts a smooth animation towards it.
  /// [duration] should match the frequency of data updates (e.g. 3.5s for 3s updates).
  void updateRiderPosition(LatLng newPosition, {double rotation = 0.0, Duration duration = const Duration(milliseconds: 3500)}) {
    // Always start the new animation from where the bike is CURRENTLY standing.
    // This is the key to buttery-smooth movement without jumps.
    _previousPosition = _currentAnimatedPosition ?? _targetPosition ?? newPosition;
    _targetPosition = newPosition;

    _previousRotation = _currentAnimatedRotation ?? _targetRotation ?? rotation;
    _targetRotation = rotation;

    _positionController.duration = duration;
    _positionController.forward(from: 0.0);
  }

  /// Injects the animated rider marker into the markers set
  Set<Marker> getAnimatedMarkers(Set<Marker> originalMarkers) {
    if (_currentAnimatedPosition == null) return originalMarkers;

    return originalMarkers.map((marker) {
      if (marker.markerId.value == 'assigned_driver') {
        return marker.copyWith(
          positionParam: _currentAnimatedPosition,
          rotationParam: _currentAnimatedRotation,
        );
      }
      return marker;
    }).toSet();
  }
}
