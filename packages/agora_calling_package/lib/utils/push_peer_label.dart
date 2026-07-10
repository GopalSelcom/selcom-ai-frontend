import '../models/agora_config.dart';

/// Reads `caller_name` from an FCM / VoIP push [data] map when present.
String? callerNameFromPush(Map<String, dynamic> data) {
  final raw = (data['caller_name'] ?? data['callerName'])?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

/// Display label for the remote party on call pushes and CallKit surfaces.
///
/// Prefers [caller_name] from the backend; keeps the previous default copy
/// when the name is missing or empty.
String peerLabelFromPush(
  Map<String, dynamic> data, {
  required CallParticipantRole localRole,
  String appName = 'Selcom Go',
}) {
  final fromPush = callerNameFromPush(data);
  if (fromPush != null) return fromPush;
  return fallbackPeerLabel(localRole: localRole);
}

/// Fallback when `caller_name` is absent — original app copy (unchanged).
String fallbackPeerLabel({
  required CallParticipantRole localRole,
  Map<String, dynamic>? data,
  String appName = 'Selcom Go',
}) {
  return localRole == CallParticipantRole.rider
      ? 'Your Rider'
      : 'Your Passenger';
}
