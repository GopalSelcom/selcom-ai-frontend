import '../entities/ride_chat_message.dart';

abstract class RideChatRepository {
  Stream<RideChatMessage> get incomingMessages;

  Future<void> ensureConnected();

  void startListening();

  void stopListening();

  void sendMessage({required String rideId, required String text});

  void joinRideRoom({required String rideId});
}
