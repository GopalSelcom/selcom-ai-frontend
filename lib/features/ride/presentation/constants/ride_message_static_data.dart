import '../../domain/entities/ride_chat_message.dart';

/// Placeholder ride id used only while UI is driven by static data.
const String kRideChatStaticPreviewRideId = 'static_preview_ride';

/// Shown as second line under header title (license plate in design).
const String kRideChatStaticDriverPlate = 'T772 BBE';

/// Seeded conversation matching design attached image.
List<RideChatMessage> staticSeedMessages(String rideId) {
  final t = DateTime(2026, 4, 11, 16, 4);
  const copy = 'Wait, I’ll be there in 10 min thanks for waiting';
  return [
    RideChatMessage(
      id: 'seed_1',
      rideId: rideId,
      text: copy,
      isFromRider: false,
      sentAt: t,
      displayName: 'Mike Mazowski',
    ),
    RideChatMessage(
      id: 'seed_2',
      rideId: rideId,
      text: copy,
      isFromRider: true,
      sentAt: t,
      displayName: 'Mike Mazowski',
    ),
  ];
}
