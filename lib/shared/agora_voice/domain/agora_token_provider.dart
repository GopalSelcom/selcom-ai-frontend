class AgoraTokenData {
  const AgoraTokenData({required this.token, this.expiresInSeconds});

  final String? token;
  final int? expiresInSeconds;
}

abstract class AgoraTokenProvider {
  Future<AgoraTokenData> fetchRtcToken({
    required String channelName,
    required int uid,
  });
}
