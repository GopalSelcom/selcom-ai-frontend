/// Delivers FCM `call_joined` payloads to the active ride session.
class AgoraCallJoinedNotificationBridge {
  AgoraCallJoinedNotificationBridge._();

  static final AgoraCallJoinedNotificationBridge instance =
      AgoraCallJoinedNotificationBridge._();

  String? _rideId;
  Future<void> Function(Map<String, dynamic> payload)? _onJoined;

  void register({
    required String rideId,
    required Future<void> Function(Map<String, dynamic> payload) onJoined,
  }) {
    _rideId = rideId;
    _onJoined = onJoined;
  }

  void unregister(String rideId) {
    if (_rideId == rideId) {
      _rideId = null;
      _onJoined = null;
    }
  }

  Future<bool> deliverIfMatching(Map<String, dynamic> raw) async {
    final type = (raw['type'] ?? '').toString().toLowerCase();
    if (type != 'call_joined') return false;
    final rideId = (raw['ride_id'] ?? raw['rideId'])?.toString();
    if (rideId == null || rideId.isEmpty) return false;
    final activeRideId = _rideId;
    final handler = _onJoined;
    if (activeRideId == null || handler == null || rideId != activeRideId) {
      return false;
    }
    await handler(raw);
    return true;
  }
}
