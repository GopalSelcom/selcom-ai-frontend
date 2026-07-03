import 'dart:async';

import 'package:flutter/widgets.dart';

/// Wall-clock payment countdown that keeps elapsed time while the app is backgrounded.
///
/// Uses a [DateTime] deadline instead of decrementing tick count so remaining time
/// is recalculated on resume via [WidgetsBindingObserver].
class PaymentCountdownTimer with WidgetsBindingObserver {
  PaymentCountdownTimer({
    required this.onTick,
    required this.onExpired,
    this.onResumed,
  });

  final void Function(int remainingSeconds) onTick;
  final VoidCallback onExpired;
  final VoidCallback? onResumed;

  DateTime? _deadline;
  Timer? _timer;
  bool _expired = false;
  bool _observingLifecycle = false;

  bool get isRunning => _deadline != null && !_expired;

  void start(int durationSeconds) {
    stop();
    if (durationSeconds <= 0) {
      onTick(0);
      onExpired();
      return;
    }

    _expired = false;
    _deadline = DateTime.now().add(Duration(seconds: durationSeconds));
    _ensureLifecycleObserver();
    _syncRemaining();
    _startPeriodicTimer();
  }

  void stop() {
    _cancelPeriodicTimer();
    _deadline = null;
    _expired = false;
    _removeLifecycleObserver();
  }

  void _startPeriodicTimer() {
    _cancelPeriodicTimer();
    if (!isRunning) return;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _syncRemaining(),
    );
  }

  void _cancelPeriodicTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _syncRemaining() {
    final deadline = _deadline;
    if (deadline == null || _expired) return;

    final remaining = deadline.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _expired = true;
      onTick(0);
      stop();
      onExpired();
      return;
    }

    onTick(remaining);
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  void _removeLifecycleObserver() {
    if (!_observingLifecycle) return;
    WidgetsBinding.instance.removeObserver(this);
    _observingLifecycle = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isRunning) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Wall-clock deadline keeps counting; pause UI ticks while backgrounded.
        _cancelPeriodicTimer();
      case AppLifecycleState.resumed:
        _syncRemaining();
        if (isRunning) {
          _startPeriodicTimer();
          onResumed?.call();
        }
      case AppLifecycleState.detached:
        break;
    }
  }
}
