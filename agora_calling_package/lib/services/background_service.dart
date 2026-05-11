import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

/// Android-only foreground service that keeps the OS from killing the audio
/// session while the app is backgrounded during an active call.
///
/// iOS does not need this — `UIBackgroundModes = [audio, voip]` covers it
/// natively (the Agora engine + ongoing audio session keep the app alive).
class CallBackgroundService {
  CallBackgroundService._();

  static final CallBackgroundService instance = CallBackgroundService._();

  bool _configured = false;
  bool _running = false;

  /// One-time setup. Must be called from the main isolate (typically inside
  /// `AgoraCalling.init`). Safe to call repeatedly.
  Future<void> configure() async {
    if (_configured || !Platform.isAndroid) {
      _configured = true;
      return;
    }
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'agora_call_foreground',
        initialNotificationTitle: 'Call in progress',
        initialNotificationContent: 'Tap to return to the call',
        foregroundServiceNotificationId: 800123,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onServiceStartIos,
        onBackground: _onServiceBackgroundIos,
      ),
    );
    _configured = true;
  }

  Future<void> startForCall({
    required String peerName,
  }) async {
    if (!Platform.isAndroid) return;
    if (!_configured) await configure();
    if (_running) return;
    final service = FlutterBackgroundService();
    final ok = await service.startService();
    _running = ok;
    if (ok) {
      service.invoke('updateCallNotification', {
        'title': 'Call in progress',
        'body': 'Connected with $peerName',
      });
    } else if (kDebugMode) {
      debugPrint('[AGORA_BG] failed to start foreground service');
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid || !_running) {
      _running = false;
      return;
    }
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    _running = false;
  }
}

@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  service.on('updateCallNotification').listen((event) async {
    if (event == null) return;
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: (event['title'] ?? 'Call in progress').toString(),
        content:
            (event['body'] ?? 'Tap to return to the call').toString(),
      );
    }
  });
  service.on('stopService').listen((_) async {
    await service.stopSelf();
  });
}

@pragma('vm:entry-point')
bool _onServiceStartIos(ServiceInstance service) {
  // iOS does not need an active foreground service for VoIP calls.
  return true;
}

@pragma('vm:entry-point')
Future<bool> _onServiceBackgroundIos(ServiceInstance service) async {
  return true;
}
