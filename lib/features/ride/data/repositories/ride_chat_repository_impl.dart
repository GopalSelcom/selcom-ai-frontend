import '../../domain/entities/ride_chat_message.dart';
import '../../domain/repositories/ride_chat_repository.dart';
import '../datasources/ride_chat_socket_data_source.dart';

class RideChatRepositoryImpl implements RideChatRepository {
  RideChatRepositoryImpl({required RideChatSocketDataSource dataSource})
    : _ds = dataSource;

  final RideChatSocketDataSource _ds;

  @override
  Stream<RideChatMessage> get incomingMessages => _ds.incomingMessages;

  @override
  Future<void> ensureConnected() => _ds.ensureConnected();

  @override
  void joinRideRoom({required String rideId}) =>
      _ds.joinRideRoom(rideId: rideId);

  @override
  void sendMessage({required String rideId, required String text}) {
    _ds.sendMessage(rideId: rideId, text: text);
  }

  @override
  void startListening() => _ds.startListening();

  @override
  void stopListening() => _ds.dispose();
}
