import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import '../models/agora_config.dart';
import '../models/call_model.dart';
import '../utils/constants.dart';

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

/// Top-level FCM background-handler the host must register BEFORE `runApp`:
///
/// ```dart
/// @pragma('vm:entry-point')
/// Future<void> myFirebaseBg(RemoteMessage m) async {
///   await Firebase.initializeApp();
///   await AgoraCallingNotificationService.firebaseBackgroundHandler(
///     m,
///     iosCallKitIconName: 'CallKitLogo',
///     callKitCallIdNamespace: 'agora-call:',
///     backgroundCallKitAppName: 'My App',
///   );
/// }
/// FirebaseMessaging.onBackgroundMessage(myFirebaseBg);
/// ```
///
/// Pass the same [iosCallKitIconName], [callKitCallIdNamespace], and
/// [backgroundCallKitAppName] you use in [AgoraCallingConfig] — the background
/// isolate cannot read GetX / [AgoraCalling.init] config.
@pragma('vm:entry-point')
Future<void> _agoraCallingBackgroundHandler(
  RemoteMessage message, {
  String iosCallKitIconName = '',
  String callKitCallIdNamespace = 'agora-call:',
  String backgroundCallKitAppName = 'Selcom Go',
}) async {
  await AgoraCallingNotificationService._showFromBackground(
    message,
    iosCallKitIconName: iosCallKitIconName,
    callKitCallIdNamespace: callKitCallIdNamespace,
    backgroundCallKitAppName: backgroundCallKitAppName,
  );
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

  /// Foreground dedup map — keyed `"$type:$rideId"` → last seen timestamp.
  /// Mirrors the static [_bgPushDedup] but for the foreground isolate so
  /// `_onForegroundMessage` can drop a duplicate FCM before it reaches the
  /// controller (the controller has its own state guards but we'd still
  /// double-show CallKit on iOS).
  final Map<String, DateTime> _fgPushDedup = <String, DateTime>{};

  /// Push events the controller layer subscribes to. Three types only:
  /// `incoming_call`, `call_joined`, `call_cancelled`.
  Stream<IncomingPushPayload> get pushStream => _pushes.stream;

  /// FCM background handler entry. Pass the same CallKit-related values as
  /// in [AgoraCallingConfig] (see library doc above).
  static Future<void> firebaseBackgroundHandler(
    RemoteMessage message, {
    String iosCallKitIconName = '',
    String callKitCallIdNamespace = 'agora-call:',
    String backgroundCallKitAppName = 'Selcom Go',
  }) =>
      _agoraCallingBackgroundHandler(
        message,
        iosCallKitIconName: iosCallKitIconName,
        callKitCallIdNamespace: callKitCallIdNamespace,
        backgroundCallKitAppName: backgroundCallKitAppName,
      );

  /// Stable UUID for `flutter_callkit_incoming` CallKit `id` (iOS requires UUID).
  /// [namespace] must match [AgoraCallingConfig.callKitCallIdNamespace].
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
    // Only the status channel — the incoming ringing UI is fully owned by
    // flutter_callkit_incoming, which manages its own CallStyle channel.
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

  /// Supports both major signatures of `flutter_local_notifications`:
  /// - v18: initialize(InitializationSettings, {callbacks...})
  /// - v21+: initialize({required InitializationSettings settings, ...})
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
    if (kDebugMode) {
      // Always log — even if we don't handle this push — so the host can
      // confirm with `adb logcat` whether the FCM message is actually being
      // delivered to the device. If you don't see this line for an expected
      // call push, the issue is upstream of the package (FCM token not
      // registered, backend not pushing, push has `notification` block when
      // it should be data-only, etc.).
      debugPrint('[AGORA_NOTIF] fg push type="$type" '
          'has_notification=${message.notification != null} '
          'data=${message.data}');
    }
    if (type.isEmpty) return;
    if (_isDuplicatePush(type, message.data, _fgPushDedup)) {
      if (kDebugMode) {
        debugPrint('[AGORA_NOTIF] fg push dropped — duplicate within '
            '${_pushDedupWindow.inSeconds}s');
      }
      return;
    }
    switch (type) {
      case PushTypes.incomingCall:
        _pushes.add(
          IncomingPushPayload(type, Map<String, dynamic>.from(message.data)),
        );
        // Avoid duplicate Accept/Decline surfaces: on **Android** in the
        // foreground, the controller opens [IncomingCallScreen] only — the
        // system CallStyle notification is **not** shown here (it would stack
        // with the full-screen incoming UI and confuse users). On **iOS**,
        // CallKit is the primary incoming surface, so we still show it while
        // the controller skips the duplicate in-app sheet (see CallController).
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
        if (kDebugMode) {
          debugPrint('[AGORA_NOTIF] ignoring fg push with unhandled type '
              '"$type" — not a calling event');
        }
        return;
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().toLowerCase();
    if (kDebugMode) {
      debugPrint('[AGORA_NOTIF] opened from notification type=$type');
    }
    if (type.isEmpty) return;
    _pushes.add(
      IncomingPushPayload(type, Map<String, dynamic>.from(message.data)),
    );
  }

  /// Shows the incoming-call UI — same path on both platforms now:
  /// CallKit on iOS, CallStyle notification + full-screen activity on Android,
  /// both via `flutter_callkit_incoming` so Accept/Decline buttons dispatch
  /// the same `CallEvent` regardless of platform or app state.
  Future<void> _showIncomingUi(Map<String, dynamic> data) =>
      _showCallkitIncoming(data);

  Future<void> _showCallkitIncoming(Map<String, dynamic> data) async {
    final rideId = (data['ride_id'] ?? data['rideId'])?.toString() ?? 'unknown';
    final peerLabel = _resolvePeerLabel(data);
    if (kDebugMode) {
      debugPrint('[AGORA_NOTIF] showCallkitIncoming '
          'rideId=$rideId peer=$peerLabel');
    }
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(
        CallKitParams(
          id: callkitUuidForRide(rideId, _config.callKitCallIdNamespace),
          nameCaller: peerLabel,
          appName: _config.appName,
          type: 0, // audio
          duration: 30000,
          textAccept: 'Accept',
          textDecline: 'Decline',
          extra: Map<String, dynamic>.from(data),
          android: const AndroidParams(
            isCustomNotification: true,
            isShowLogo: false,
            isShowCallID: false,
            ringtonePath: 'system_ringtone_default',
            backgroundColor: '#0955fa',
            actionColor: '#4CAF50',
            textColor: '#ffffff',
            incomingCallNotificationChannelName: 'Incoming Calls',
            missedCallNotificationChannelName: 'Missed Calls',
            isShowFullLockedScreen: true,
            isImportant: true,
          ),
          ios: _iosCallKitParams(),
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AGORA_NOTIF] showCallkitIncoming failed: $e\n$st');
      }
    }
  }

  Future<void> _dismissIncomingUi(Map<String, dynamic> data) async {
    final rideId = (data['ride_id'] ?? data['rideId'])?.toString();
    if (kDebugMode) {
      debugPrint('[AGORA_NOTIF] dismiss incoming UI rideId=$rideId');
    }
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      if (kDebugMode) debugPrint('[AGORA_NOTIF] endAllCalls failed: $e');
    }
  }

  /// Injects an externally-received `incoming_call` payload into the push
  /// stream (e.g. from the host app's iOS PushKit bridge). Bypasses FCM.
  void injectExternalIncomingCall(Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('[AGORA_NOTIF] injectExternalIncomingCall data=$data');
    }
    final patched = <String, dynamic>{
      ...data,
      'type': PushTypes.incomingCall,
    };
    _pushes.add(IncomingPushPayload(PushTypes.incomingCall, patched));
  }

  /// Public helper for the controller to dismiss any active CallKit / CallStyle
  /// UI. Today the controller calls `FlutterCallkitIncoming.endAllCalls()`
  /// directly from `_terminate`; this method is kept for host apps that need to
  /// force-dismiss any phantom call UIs (e.g. on logout).
  ///
  /// **Do not call this from the accept path** — `endAllCalls()` round-trips
  /// an `actionCallEnded` event back through `FlutterCallkitIncoming.onEvent`
  /// and will tear down a freshly-accepted call. See the controller's
  /// `_acceptIncoming` for the correct `setCallConnected` transition.
  Future<void> dismissCallUi() async {
    if (kDebugMode) {
      debugPrint('[AGORA_NOTIF] dismissCallUi');
    }
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  String _resolvePeerLabel(Map<String, dynamic> data) {
    final resolver = _config.peerNameResolver;
    if (resolver != null) {
      try {
        return resolver(data);
      } catch (_) {
        // fall through
      }
    }
    return _defaultPeerLabel(_config.localRole, data);
  }

  /// Static dedup map for the **background** isolate. Survives across two
  /// FCM deliveries within the same wake-up cycle (the typical "notification
  /// + data" backend split).
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

  /// Background-only entry. Builds its own CallKit invocation because there's
  /// no guarantee the singleton was initialized in this isolate.
  static Future<void> _showFromBackground(
    RemoteMessage message, {
    required String iosCallKitIconName,
    required String callKitCallIdNamespace,
    required String backgroundCallKitAppName,
  }) async {
    final type = (message.data['type'] ?? '').toString().toLowerCase();
    if (kDebugMode) {
      debugPrint('[AGORA_NOTIF] bg push type="$type" '
          'has_notification=${message.notification != null} '
          'data=${message.data}');
    }
    if (type != PushTypes.incomingCall && type != PushTypes.callCancelled) {
      if (kDebugMode) {
        debugPrint('[AGORA_NOTIF] bg push ignored — not a calling event');
      }
      return;
    }

    final rideId =
        (message.data['ride_id'] ?? message.data['rideId'])?.toString() ??
            'unknown';

    if (_isDuplicatePush(type, message.data, _bgPushDedup)) {
      if (kDebugMode) {
        debugPrint('[AGORA_NOTIF] bg push dropped — duplicate within '
            '${_pushDedupWindow.inSeconds}s rideId=$rideId');
      }
      return;
    }

    if (type == PushTypes.callCancelled) {
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (_) {}
      return;
    }

    // type == incoming_call — same path on both platforms (CallKit on iOS,
    // CallStyle on Android). The native side wakes the app on Accept and
    // dispatches Event.actionCallAccept once the Dart isolate is alive.
    final peerLabel = _defaultPeerLabel(
      _peerRoleFromDataOrFallback(message.data),
      message.data,
    );
    try {
      await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
        id: callkitUuidForRide(rideId, callKitCallIdNamespace),
        nameCaller: peerLabel,
        appName: backgroundCallKitAppName,
        type: 0,
        duration: 30000,
        textAccept: 'Accept',
        textDecline: 'Decline',
        extra: Map<String, dynamic>.from(message.data),
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          isShowCallID: false,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          textColor: '#ffffff',
          incomingCallNotificationChannelName: 'Incoming Calls',
          missedCallNotificationChannelName: 'Missed Calls',
          isShowFullLockedScreen: true,
          isImportant: true,
        ),
        ios: _iosCallKitParamsForBackground(iosCallKitIconName),
      ));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_NOTIF] bg showCallkitIncoming failed: $e');
      }
    }
  }

  /// Default peer-name labeler. Rider sees "Your Driver"; driver sees
  /// "Your Rider". `caller_name` from the push — if present — is preferred.
  static String _defaultPeerLabel(
    CallParticipantRole localRole,
    Map<String, dynamic> data,
  ) {
    final fromPush =
        (data['caller_name'] ?? data['callerName'])?.toString().trim();
    if (fromPush != null && fromPush.isNotEmpty) return fromPush;
    return localRole == CallParticipantRole.rider
        ? 'Your Driver'
        : 'Your Rider';
  }

  /// Returns `true` when `(type, ride_id)` was last seen within
  /// [_pushDedupWindow]. Mutates [bucket] to record the new sighting and
  /// garbage-collects stale entries so the map can't grow unbounded.
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

  /// Background isolate has no [AgoraCallingConfig] — fall back to inferring
  /// the local role from the push's `caller_role`. (rider local ↔ driver
  /// caller, and vice versa.)
  static CallParticipantRole _peerRoleFromDataOrFallback(
    Map<String, dynamic> data,
  ) {
    final raw =
        (data['caller_role'] ?? data['callerRole'])?.toString().toLowerCase();
    if (raw == 'rider') return CallParticipantRole.driver;
    if (raw == 'driver') return CallParticipantRole.rider;
    return CallParticipantRole.rider;
  }

}

/// Helper typedef so the controller can reuse [CallModel.fromIncomingPush]
/// with a peer-label string built from config.
typedef PeerLabelBuilder = String Function(Map<String, dynamic> push);
