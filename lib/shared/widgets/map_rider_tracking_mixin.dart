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
  final List<int> _intervalHistory = [];

  /// Callback called on every frame of the position animation.
  void Function(LatLng)? onAnimatedPositionUpdate;

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
          onAnimatedPositionUpdate?.call(_currentAnimatedPosition!);
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

    // Only update if position actually changed significantly
    if (newPosition != _targetPosition) {
      // Jitter filter: ignore tiny movements (~2m) to prevent drifting while stationary
      final dist = MapMathUtils.calculateSimpleDist(newPosition, _targetPosition!);
      if (dist < 0.00002) return;

      _previousPosition = _currentAnimatedPosition ?? _targetPosition;
      _targetPosition = newPosition;

      // Calculate duration based on 1km/hr speed (~0.27 m/s)
      // 1km/hr = 0.0000025 degrees per second (approx)
      const double speedDegreesPerSecond = 0.0000025;
      final double travelDist = MapMathUtils.calculateSimpleDist(_previousPosition!, _targetPosition!);
      
      int durationMs = (travelDist / speedDegreesPerSecond * 1000).toInt();
      
      // Clamp duration between 1s and 10s to keep it responsive but smooth
      _positionController.duration = Duration(
        milliseconds: durationMs.clamp(1000, 10000),
      );

      // Start position animation
      _positionController.forward(from: 0.0);
    }
  }

  /// Injects the animated rider marker into the markers set
  Set<Marker> getAnimatedMarkers(Set<Marker> originalMarkers) {
    if (_currentAnimatedPosition == null) return originalMarkers;

    return originalMarkers.map((marker) {
      if (marker.markerId.value == 'assigned_driver') {
        return marker.copyWith(
          positionParam: _currentAnimatedPosition,
        );
      }
      return marker;
    }).toSet();
  }
}
