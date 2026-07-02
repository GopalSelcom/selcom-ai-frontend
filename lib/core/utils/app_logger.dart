import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Central app logger — use instead of [print], [debugPrint], or [developer.log].
///
/// Enabled only in debug builds ([kDebugMode]).
class AppLogger {
  AppLogger._();

  static bool get enabled => kDebugMode;
  static void d(String message, {String tag = 'APP'}) =>
      _log('DEBUG', tag, message);

  static void i(String message, {String tag = 'APP'}) =>
      _log('INFO', tag, message);

  static void w(String message, {String tag = 'APP'}) =>
      _log('WARNING', tag, message);

  static void e(
    String message, {
    String tag = 'APP',
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

  static void _log(String level, String tag, String message) {
    if (!enabled) return;
    developer.log('[$level] $message', name: tag);
  }
}
