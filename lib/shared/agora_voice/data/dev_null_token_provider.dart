import '../domain/agora_token_provider.dart';

class DevNullTokenProvider implements AgoraTokenProvider {
  const DevNullTokenProvider();

  @override
  Future<AgoraTokenData> fetchRtcToken({
    required String channelName,
    required int uid,
  }) async {
    return const AgoraTokenData(token: null);
  }
}
