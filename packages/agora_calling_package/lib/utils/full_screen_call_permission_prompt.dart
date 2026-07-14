import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import 'agora_call_log.dart';

/// Android 14+ full-screen incoming-call intent check only.
/// Permission UI is provided by the host app ([AgoraCallingConfig.ensureCallPermissionsUi]).
class FullScreenCallPermissionPrompt {
  FullScreenCallPermissionPrompt._();

  static const _channel = MethodChannel('agora_calling/full_screen_intent');

  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final nativeGranted =
          await _channel.invokeMethod<bool>('canUseFullScreenIntent');
      if (nativeGranted != null) return nativeGranted;
    } catch (e) {
      AgoraCallLogger.kill(
        'COLD_START',
        'native canUseFullScreenIntent check failed: $e',
      );
    }
    try {
      return await FlutterCallkitIncoming.canUseFullScreenIntent();
    } catch (e) {
      AgoraCallLogger.kill(
        'COLD_START',
        'canUseFullScreenIntent check failed: $e',
      );
      return false;
    }
  }

  /// Opens the Android 14+ "Full screen notifications" permission screen.
  static Future<void> openSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openSettings');
      return;
    } catch (e) {
      AgoraCallLogger.kill(
        'COLD_START',
        'native full-screen settings failed, using plugin fallback: $e',
      );
    }
    try {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    } catch (e) {
      AgoraCallLogger.kill(
        'COLD_START',
        'requestFullIntentPermission failed: $e',
      );
    }
  }
}
