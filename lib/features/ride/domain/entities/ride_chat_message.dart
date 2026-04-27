/// One line in the ride chat (socket `chat:receive_message` / local send).
class RideChatMessage {
  const RideChatMessage({
    required this.id,
    required this.rideId,
    required this.text,
    required this.isFromRider,
    required this.sentAt,

  });

  final String id;
  final String rideId;
  final String text;
  final bool isFromRider;
  final DateTime sentAt;
}
