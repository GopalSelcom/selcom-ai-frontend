/// When multiple ride socket rooms could be joined, handlers must ignore events
/// that are not for the screen's [activeRideId].
bool socketPayloadIsForRide({
  required String activeRideId,
  String? payloadRideId,
}) {
  final active = activeRideId.trim();
  final incoming = (payloadRideId ?? '').trim();
  if (active.isEmpty || incoming.isEmpty) return false;
  return incoming == active;
}
