/// When multiple ride socket rooms are joined (Home active-rides), broadcast
/// handlers must ignore events that are not for the screen's [activeRideId].
bool socketPayloadIsForRide({
  required String activeRideId,
  String? payloadRideId,
}) {
  final active = activeRideId.trim();
  final incoming = (payloadRideId ?? '').trim();
  if (active.isEmpty || incoming.isEmpty) return false;
  return incoming == active;
}
