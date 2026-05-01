import '../domain/agora_rtc_join_credentials.dart';
import '../domain/agora_voice_token_provider.dart';

/// No-backend / dev: fixed channel + UID + optional empty token (tokenless Agora project).
class StaticVoiceTokenProvider implements AgoraVoiceTokenProvider {
  StaticVoiceTokenProvider({
    required this.appId,
    required this.channel,
    required this.uid,
    this.token = '',
  });

  final String appId;
  final String channel;
  final int uid;
  final String token;

  @override
  /// Returns fixed credentials for local testing/no-backend mode.
  /// Keeps `rideId` required so host flow stays consistent across modes.
  Future<AgoraRtcJoinCredentials> fetchCredentials({required String rideId}) async {
    if (rideId.trim().isEmpty) {
      throw StateError('rideId is required for AgoraVoiceCallSession');
    }
    return AgoraRtcJoinCredentials(
      appId: appId,
      channel: channel,
      token: token,
      uid: uid,
    );
  }
}
