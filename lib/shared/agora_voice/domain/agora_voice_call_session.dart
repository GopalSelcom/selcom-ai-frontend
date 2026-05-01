/// Ride-scoped call session. Token providers use [rideId] to mint RTC credentials.
class AgoraVoiceCallSession {
  const AgoraVoiceCallSession({required this.rideId});

  final String rideId;
}
