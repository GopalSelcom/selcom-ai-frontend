enum AgoraCallInviteEventType { invite, accept, reject, end }

class AgoraCallInviteEvent {
  const AgoraCallInviteEvent({
    required this.type,
    required this.channelName,
    required this.rideId,
    required this.callerName,
    required this.callerId,
    required this.timestampMs,
  });

  final AgoraCallInviteEventType type;
  final String channelName;
  final String rideId;
  final String callerName;
  final String callerId;
  final int timestampMs;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kind': 'agora_call_invite',
      'type': type.name,
      'channel_name': channelName,
      'ride_id': rideId,
      'caller_name': callerName,
      'caller_id': callerId,
      'timestamp_ms': timestampMs,
    };
  }

  static AgoraCallInviteEvent? fromJson(Map<String, dynamic> json) {
    if ((json['kind'] as String?) != 'agora_call_invite') return null;
    final typeRaw = (json['type'] as String?)?.trim();
    if (typeRaw == null || typeRaw.isEmpty) return null;
    final matched = AgoraCallInviteEventType.values.where(
      (AgoraCallInviteEventType element) => element.name == typeRaw,
    );
    if (matched.isEmpty) return null;
    return AgoraCallInviteEvent(
      type: matched.first,
      channelName: (json['channel_name'] as String?)?.trim() ?? '',
      rideId: (json['ride_id'] as String?)?.trim() ?? '',
      callerName: (json['caller_name'] as String?)?.trim() ?? 'Caller',
      callerId: (json['caller_id'] as String?)?.trim() ?? '',
      timestampMs: (json['timestamp_ms'] as int?) ?? 0,
    );
  }
}
