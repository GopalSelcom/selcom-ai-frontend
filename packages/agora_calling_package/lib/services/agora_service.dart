import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

/// Bundle of events published by [AgoraService] to the controller layer.
class AgoraEvents {
  AgoraEvents({
    required this.onJoined,
    required this.onRemoteJoined,
    required this.onRemoteOffline,
    required this.onTokenWillExpire,
    required this.onConnectionLost,
    required this.onError,
  });

  final void Function() onJoined;
  final void Function(int remoteUid) onRemoteJoined;
  final void Function(int remoteUid) onRemoteOffline;
  final void Function() onTokenWillExpire;
  final void Function() onConnectionLost;
  final void Function(String message) onError;
}

/// Thin wrapper around [RtcEngine] for audio-only Agora calls.
///
/// Engine lifecycle invariant: the internal `_engine` reference is set BEFORE
/// `registerEventHandler` so handlers fire reliably (matches the prior
/// SDK-init race fix).
class AgoraService {
  AgoraService({required this.appId});

  final String appId;
  RtcEngine? _engine;

  /// Channel id from the last successful [onJoinChannelSuccess]. Used to make
  /// duplicate `joinChannel` calls idempotent (Agora returns -17 when already
  /// joined with the same uid).
  String? _activeChannelId;

  /// Serialises concurrent `joinChannel` calls for the same channel.
  Future<void>? _joinFuture;
  String? _joinFutureChannel;

  /// In-flight init future — cached so concurrent `ensureInitialized` callers
  /// share one engine instead of each constructing their own. Without this,
  /// two parallel accepts (e.g. CallKit replay + foreground push) both pass
  /// the `_engine != null` check during the long async init and we end up
  /// with two `RtcEngine` instances racing to `joinChannel` on the same uid
  /// (the loser hits `ERR_JOIN_CHANNEL_REJECTED` -17 and tears the session
  /// down on its way out).
  Future<void>? _initFuture;

  bool get isInitialized => _engine != null;

  Future<void> ensureInitialized(AgoraEvents events) async {
    if (_engine != null) return;
    final pending = _initFuture ??= _runInit(events);
    try {
      await pending;
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> _runInit(AgoraEvents events) async {
    if (_engine != null) return;
    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    // Voice settings per brain doc § 9 — chatroom scenario activates Agora's
    // built-in AEC + ANS, optimised for 1:1 voice calls.
    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableAudio();
    await engine.disableVideo();
    _engine = engine;

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _activeChannelId = connection.channelId;
          if (kDebugMode) {
            debugPrint('[AGORA] joined channel=${connection.channelId}');
          }
          events.onJoined();
        },
        onUserJoined: (RtcConnection conn, int remoteUid, int elapsed) {
          if (kDebugMode) debugPrint('[AGORA] remote joined uid=$remoteUid');
          events.onRemoteJoined(remoteUid);
        },
        onUserOffline: (RtcConnection conn, int remoteUid, _) {
          if (kDebugMode) debugPrint('[AGORA] remote offline uid=$remoteUid');
          events.onRemoteOffline(remoteUid);
        },
        onTokenPrivilegeWillExpire: (_, __) => events.onTokenWillExpire(),
        onConnectionStateChanged: (_, state, __) {
          if (state == ConnectionStateType.connectionStateDisconnected) {
            events.onConnectionLost();
          }
        },
        onError: (ErrorCodeType code, String message) {
          if (kDebugMode) {
            debugPrint('[AGORA] error code=$code msg=$message');
          }
          events.onError(message.isEmpty ? code.name : message);
        },
      ),
    );
  }

  Future<void> joinChannel({
    required String channelName,
    required String token,
    int uid = 0,
  }) async {
    if (_activeChannelId == channelName) {
      if (kDebugMode) {
        debugPrint('[AGORA] joinChannel skip — already active on $channelName');
      }
      return;
    }
    if (_joinFuture != null && _joinFutureChannel == channelName) {
      if (kDebugMode) {
        debugPrint('[AGORA] joinChannel await in-flight join for $channelName');
      }
      await _joinFuture;
      return;
    }

    final pending = _runJoin(
      channelName: channelName,
      token: token,
      uid: uid,
    );
    _joinFuture = pending;
    _joinFutureChannel = channelName;
    try {
      await pending;
    } finally {
      if (identical(_joinFuture, pending)) {
        _joinFuture = null;
        _joinFutureChannel = null;
      }
    }
  }

  Future<void> _runJoin({
    required String channelName,
    required String token,
    required int uid,
  }) async {
    final engine = _requireEngine();
    try {
      await engine.joinChannel(
        token: token,
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } on AgoraRtcException catch (e) {
      // ERR_JOIN_CHANNEL_REJECTED — duplicate join (CallKit Accept replayed
      // twice, or placeCall + accept racing). Treat as success so the failure
      // path does not `leaveChannel` and drop live audio.
      if (e.code == -17) {
        if (kDebugMode) {
          debugPrint(
            '[AGORA] joinChannel -17 ignored for $channelName '
            '(duplicate join — already in channel)',
          );
        }
        _activeChannelId = channelName;
        return;
      }
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    final engine = _engine;
    if (engine == null) return;
    _activeChannelId = null;
    try {
      await engine.leaveChannel();
    } catch (_) {
      // Best-effort.
    }
  }

  Future<void> setMuted(bool muted) async {
    await _requireEngine().muteLocalAudioStream(muted);
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    await _requireEngine().setEnableSpeakerphone(enabled);
  }

  Future<void> renewToken(String token) async {
    if (token.isEmpty) return;
    await _requireEngine().renewToken(token);
  }

  Future<void> dispose() async {
    final engine = _engine;
    _engine = null;
    _initFuture = null;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (_) {}
    try {
      await engine.release();
    } catch (_) {}
  }

  RtcEngine _requireEngine() {
    final engine = _engine;
    if (engine == null) {
      throw StateError('AgoraService used before ensureInitialized()');
    }
    return engine;
  }
}
