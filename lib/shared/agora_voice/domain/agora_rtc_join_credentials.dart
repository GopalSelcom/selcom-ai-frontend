/// Values returned by your backend token mint (see `brain/docs/AGORA-FRONTEND-GUIDE.md`).
///
/// Keep this file free of app-specific imports so the `agora_voice` folder can be
/// copied into another Flutter app with minimal edits.
class AgoraRtcJoinCredentials {
  const AgoraRtcJoinCredentials({
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    this.expiresAt,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final DateTime? expiresAt;

  /// Parses the `data` object from a standard API envelope, e.g. `{ "data": { ... } }`.
  factory AgoraRtcJoinCredentials.fromBackendData(Map<String, dynamic> raw) {
    String pickString(Iterable<String> keys) {
      for (final k in keys) {
        final v = raw[k];
        if (v == null) continue;
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '';
    }

    int pickUid(Iterable<String> keys) {
      for (final k in keys) {
        final v = raw[k];
        if (v is int) return v;
        if (v is num) return v.toInt();
        if (v is String) {
          final parsed = int.tryParse(v.trim());
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    DateTime? pickExpiresAt() {
      final v = raw['expires_at'] ?? raw['expiresAt'];
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final appId = pickString(['app_id', 'appId']);
    final channel = pickString(['channel', 'channelName', 'channel_id']);
    final token = pickString(['token', 'rtc_token', 'rtcToken']);
    final uid = pickUid(['uid', 'rtc_uid', 'rtcUid']);

    return AgoraRtcJoinCredentials(
      appId: appId,
      channel: channel,
      token: token,
      uid: uid,
      expiresAt: pickExpiresAt(),
    );
  }

  bool get isValidForJoin => appId.isNotEmpty && channel.isNotEmpty;
}
