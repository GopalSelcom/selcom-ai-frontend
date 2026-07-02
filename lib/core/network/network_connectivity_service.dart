import 'dart:async';

import '../utils/app_logger.dart';
import 'connectivity_probe.dart';

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
    AppLogger.d('Started monitoring', tag: 'NetworkConnectivity');

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

    AppLogger.d('Starting periodic connectivity check (every 3s)', tag: 'NetworkConnectivity');

    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final wasOnline = _isOnline;
      _isOnline = await _checkConnection();

      if (!wasOnline && _isOnline) {
        // Connection restored!
        AppLogger.i('Connection restored!', tag: 'NetworkConnectivity');
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
    // Shared probe reports unexpected errors centrally. Socket/timeout failures
    // remain expected offline conditions and are not treated as app crashes.
    return ConnectivityProbe.instance.probeInternetConnection();
  }

  /// Manually trigger offline state and start checking
  void notifyOffline() {
    if (_isOnline) {
      _isOnline = false;
      AppLogger.d('📵 Manual offline notification', tag: 'NetworkConnectivity');
      _startPeriodicCheck();
    }
  }

  /// Stop monitoring and cleanup
  void dispose() {
    _stopPeriodicCheck();
    _controller.close();
    _isMonitoring = false;
    AppLogger.d('🌐 Disposed', tag: 'NetworkConnectivity');
  }
}
