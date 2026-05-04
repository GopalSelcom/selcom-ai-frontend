import 'agora_call_invite_event.dart';

/// Canonical shape of backend `incoming_call` push payload.
///
/// Expected payload:
/// {
///   "type": "incoming_call",
///   "ride_id": "<rideId>",
///   "caller_role": "rider" | "driver",
///   "channel": "ride_<rideId>"
/// }
class AgoraIncomingCallSignal {
  const AgoraIncomingCallSignal({
    required this.rideId,
    required this.channel,
    required this.callerRole,
    required this.timestampMs,
  });

  final String rideId;
  final String channel;
  final String callerRole;
  final int timestampMs;

  static AgoraIncomingCallSignal? fromMap(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString().trim().toLowerCase();
    if (type != 'incoming_call') return null;

    final rideId = (json['ride_id'] ?? json['rideId'])?.toString().trim() ?? '';
    var channel =
        (json['channel'] ?? json['channel_name'])?.toString().trim() ?? '';
    if (channel.isEmpty && rideId.isNotEmpty) {
      final sanitized = rideId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      if (sanitized.isNotEmpty) {
        channel = 'ride_$sanitized';
      }
    }
    var callerRole = (json['caller_role'] ?? json['callerRole'])
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
    if (callerRole.isEmpty) {
      callerRole = 'driver';
    } else if (callerRole != 'rider' && callerRole != 'driver') {
      return null;
    }

    if (rideId.isEmpty || channel.isEmpty) return null;

    return AgoraIncomingCallSignal(
      rideId: rideId,
      channel: channel,
      callerRole: callerRole,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Converts backend wake payload into module-level invite event.
  AgoraCallInviteEvent toInviteEvent({
    required String callerId,
    String? callerName,
  }) {
    final resolvedName =
        callerName ??
        (callerRole == 'rider' ? 'Your Rider' : 'Your Driver');
    return AgoraCallInviteEvent(
      type: AgoraCallInviteEventType.invite,
      channelName: channel,
      rideId: rideId,
      callerName: resolvedName,
      callerId: callerId,
      timestampMs: timestampMs,
    );
  }
}
