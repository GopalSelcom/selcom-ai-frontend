import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../services/error_reporting/error_reporter.dart';

/// Monitors internet connectivity and notifies listeners when connection is restored
class NetworkConnectivityService {
  static final NetworkConnectivityService instance =
      NetworkConnectivityService._();

  NetworkConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  Timer? _checkTimer;
  bool _isOnline = true;
  bool _isMonitoring = false;

  /// Stream that emits connectivity status changes
  Stream<bool> get connectivityStream => _controller.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Start monitoring connectivity
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint("🌐 NetworkConnectivityService: Started monitoring");

    // Initial check
    _checkConnection().then((isOnline) {
      _isOnline = isOnline;
      if (!isOnline) {
        _startPeriodicCheck();
      }
    });
  }

  /// Start periodic connectivity checks (when offline)
  void _startPeriodicCheck() {
    _stopPeriodicCheck();

    debugPrint("🔄 Starting periodic connectivity check (every 3s)");

    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkConnection();

      if (!wasOnline && _isOnline) {
        // Connection restored!
        debugPrint("✅ Connection restored!");
        _controller.add(true);
        _stopPeriodicCheck();
      }
    });
  }

  /// Stop periodic checks
  void _stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check internet connection via DNS lookup
  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Manually trigger offline state and start checking
  void notifyOffline() {
    if (_isOnline) {
      _isOnline = false;
      debugPrint("📵 Manual offline notification");
      _startPeriodicCheck();
    }
  }

  /// Stop monitoring and cleanup
  void dispose() {
    _stopPeriodicCheck();
    _controller.close();
    _isMonitoring = false;
    debugPrint("🌐 NetworkConnectivityService: Disposed");
  }
}
