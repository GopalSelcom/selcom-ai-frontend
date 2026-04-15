import '../entities/ride_chat_message.dart';

abstract class RideChatRepository {
  Stream<RideChatMessage> get incomingMessages;

  Future<void> ensureConnected();

  void startListening();

  void stopListening();

  Future<bool> sendMessage({required String rideId, required String text});

  Future<List<RideChatMessage>> getHistory({
    required String rideId,
    int page = 1,
  });

  void joinRideRoom({required String rideId});
}
