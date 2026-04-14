import 'dart:async';

import '../../../../core/services/nearby_drivers_socket_service.dart';
import '../../domain/entities/ride_chat_message.dart';

/// Maps `chat:receive_message` payloads to [RideChatMessage].
class RideChatSocketDataSource {
  RideChatSocketDataSource({required AppSocketService socket}) : _socket = socket;

  final AppSocketService _socket;

  StreamSubscription<Map<String, dynamic>>? _sub;
  final _incoming = StreamController<RideChatMessage>.broadcast();

  Stream<RideChatMessage> get incomingMessages => _incoming.stream;

  Future<void> ensureConnected() => _socket.connect();

  void joinRideRoom({required String rideId}) {
    _socket.joinRideRoom(rideId: rideId);
  }

  void sendMessage({required String rideId, required String text}) {
    _socket.sendMessage(rideId: rideId, message: text);
  }

  void startListening() {
    _sub ??= _socket.chatStream.listen((payload) {
      final msg = _parseIncoming(payload);
      if (msg != null) _incoming.add(msg);
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _incoming.close();
  }

  RideChatMessage? _parseIncoming(Map<String, dynamic> payload) {
    final rideId = (payload['ride_id'] ?? payload['rideId'])?.toString().trim() ?? '';
    final text = (payload['message'] ?? payload['text'] ?? payload['body'])?.toString().trim() ?? '';
    if (rideId.isEmpty || text.isEmpty) return null;

    final senderRaw = (payload['sender'] ?? payload['from'] ?? payload['role'])?.toString().toLowerCase() ?? '';
    final bool isFromRider;
    if (senderRaw.isEmpty) {
      isFromRider = false;
    } else if (senderRaw.contains('driver') ||
        senderRaw.contains('fleet') ||
        senderRaw.contains('captain')) {
      isFromRider = false;
    } else {
      isFromRider = senderRaw.contains('rider') ||
          senderRaw.contains('passenger') ||
          senderRaw.contains('customer') ||
          senderRaw == 'user';
    }

    DateTime sentAt = DateTime.now();
    final ts = payload['timestamp'] ?? payload['created_at'] ?? payload['sent_at'];
    if (ts is int) {
      sentAt = DateTime.fromMillisecondsSinceEpoch(ts < 2000000000000 ? ts * 1000 : ts);
    } else if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) sentAt = parsed;
    }

    final id = (payload['id'] ?? payload['message_id'] ?? '${rideId}_${sentAt.millisecondsSinceEpoch}_$text')
        .toString();

    final driverName = payload['driver_name'] ?? payload['sender_name'];
    final riderName = payload['rider_name'] ?? payload['user_name'];
    final String? displayName = isFromRider
        ? (riderName is String && riderName.trim().isNotEmpty
            ? riderName.trim()
            : null)
        : (driverName is String && driverName.trim().isNotEmpty ? driverName.trim() : null);

    return RideChatMessage(
      id: id,
      rideId: rideId,
      text: text,
      isFromRider: isFromRider,
      sentAt: sentAt,
      displayName: displayName,
    );
  }
}
