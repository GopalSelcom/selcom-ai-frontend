/// One line in the ride chat (socket `chat:receive_message` / local send).
class RideChatMessage {
  const RideChatMessage({
    required this.id,
    required this.rideId,
    required this.text,
    required this.isFromRider,
    required this.sentAt,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String rideId;
  final String text;
  final bool isFromRider;
  final DateTime sentAt;

  /// Name on the bubble (driver: pink, left; rider: white on pink bubble).
  final String? displayName;

  /// Avatar image URL for the sender.
  final String? avatarUrl;
}
