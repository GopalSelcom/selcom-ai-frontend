import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../domain/agora_rtc_join_credentials.dart';
import '../domain/agora_voice_token_provider.dart';

class AgoraVoiceEngineService {
  AgoraVoiceEngineService({required this.tokenProvider});

  final AgoraVoiceTokenProvider tokenProvider;

  RtcEngine? _engine;
  String? _initializedAppId;
  bool _joined = false;

  /// Initializes RTC engine for the supplied App ID.
  /// Recreates engine automatically if App ID changes at runtime.
  Future<void> ensureInitialized({
    required String appId,
    required void Function(RtcEngineEventHandler handler) registerEvents,
  }) async {
    if (_engine != null && _initializedAppId == appId) {
      return;
    }

    if (_engine != null) {
      await dispose();
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        audioScenario: AudioScenarioType.audioScenarioChatroom,
      ),
    );

    await engine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    await engine.enableAudio();
    await engine.disableVideo();

    _engine = engine;
    _initializedAppId = appId;
    registerEvents(const RtcEngineEventHandler());
  }

  /// Sets/overrides event handlers from the call controller layer.
  Future<void> setEventHandler(RtcEngineEventHandler handler) async {
    final engine = _engine;
    if (engine == null) return;
    engine.registerEventHandler(handler);
  }

  /// Joins the channel using backend-provided credentials.
  /// Debug log here is the best place to verify app/channel/token/uid alignment.
  Future<void> join(AgoraRtcJoinCredentials creds) async {
    final engine = _engine;
    if (engine == null) {
      throw StateError('Agora engine not initialized');
    }
    if (!creds.isValidForJoin) {
      throw StateError('Invalid join credentials');
    }

    if (kDebugMode) {
      debugPrint(
        '[AGORA_VERIFY] appId=${creds.appId} channel=${creds.channel} '
        'uid=${creds.uid} token=${_maskToken(creds.token)} '
        'provider=${tokenProvider.runtimeType}',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[AGORA_SDK] Joining channel=${creds.channel} with uid=${creds.uid}...',
      );
    }
    await engine.joinChannel(
      token: creds.token,
      channelId: creds.channel,
      uid: creds.uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );
    if (kDebugMode) debugPrint('[AGORA_SDK] joinChannel call completed.');
    _joined = true;
  }

  /// Renews token without leaving channel (used by expiry callback).
  Future<void> renewRtcToken(String token) async {
    final engine = _engine;
    if (engine == null) return;
    await engine.renewToken(token);
  }

  /// Local mute only; does not leave channel.
  Future<void> setMuted(bool muted) async {
    final engine = _engine;
    if (engine == null) return;
    await engine.muteLocalAudioStream(muted);
  }

  /// Changes audio route to speaker/earpiece.
  /// Errors are intentionally swallowed to avoid breaking active call flow.
  Future<void> setSpeakerEnabled(bool enabled) async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.setEnableSpeakerphone(enabled);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AGORA_VERIFY] setSpeakerEnabled skipped: $e');
      }
    }
  }

  /// Leaves current channel if currently joined.
  Future<void> leave() async {
    final engine = _engine;
    if (engine == null || !_joined) return;
    await engine.leaveChannel();
    _joined = false;
  }

  /// Full engine cleanup; call when call screen/controller is destroyed.
  Future<void> dispose() async {
    await leave();
    final engine = _engine;
    if (engine != null) {
      await engine.release();
    }
    _engine = null;
    _initializedAppId = null;
  }

  /// Masks token for logs to avoid leaking secrets.
  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return '<null-or-empty>';
    if (token.length <= 10) return '${token.substring(0, 2)}***';
    final start = token.substring(0, 6);
    final end = token.substring(token.length - 4);
    return '$start***$end(len=${token.length})';
  }
}
