import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../domain/agora_token_provider.dart';
import '../domain/agora_voice_call_session.dart';

class AgoraVoiceEngineService {
  AgoraVoiceEngineService({required this.appId, required this.tokenProvider});

  final String appId;
  final AgoraTokenProvider tokenProvider;

  RtcEngine? _engine;
  bool _joined = false;

  Future<void> ensureInitialized({
    required void Function(RtcEngineEventHandler handler) registerEvents,
  }) async {
    if (_engine != null) return;

    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.enableAudio();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    registerEvents(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          _joined = true;
        },
        onLeaveChannel: (_, __) {
          _joined = false;
        },
      ),
    );
    _engine = engine;
  }

  Future<void> setEventHandler(RtcEngineEventHandler handler) async {
    final engine = _engine;
    if (engine == null) return;
    engine.registerEventHandler(handler);
  }

  Future<void> join(AgoraVoiceCallSession session) async {
    final engine = _engine;
    if (engine == null) {
      throw Exception('Agora engine not initialized');
    }

    final tokenData = await tokenProvider.fetchRtcToken(
      channelName: session.channelName,
      uid: session.uid,
    );

    await engine.joinChannel(
      token: tokenData.token ?? '',
      channelId: session.channelName,
      uid: session.uid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> setMuted(bool muted) async {
    final engine = _engine;
    if (engine == null) return;
    await engine.muteLocalAudioStream(muted);
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    final engine = _engine;
    if (engine == null) return;
    await engine.setEnableSpeakerphone(enabled);
  }

  Future<void> leave() async {
    final engine = _engine;
    if (engine == null || !_joined) return;
    await engine.leaveChannel();
    _joined = false;
  }

  Future<void> dispose() async {
    await leave();
    final engine = _engine;
    if (engine != null) {
      await engine.release();
    }
    _engine = null;
  }
}
