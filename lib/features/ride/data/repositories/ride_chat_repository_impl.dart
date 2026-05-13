import '../../domain/entities/ride_chat_message.dart';
import '../../domain/repositories/ride_chat_repository.dart';
import '../datasources/ride_chat_socket_data_source.dart';
import '../datasources/ride_remote_data_source.dart';

class RideChatRepositoryImpl implements RideChatRepository {
  RideChatRepositoryImpl({
    required RideChatSocketDataSource socketDataSource,
    required RideRemoteDataSource remoteDataSource,
  }) : _socketDs = socketDataSource,
       _remoteDs = remoteDataSource;

  final RideChatSocketDataSource _socketDs;
  final RideRemoteDataSource _remoteDs;

  @override
  Stream<RideChatMessage> get incomingMessages => _socketDs.incomingMessages;

  @override
  Future<void> ensureConnected() => _socketDs.ensureConnected();

  @override
  void joinRideRoom({required String rideId}) =>
      _socketDs.joinRideRoom(rideId: rideId);

  @override
  Future<bool> sendMessage({required String rideId, required String text}) {
    // Spec 1.0: Send via HTTP POST
    return _remoteDs.sendChatMessage(rideId, text);
  }

  @override
  Future<List<RideChatMessage>> getHistory({
    required String rideId,
    int page = 1,
  }) async {
    final data = await _remoteDs.getChatMessages(rideId, page: page);
    final List messagesRaw = data['messages'] ?? [];
    return messagesRaw
        .map((m) => _socketDs.parseIncoming(m))
        .whereType<RideChatMessage>()
        .toList();
  }

  @override
  Future<List<String>> fetchQuickReplies({String role = 'passenger'}) =>
      _remoteDs.getChatQuickReplies(role: role);

  @override
  void startListening() => _socketDs.startListening();

  @override
  void stopListening() => _socketDs.dispose();
}
