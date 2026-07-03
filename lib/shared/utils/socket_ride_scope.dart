/// When multiple ride socket rooms could be joined, handlers must ignore events
/// that are not for the screen's [activeRideId].
///
/// Some room-scoped payloads (e.g. `ride:tracking_update` after stop/destination
/// edits) omit `ride_id`; treat those as in-scope when [joinedRideRoomId] matches
/// [activeRideId].
bool socketPayloadIsForRide({
  required String activeRideId,
  String? payloadRideId,
  String? joinedRideRoomId,
}) {
  final active = activeRideId.trim();
  final incoming = (payloadRideId ?? '').trim();
  if (active.isEmpty) return false;
  if (incoming.isNotEmpty) return incoming == active;

  final joined = (joinedRideRoomId ?? '').trim();
  return joined.isNotEmpty && joined == active;
}
