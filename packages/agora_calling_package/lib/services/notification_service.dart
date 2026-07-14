import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/agora_config.dart';
import '../utils/agora_call_log.dart';
import '../utils/constants.dart';
import '../utils/push_peer_label.dart';

/// Shared CallStyle params for incoming calls (foreground iOS + FCM background).
///
/// Android incoming-call surfaces by app state:
/// - **Foreground:** in-app [IncomingCallScreen] only (no duplicate CallStyle).
/// - **Background / killed:** [FlutterCallkitIncoming.showCallkitIncoming] →
///   CallStyle notification with Accept/Decline (same path for both states).
///
/// [isShowFullLockedScreen]: asks the plugin to use full-screen intent on the
/// lock screen. Requires [USE_FULL_SCREEN_INTENT] in manifest; on Android 14+
/// the user must also enable "Full screen notifications" in app Settings.
/// When disabled by the user, notification + buttons still work on an unlocked phone.
const AndroidParams _incomingAndroidParams = AndroidParams(
  isCustomNotification: true,
  isShowLogo: false,
  isShowCallID: false,
  ringtonePath: 'system_ringtone_default',
  backgroundColor: '#0955fa',
  actionColor: '#4CAF50',
  textColor: '#ffffff',
  textAccept: 'Accept',
  textDecline: 'Decline',
  incomingCallNotificationChannelName: 'Incoming Calls',
  missedCallNotificationChannelName: 'Missed Calls',
  isShowFullLockedScreen: true,
  isImportant: true,
);

/// After `showCallkitIncoming` the FCM background isolate must stay alive long
/// enough for the native broadcast receiver to post the CallStyle notification.
/// If the headless FlutterEngine detaches first, `CallkitNotificationManager`
/// is torn down and the incoming UI is silently dropped (killed-state bug).
const Duration _bgCallkitEngineKeepAlive = Duration(milliseconds: 2500);

/// Channel id for non-ringing call status updates (e.g. call_joined toasts).
/// Incoming-call ringing UI is owned by `flutter_callkit_incoming` on both
/// platforms — no `flutter_local_notifications` channel is needed for that.
const String _statusChannelId = 'go_call_status';

/// Window during which we suppress repeated `(type, rideId)` pushes before
/// re-showing the CallKit/CallStyle UI. Backends sometimes send the same FCM
/// twice (e.g. once with a `notification` block, once with `data`-only) and
/// Android delivers them as two separate messages — invoking
/// `showCallkitIncoming` twice for the same ride confuses the plugin (two
/// CallStyle entries) and downstream the controller sees two
/// `actionCallAccept` events that race a duplicate `joinChannel`.
const Duration _pushDedupWindow = Duration(seconds: 10);

@pragma('vm:entry-point')
Future<void> _agoraCallingBackgroundHandler(
  RemoteMessage message, {
  String iosCallKitIconName = '',
  String callKitCallIdNamespace = 'agora-call:',
  String backgroundCallKitAppName = 'Selcom Go',
  CallParticipantRole localRole = CallParticipantRole.rider,
}) async {
  AgoraCallLogger.kill(
    'CALLKIT',
    'agora background handler entered messageId=${message.messageId}',
  );
  await AgoraCallingNotificationService._showFromBackground(
    message,
    iosCallKitIconName: iosCallKitIconName,
    callKitCallIdNamespace: callKitCallIdNamespace,
    backgroundCallKitAppName: backgroundCallKitAppName,
    localRole: localRole,
  );
  AgoraCallLogger.kill('CALLKIT', 'agora background handler exited');
}

/// Push payload shape emitted to the controller.
class IncomingPushPayload {
  IncomingPushPayload(this.type, this.raw);
  final String type;
  final Map<String, dynamic> raw;
}

/// Owns FCM listeners + the local notification surfaces used for incoming
/// calls. Pure infra — does NOT know about the call state machine.
class AgoraCallingNotificationService {
  AgoraCallingNotificationService(this._config);

  final AgoraCallingConfig _config;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static const Uuid _uuid = Uuid();

  final StreamController<IncomingPushPayload> _pushes =
      StreamController<IncomingPushPayload>.broadcast();

  final Map<String, DateTime> _fgPushDedup = <String, DateTime>{};

  Stream<IncomingPushPayload> get pushStream => _pushes.stream;

  static Future<void> firebaseBackgroundHandler(
    RemoteMessage message, {
    String iosCallKitIconName = '',
    String callKitCallIdNamespace = 'agora-call:',
    String backgroundCallKitAppName = 'Selcom Go',
    CallParticipantRole localRole = CallParticipantRole.rider,
  }) =>
      _agoraCallingBackgroundHandler(
        message,
        iosCallKitIconName: iosCallKitIconName,
        callKitCallIdNamespace: callKitCallIdNamespace,
        backgroundCallKitAppName: backgroundCallKitAppName,
        localRole: localRole,
      );

  static String callkitUuidForRide(String rideId, String namespace) {
    final trimmed = rideId.trim();
    if (trimmed.isEmpty) return _uuid.v4();
    return _uuid.v5(Uuid.NAMESPACE_URL, '${namespace.trim()}$trimmed');
  }

  Future<void> initialize() async {
    final initSettings = InitializationSettings(
      android: AndroidInitializationSettings(_config.androidNotificationIcon),
      iOS: const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _initializeLocalNotifications(initSettings);

    if (Platform.isAndroid) {
      await _createAndroidChannels();
    }
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onMessageOpened(initial);
  }

  Future<void> _createAndroidChannels() async {
    const statusChannel = AndroidNotificationChannel(
      _statusChannelId,
      'Call Status',
      description: 'Call connected / cancelled updates',
      importance: Importance.defaultImportance,
    );
    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(statusChannel);
  }

  Future<void> _initializeLocalNotifications(
    InitializationSettings initSettings,
  ) async {
    final dynamic plugin = _local;
    try {
      await Function.apply(plugin.initialize as Function, <Object?>[
        initSettings,
      ]);
      return;
    } on NoSuchMethodError {
      await Function.apply(
        plugin.initialize as Function,
        const <Object?>[],
        <Symbol, Object?>{
          #settings: initSettings,
        },
      );
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().toLowerCase();
    AgoraCallLogger.d('[AGORA_NOTIF] fg push type="$type" '
        'has_notification=${message.notification != null} '
        'data=${message.data}');
    if (type.isEmpty) return;
    if (_isDuplicatePush(type, message.data, _fgPushDedup)) {
      AgoraCallLogger.d('[AGORA_NOTIF] fg push dropped — duplicate within '
          '${_pushDedupWindow.inSeconds}s');
      return;
    }
    switch (type) {
      case PushTypes.incomingCall:
        _pushes.add(
          IncomingPushPayload(type, Map<String, dynamic>.from(message.data)),
        );
        if (Platform.isIOS) {
          _showIncomingUi(message.data);
        }
        return;
      case PushTypes.callJoined:
        _pushes.add(
          IncomingPushPayload(type, Map<String, dynamic>.from(message.data)),
        );
        return;
      case PushTypes.callCancelled:
        _pushes.add(
          IncomingPushPayload(type, Map<String, dynamic>.from(message.data)),
        );
        _dismissIncomingUi(message.data);
        return;
      default:
        AgoraCallLogger.d('[AGORA_NOTIF] ignoring fg push with unhandled type '
            '"$type" — not a calling event');
        return;
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().toLowerCase();
    AgoraCallLogger.d('[AGORA_NOTIF] opened from notification type=$type');
    if (type.isEmpty) return;
    _pushes.add(
      IncomingPushPayload(type, Map<String, dynamic>.from(message.data)),
    );
  }

  Future<void> _showIncomingUi(Map<String, dynamic> data) =>
      _showCallkitIncoming(data);

  Future<void> _showCallkitIncoming(Map<String, dynamic> data) async {
    final rideId = (data['ride_id'] ?? data['rideId'])?.toString() ?? 'unknown';
    final peerLabel = _resolvePeerLabel(data);
    AgoraCallLogger.d('[AGORA_NOTIF] showCallkitIncoming '
        'rideId=$rideId peer=$peerLabel');
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(
        CallKitParams(
          id: callkitUuidForRide(rideId, _config.callKitCallIdNamespace),
          nameCaller: peerLabel,
          appName: _config.appName,
          type: 0,
          duration: 30000,
          extra: Map<String, dynamic>.from(data),
          android: _incomingAndroidParams,
          ios: _iosCallKitParams(),
        ),
      );
    } catch (e, st) {
      AgoraCallLogger.d('[AGORA_NOTIF] showCallkitIncoming failed: $e\n$st');
    }
  }

  Future<void> _dismissIncomingUi(Map<String, dynamic> data) async {
    final rideId = (data['ride_id'] ?? data['rideId'])?.toString();
    AgoraCallLogger.d('[AGORA_NOTIF] dismiss incoming UI rideId=$rideId');
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      AgoraCallLogger.d('[AGORA_NOTIF] endAllCalls failed: $e');
    }
  }

  void injectExternalIncomingCall(Map<String, dynamic> data) {
    AgoraCallLogger.d('[AGORA_NOTIF] injectExternalIncomingCall data=$data');
    final patched = <String, dynamic>{
      ...data,
      'type': PushTypes.incomingCall,
    };
    _pushes.add(IncomingPushPayload(PushTypes.incomingCall, patched));
  }

  Future<void> dismissCallUi() async {
    AgoraCallLogger.d('[AGORA_NOTIF] dismissCallUi');
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  String _resolvePeerLabel(Map<String, dynamic> data) {
    final resolver = _config.peerNameResolver;
    if (resolver != null) {
      try {
        final resolved = resolver(data).trim();
        if (resolved.isNotEmpty) return resolved;
      } catch (_) {}
    }
    return peerLabelFromPush(
      data,
      localRole: _config.localRole,
      appName: _config.appName,
    );
  }

  static final Map<String, DateTime> _bgPushDedup = <String, DateTime>{};

  IOSParams _iosCallKitParams() {
    final icon = _config.iosCallKitIconName.trim();
    return IOSParams(
      iconName: icon.isEmpty ? null : icon,
      handleType: 'generic',
      supportsHolding: false,
      supportsVideo: false,
    );
  }

  static IOSParams _iosCallKitParamsForBackground(String iconName) {
    final icon = iconName.trim();
    return IOSParams(
      iconName: icon.isEmpty ? null : icon,
      handleType: 'generic',
      supportsHolding: false,
      supportsVideo: false,
    );
  }

  static Future<void> _showFromBackground(
    RemoteMessage message, {
    required String iosCallKitIconName,
    required String callKitCallIdNamespace,
    required String backgroundCallKitAppName,
    CallParticipantRole localRole = CallParticipantRole.rider,
  }) async {
    final type = (message.data['type'] ?? '').toString().toLowerCase();
    AgoraCallLogger.kill(
      'CALLKIT',
      '_showFromBackground type="$type" '
      'has_notification=${message.notification != null} '
      'data=${message.data}',
    );
    if (type != PushTypes.incomingCall && type != PushTypes.callCancelled) {
      AgoraCallLogger.kill('CALLKIT', 'bg push ignored — not a calling event');
      return;
    }

    final rideId =
        (message.data['ride_id'] ?? message.data['rideId'])?.toString() ??
            'unknown';

    if (_isDuplicatePush(type, message.data, _bgPushDedup)) {
      AgoraCallLogger.kill(
        'CALLKIT',
        'bg push dropped — duplicate within '
        '${_pushDedupWindow.inSeconds}s rideId=$rideId',
      );
      return;
    }

    if (type == PushTypes.callCancelled) {
      AgoraCallLogger.kill('CALLKIT', 'call_cancelled rideId=$rideId');
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (e) {
        AgoraCallLogger.kill('CALLKIT', 'endAllCalls failed for cancel: $e');
      }
      return;
    }

    final peerLabel = peerLabelFromPush(
      message.data,
      localRole: localRole,
      appName: backgroundCallKitAppName,
    );
    AgoraCallLogger.kill(
      'CALLKIT',
      'showCallkitIncoming START rideId=$rideId peer=$peerLabel',
    );
    if (Platform.isAndroid) {
      await _logAndroidCallPermissionState();
    }
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
        id: callkitUuidForRide(rideId, callKitCallIdNamespace),
        nameCaller: peerLabel,
        appName: backgroundCallKitAppName,
        type: 0,
        duration: 30000,
        extra: Map<String, dynamic>.from(message.data),
        android: _incomingAndroidParams,
        ios: _iosCallKitParamsForBackground(iosCallKitIconName),
      ));
      AgoraCallLogger.kill(
        'CALLKIT',
        'showCallkitIncoming OK rideId=$rideId — holding bg isolate '
        '${_bgCallkitEngineKeepAlive.inMilliseconds}ms for native UI',
      );
      if (Platform.isAndroid) {
        await Future<void>.delayed(_bgCallkitEngineKeepAlive);
        AgoraCallLogger.kill('CALLKIT', 'bg isolate keep-alive done rideId=$rideId');
      }
    } catch (e, st) {
      AgoraCallLogger.kill('CALLKIT', 'showCallkitIncoming FAILED rideId=$rideId err=$e');
      AgoraCallLogger.kill('CALLKIT', 'stack=$st');
    }
  }

  static Future<void> _logAndroidCallPermissionState() async {
    try {
      final notif = await Permission.notification.status;
      AgoraCallLogger.kill('CALLKIT', 'POST_NOTIFICATIONS status=$notif');
      if (!notif.isGranted) {
        AgoraCallLogger.kill(
          'CALLKIT',
          'WARNING: notification permission not granted — CallStyle may not show',
        );
      }
      final canFullScreen = await FlutterCallkitIncoming.canUseFullScreenIntent();
      AgoraCallLogger.kill('CALLKIT', 'canUseFullScreenIntent=$canFullScreen');
      if (canFullScreen == false) {
        AgoraCallLogger.kill(
          'CALLKIT',
          'WARNING: full-screen intent disabled — lock-screen incoming UI may be hidden',
        );
      }
    } catch (e) {
      AgoraCallLogger.kill('CALLKIT', 'permission probe failed: $e');
    }
  }

  static bool _isDuplicatePush(
    String type,
    Map<String, dynamic> data,
    Map<String, DateTime> bucket,
  ) {
    final rideId = (data['ride_id'] ?? data['rideId'])?.toString() ?? '';
    if (rideId.isEmpty) return false;
    final now = DateTime.now();
    bucket.removeWhere((_, ts) => now.difference(ts) > _pushDedupWindow);
    final key = '$type:$rideId';
    final last = bucket[key];
    bucket[key] = now;
    if (last == null) return false;
    return now.difference(last) <= _pushDedupWindow;
  }
}

typedef PeerLabelBuilder = String Function(Map<String, dynamic> push);
