/// Push payload type strings that the backend uses for FCM/APNs.
///
/// Per the brain doc (`brain/docs/AGORA-FRONTEND-GUIDE.md`):
/// - `incoming_call` — sent to the callee when the caller mints a token.
/// - `call_joined`   — sent to the caller when the callee mints a token (i.e.
///                     answers). Mirrors Agora SDK `onUserJoined` and is
///                     deduplicated against it client-side.
/// - `call_cancelled`— sent to the callee when the caller hits the cancel
///                     endpoint before the call is connected. Always FCM —
///                     never APNs VoIP (PushKit can't dismiss CallKit).
class PushTypes {
  PushTypes._();
  static const String incomingCall = 'incoming_call';
  static const String callJoined = 'call_joined';
  static const String callCancelled = 'call_cancelled';
}

/// Builds the deterministic ride-scoped channel name used by both clients
/// when the backend's mint response doesn't include `channel` (defensive —
/// the backend always returns one).
String channelNameForRide(String rideId) {
  final sanitized = rideId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  return sanitized.isEmpty ? 'ride_unknown' : 'ride_$sanitized';
}
