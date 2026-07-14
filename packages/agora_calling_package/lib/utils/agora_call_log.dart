import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Calling package logger — same shape as host `AppLogger`.
///
/// Enabled only in debug builds ([kDebugMode]) by default.
/// Set [forceRelease] to `true` when you need logs in a release build
/// (set it in each isolate: `main` and the FCM background handler).
class AgoraCallLogger {
  AgoraCallLogger._();

  /// Flip to `true` for release kill-state / CallKit debugging.
  static bool forceRelease = false;

  static bool get enabled => kDebugMode || forceRelease;

  /// Optional sink (e.g. Crashlytics) — register per isolate.
  static void Function(String message)? sink;

  static void d(String message, {String tag = 'AGORA_CALL'}) =>
      _log('DEBUG', tag, message);

  static void i(String message, {String tag = 'AGORA_CALL'}) =>
      _log('INFO', tag, message);

  static void w(String message, {String tag = 'AGORA_CALL'}) =>
      _log('WARNING', tag, message);

  static void e(
    String message, {
    String tag = 'AGORA_CALL',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(' | $error');
    }
    _log('ERROR', tag, buffer.toString());
    if (stackTrace != null) {
      _log('ERROR', tag, stackTrace.toString());
    }
  }

  /// Kill / background / CallKit path — filter logcat with `KILL_CALL`.
  ///
  /// Stages: `FCM_BG`, `CALLKIT`, `COLD_START`, `ACCEPT`, `VOIP`.
  static void kill(String stage, String message) =>
      d(message, tag: 'KILL_CALL/$stage');

  static void _log(String level, String tag, String message) {
    if (!enabled) return;
    final line = '[$level] $message';
    developer.log(line, name: tag);
    try {
      sink?.call('[$tag] $line');
    } catch (_) {}
  }
}
